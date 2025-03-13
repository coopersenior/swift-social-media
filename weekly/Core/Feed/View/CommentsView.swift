//
//  CommentsView.swift
//  weekly
//
//  Created by Cooper Senior on 1/20/25.
//

import SwiftUI

struct CommentsView: View {
    let post: Post
    @State private var user: User? = nil
    @State private var isShowingUserView = false
    @State private var isShowingUserProfileView = false
    @StateObject var viewModel = FeedViewModel()
    @StateObject private var commentsService: CommentsService
    @State private var selectedCommentId: String? = nil
    @State private var showConfirmation = false
    @Environment(\.colorScheme) var colorScheme
    
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State var text = ""
    
    init(post: Post) {
        self.post = post
        _commentsService = StateObject(wrappedValue: CommentsService(post: post))
    }
    
    func getTimeElapsed(comment: Comment) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let date = comment.timestamp.dateValue()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var body: some View {
        Text("Comments")
            .font(.subheadline)
            .fontWeight(.semibold)
            .padding(.top)
        Divider()
        
        // START of comments field
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(commentsService.comments) { comment in
                        HStack {
                            CommentCircularProfileImageView(comment: comment, size: .xSmall)
                                .simultaneousGesture(TapGesture().onEnded {
                                    Task {
                                        self.user = try await UserService.fetchUser(withUid: comment.commentUserId)
                                        isShowingUserView = true
                                    }
                                })
                            VStack(alignment: .leading) {
                                HStack {
                                    if let username = comment.commentUsername {
                                        Text(username)
                                            .fontWeight(.semibold)
                                            .simultaneousGesture(TapGesture().onEnded {
                                                Task {
                                                    self.user = try await UserService.fetchUser(withUid: comment.commentUserId)
                                                    isShowingUserView = true
                                                }
                                            })
                                    }
                                    
                                    Text(getTimeElapsed(comment: comment))
                                        .font(.footnote)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 10)
                                        .padding(.top, 0.5)
                                        .foregroundStyle(.gray)
                                        .simultaneousGesture(TapGesture().onEnded {
                                            Task {
                                                self.user = try await UserService.fetchUser(withUid: comment.commentUserId)
                                                isShowingUserView = true
                                            }
                                        })
                                }
                                formatCommentText(comment: comment)
                                    .font(.subheadline)
                                
                            }
                            .font(.footnote)
                            Spacer()
                            
                        }
                        .padding(.horizontal)
                        .padding(.top, 5)
                        .gesture(
                            LongPressGesture(minimumDuration: 0.5) // Adjust duration as needed
                                .onEnded { _ in
                                    if commentsService.isCommentAuthor(withUid: comment.commentUserId) {
                                        impactFeedbackGenerator.prepare()
                                        impactFeedbackGenerator.impactOccurred()
                                        selectedCommentId = comment.id
                                        showConfirmation = true
                                    }
                                }
                        )
                        
                    }
                    
                    if commentsService.comments.count == 0 {
                        Text("No comments yet")
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.top, 8)
            }
            .alert("Are you sure?", isPresented: $showConfirmation, actions: {
                Button("Delete Comment", role: .destructive) {
                    if let commentId = selectedCommentId {
                        Task {
                            do {
                                try await commentsService.deleteComment(postId: post.id, commentId: commentId)
                            } catch {
                                print("Failed to delete comment: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }, message: {
                Text("This action cannot be undone.")
            })
            
            Spacer()
            
            HStack {
                TextField("Comment...", text: $text)
                
                Button {
                    if text.count > 0 {
                        impactFeedbackGenerator.prepare()
                        impactFeedbackGenerator.impactOccurred()
                        commentsService.sendComment(text: text) // it will be from current user
                        text = ""
                    }
                } label : {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(Color(.white))
                        .padding(10)
                        .background(Color(.systemBlue))
                        .cornerRadius(50)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(uiColor: .systemGray5))
            .cornerRadius(50)
            .padding()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isShowingUserView) {
                if user != nil {
                    Text("User View")
                        .onAppear {
                            isShowingUserProfileView = true
                            isShowingUserView = false
                        }
                }
                
            }
        }
        .fullScreenCover(isPresented: $isShowingUserProfileView) {
            if let user = user {
                NavigationStack {
                    ProfileView(user: user)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    isShowingUserProfileView = false  // Make sure this dismisses the fullScreenCover
                                }) {
                                    // blank
                                }
                            }
                        }
                }
            }
        }
    }
    
    @ViewBuilder
        func formatCommentText(comment: Comment) -> some View {
            if let username = extractUsername(from: comment.text),
               let range = comment.text.range(of: "@\(username)") {
                let before = String(comment.text[..<range.lowerBound])
                let after = String(comment.text[range.upperBound...])
                
                HStack(spacing: 0) {
                    Text(before)
                    Text("@\(username)")
                        .foregroundStyle(Color(.systemBlue))
                        .simultaneousGesture(TapGesture().onEnded {
                            Task {
                                self.user = try await UserService.fetchUserByUsername(username)
                               
                                if let validUser = self.user {
                                    print(validUser.username)
                                    isShowingUserView = true
                                }
                                
                            }
                        })
                    
                    Text(after)
                }
            } else {
                Text(comment.text)
            }
        }
        
        func extractUsername(from text: String) -> String? {
            let words = text.components(separatedBy: .whitespaces)
            if let mentionWord = words.first(where: { $0.hasPrefix("@") }) {
                let username = String(mentionWord.dropFirst())
                return username.isEmpty ? nil : username
            }
            return nil
        }
}
