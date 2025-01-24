//
//  FeedCell.swift
//  weekly
//
//  Created by Cooper Senior on 12/11/24.
//

import SwiftUI
import Kingfisher

struct FeedCell: View {
    let post: Post
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = FeedViewModel()
    @State private var isLiked = false
    @State private var likes: Int
    @State private var showHeart = false
    @State private var user: User?
    @State private var scale: CGFloat = 1.0
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedPostId: String? = nil
    @State private var showConfirmation = false
    @State private var showCommentsSheet = false
    @State private var userProfileView = false
    @Environment(\.presentationMode) var presentationMode
    
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    init(post: Post, userProfileView: Bool) {
        self.userProfileView = userProfileView
        self.post = post
        _likes = State(initialValue: post.likes)
    }
    
    private var timeElapsed: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let date = post.timestamp.dateValue()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    // TODO: dissable all action buttons and blur photo is not posted last within a week
    var body: some View {
        ScrollView {
            VStack {
                // Image and username
                if let user = user {
                    NavigationLink(destination: ProfileView(user: user)) {
                        HStack {
                            CircularProfileImageView(user: user, size: .xSmall)
                            
                            Text(user.username)
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Spacer()
                            
                            // hide if not in user Profile View
                            if user.isCurrentUser && userProfileView {
                                Button {
                                    impactFeedbackGenerator.prepare()
                                    impactFeedbackGenerator.impactOccurred()
                                    selectedPostId = post.id
                                    showConfirmation = true
                                } label: {
                                    Image(systemName: "trash")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .padding()
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                            }
                            
                        }
                        .padding(.leading, 8)
                    }
                } else {
                    // Empty space with margin so view doesnt change after loading
                    HStack {
                        Spacer()
                    }
                    .frame(height: 45)
                    .padding(.leading, 8)
                }
                
                // Post image
                KFImage(URL(string: post.imageUrl))
                    .resizable()
                    .scaledToFit()
                    .clipShape(Rectangle())
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = max(1.0, value.magnitude)
                            }
                            .onEnded { _ in
                                scale = 1.0
                            }
                    )
                    .clipped()
                    .onTapGesture(count: 2) {
                        impactFeedbackGenerator.prepare()
                        impactFeedbackGenerator.impactOccurred()
                        showHeart = true
                        Task {
                            if !isLiked {
                                try await viewModel.likePost(postId: post.id)
                                likes += 1
                                isLiked.toggle()
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showHeart = false
                        }
                    }
                    .overlay(
                        // Heart image appears on double tap
                        Image(systemName: "heart.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .foregroundColor(.red)
                            .opacity(showHeart ? 1 : 0)  // Heart fades in and out
                            .animation(.easeInOut(duration: 0.5), value: showHeart) // Smooth fade animation
                    )
                
                // Action buttons
                HStack {
                    Button {
                        Task {
                            if !isLiked {
                                try await viewModel.likePost(postId: post.id)
                                likes += 1
                            } else {
                                try await viewModel.unlikePost(postId: post.id)
                                likes -= 1
                            }
                            isLiked.toggle()
                        }
                        impactFeedbackGenerator.prepare()
                        impactFeedbackGenerator.impactOccurred()
                    } label: {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .imageScale(.large)
                            .foregroundColor(isLiked ? .red : (colorScheme == .dark ? .white : .black))
                    }
                    
                    Button {
                        presentCommentsView()
                        impactFeedbackGenerator.prepare()
                        impactFeedbackGenerator.impactOccurred()
                    } label: {
                        Image(systemName: "bubble.right")
                            .imageScale(.large)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    
                    Button {
                        impactFeedbackGenerator.prepare()
                        impactFeedbackGenerator.impactOccurred()
                    } label: {
                        Image(systemName: "paperplane")
                            .imageScale(.large)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    
                    Spacer()
                }
                .padding(.leading, 8)
                .padding(.top, 4)
                
                // Likes label
                Text(likes == 1 ? "\(likes) like" : "\(likes) likes")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                    .padding(.top, 1)
                
                // Caption label
                HStack {
                    Text("\(user?.username ?? "") ").fontWeight(.semibold) +
                    Text(post.caption ?? "")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
                .padding(.top, 0.5)
                .font(.footnote)
                
                // Time elapsed
                Text(timeElapsed)
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                    .padding(.top, 0.5)
                    .foregroundStyle(.gray)
                
                Spacer()
            }
        }
        .onAppear {
            // Fetch like status on load
            Task {
                if try await viewModel.fetchLikeStatus(postId: post.id) {
                    isLiked = true
                }
                do {
                    self.user = try await UserService.fetchUser(withUid: post.ownerUid)
                } catch {
                    print("Failed to fetch user: \(error)")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if presentationMode.wrappedValue.isPresented {
                // Only customize if the view is part of a navigation stack
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.backward")
                                .foregroundColor(colorScheme == .dark ? .white : .black)

                        }
                    }
                }
            }
        }
        .alert("Are you sure?", isPresented: $showConfirmation, actions: {
            Button("Delete Post", role: .destructive) {
                if let postId = selectedPostId {
                    Task {
                        do {
                            try await viewModel.deletePost(postId: postId)
                            dismiss()
                            print("Post deleted successfully.")
                        } catch {
                            print("Failed to delete post: \(error.localizedDescription)")
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }, message: {
            Text("This action cannot be undone.")
        })
    }
    
    func presentCommentsView() {
        // Find the current top-most UIViewController
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            // Create and present CommentsViewController
            let commentsViewController = CommentsViewModel(post: post)

            // Configure sheet presentation
            if let sheet = commentsViewController.presentationController as? UISheetPresentationController {
                sheet.detents = [.medium(), .large()] // Set height to half-screen
                sheet.prefersGrabberVisible = true // Show grabber for resizing
            }

            // Present the CommentsViewController
            rootVC.present(commentsViewController, animated: true)
        }
    }
}

#Preview {
    FeedCell(post: Post.MOCK_POSTS[0], userProfileView: false)
}
