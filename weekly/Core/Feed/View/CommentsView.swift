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
    @StateObject var viewModel = FeedViewModel()
    @StateObject private var commentsService: CommentsService
    @State private var selectedCommentId: String? = nil
    @State private var showConfirmation = false
    
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
                            VStack(alignment: .leading) {
                                HStack {
                                    if let username = comment.commentUsername {
                                        Text(username)
                                            .fontWeight(.semibold)
                                    }
                                    Text(getTimeElapsed(comment: comment))
                                        .font(.footnote)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 10)
                                        .padding(.top, 0.5)
                                        .foregroundStyle(.gray)
                                }
                                Text(comment.text)
                                    .font(.subheadline)
                            }
                            .font(.footnote)
                            Spacer()
                            
                        }
                        .foregroundStyle(.black)
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
                        .simultaneousGesture(TapGesture().onEnded {
                            Task {
                                self.user = try await UserService.fetchUser(withUid: comment.commentUserId)
                                isShowingUserView = true // Trigger navigation after fetching the user
                            }
                        })
                    }
                    
                    if commentsService.comments.count == 0 {
                        Text("No comments yet")
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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
            .navigationDestination(isPresented: $isShowingUserView) {
                if let user = user {
                    ProfileView(user: user)
                        .navigationBarBackButtonHidden(true)
                        .navigationTitle("")
                        .toolbarRole(.editor) // Removes the title in the back button
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    isShowingUserView = false // Handle custom back navigation
                                }) {
                                    HStack {
                                        Image(systemName: "chevron.backward")
                                            .foregroundColor(.black) // Black back arrow
                                        Text("") // Optional back button title (empty for clean look)
                                    }
                                }
                            }
                        }
                }
            }
        }
    }
}
