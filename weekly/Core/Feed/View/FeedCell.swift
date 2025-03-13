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
    @State private var numberOfComments: Int = 0
    @State private var showHeart = false
    @State private var user: User?
    @State private var taggedUser: User?
    @State private var scale: CGFloat = 1.0
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedPostId: String? = nil
    @State private var showConfirmation = false
    @State private var showCommentsSheet = false
    @State private var showShareSheet = false
    @State private var userProfileView = false
    @State private var navigateToUpload = false
    @State private var selectedIndex: Int = 0
    @State private var canLike = true
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
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        if timeInterval < 5 {
            return "Just now"
        }

        return formatter.localizedString(for: date, relativeTo: now)
    }
    
    var body: some View {
        NavigationStack {
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
                    // trying to add space view dosnt change after loading
                    HStack {
                        Image(systemName: "trash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .padding()
                            .opacity(0)
                        Text("")
                            .font(.footnote)
                            .fontWeight(.semibold)
                        Spacer()
                        
                        Image(systemName: "trash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding()
                            .opacity(0)
                    }
                    .padding(.leading, 8)
                }
                
                // Post image
                KFImage(URL(string: post.imageUrl))
                    .resizable()
                    .scaledToFit()
                    .clipShape(Rectangle())
                    .scaleEffect(scale.isNaN ? 1.0 : scale)
                    .blur(radius: (post.blurred ?? false) ? 25 : 0)
                    .blur(radius: (post.hiddenFromNonFriends ?? false) ? 50 : 0)
                    .cornerRadius(10)
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
                        let blur = post.blurred ?? false
                        let hidden = post.hiddenFromNonFriends ?? false
                        if !blur && !hidden {
                            impactFeedbackGenerator.prepare()
                            impactFeedbackGenerator.impactOccurred()
                            showHeart = true
                            Task {
                                if !isLiked {
                                    try await viewModel.likePost(postId: post.id)
                                    isLiked.toggle()
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showHeart = false
                            }
                        }
                    }
                    .overlay(
                        ZStack {
                            // Apply overlay if post is blurred
                            if let blur = post.blurred, blur {
                                VStack {
                                    Text("You must share a post once a week to view your friends' new posts.")
                                        .font(.footnote)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding()
                                    
                                    Button {
                                        navigateToUpload = true
                                        selectedIndex = 1
                                    } label: {
                                        HStack {
                                            Image(systemName: "plus.square.fill")
                                                .tint(colorScheme == .dark ? .white : .black)
                                            Text("Post now to unlock!")
                                                .font(.footnote)
                                                .fontWeight(.semibold)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(colorScheme == .dark ? Color.black.opacity(0.25) : Color.white.opacity(0.75))
                                        )
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .multilineTextAlignment(.center)
                                .padding()
                                .onAppear {
                                    selectedIndex = 1
                                }
                            }
                            HStack {
                                if let hidden = post.hiddenFromNonFriends, hidden {
                                    VStack {
                                        Text("You are not friends with the owner of the post.")
                                            .font(.footnote)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding()
                                    }
                                }
                            }
                            
                            // Heart image appears on double tap (and fades in and out)
                            Image(systemName: "heart.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 75, height: 75)
                                .foregroundColor(.red)
                                .opacity(showHeart ? 1 : 0)  // Heart fades in and out
                                .animation(.easeInOut(duration: 0.5), value: showHeart) // Smooth fade animation
                        }
                    )
                
                // Action buttons
                HStack {
                    Button {
                        Task {
                            if canLike { //  a flag to prevent spamming
                                canLike = false // disable further likes temporarily
                                defer {
                                    Task {
                                        try? await Task.sleep(nanoseconds: 100_000_000) // 500ms delay
                                        canLike = true // re-enable liking after delay
                                    }
                                }
                                if !isLiked {
                                    try await viewModel.likePost(postId: post.id)
                                    isLiked.toggle()
                                } else {
                                    if likes > 0 {
                                        try await viewModel.unlikePost(postId: post.id)
                                        isLiked.toggle()
                                    }
                                }
                            }
                        }
                        impactFeedbackGenerator.prepare()
                        impactFeedbackGenerator.impactOccurred()
                    } label: {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .imageScale(.large)
                            .foregroundColor(isLiked ? .red : (colorScheme == .dark ? .white : .black))
                    }
                    .disabled(post.blurred ?? false ? true : false)
                    .disabled(post.hiddenFromNonFriends ?? false ? true : false)
                    .opacity(post.blurred ?? false ? 0.5 : 1)
                    .opacity(post.hiddenFromNonFriends ?? false ? 0.5 : 1)
                    
                    Text("\(likes)")
                        .font(.footnote)
                        .fontWeight(.semibold)
                    
                    Button {
                        showCommentsSheet.toggle()
                        impactFeedbackGenerator.prepare()
                        impactFeedbackGenerator.impactOccurred()
                    } label: {
                        Image(systemName: "bubble.right")
                            .imageScale(.large)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .disabled(post.blurred ?? false ? true : false)
                    .disabled(post.hiddenFromNonFriends ?? false ? true : false)
                    .opacity(post.blurred ?? false ? 0.5 : 1)
                    .opacity(post.hiddenFromNonFriends ?? false ? 0.5 : 1)
                    
                    Text("\(numberOfComments)") // comments count
                        .font(.footnote)
                        .fontWeight(.semibold)
                    
                    Button {
                        showShareSheet.toggle()
                        impactFeedbackGenerator.prepare()
                        impactFeedbackGenerator.impactOccurred()
                    } label: {
                        Image(systemName: "paperplane")
                            .imageScale(.large)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .disabled(post.blurred ?? false ? true : false)
                    .disabled(post.hiddenFromNonFriends ?? false ? true : false)
                    .opacity(post.blurred ?? false ? 0.5 : 1)
                    .opacity(post.hiddenFromNonFriends ?? false ? 0.5 : 1)
                    
                    Spacer()
                }
                .padding(.leading, 8)
                .padding(.top, 4)
                
                // Caption label
                HStack {
                    if let user = user {
                        NavigationLink(destination: ProfileView(user: user)) {
                            Text("\(user.username)").fontWeight(.semibold)
                        }
                        if post.caption != nil {
                            formatCaptionText(post: post)
                        }
                    } else {
                        Text("\(user?.username ?? "") ").fontWeight(.semibold) +
                        Text(post.caption ?? "")
                    }
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
            .fullScreenCover(isPresented: $navigateToUpload) {
                UploadPostView(tabIndex: $selectedIndex)
                    .navigationBarBackButtonHidden()
            }
            .sheet(isPresented: $showCommentsSheet) {
                // Presenting CommentsView as a half-screen sheet
                CommentsView(post: post)
                    .presentationDetents([.medium, .large]) // Half screen and full screen options
                    .presentationDragIndicator(.visible) // Shows the grabber for resizing
            }
            .sheet(isPresented: $showShareSheet) {
                // Presenting CommentsView as a half-screen sheet
                SharePostView(post: post)
                    .presentationDetents([.medium, .large]) // Half screen and full screen options
                    .presentationDragIndicator(.visible) // Shows the grabber for resizing
            }
        }
    .onAppear {
        // Fetch like status on load
        Task {
            do {
                self.user = try await UserService.fetchUser(withUid: post.ownerUid)
            } catch {
                print("Failed to fetch user: \(error)")
            }
            if try await viewModel.fetchLikeStatus(postId: post.id) {
                isLiked = true
            }
            
            viewModel.listenToLikes(for: post.id) { updatedLikes in
                self.likes = updatedLikes // Update likes count in the FeedCell
            }
            viewModel.listenToComments(for: post.id) { updatedComments in
                self.numberOfComments = updatedComments // Update likes count in the FeedCell
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

@ViewBuilder
    func formatCaptionText(post: Post) -> some View {
        if let caption = post.caption {
            if let username = extractUsername(from: caption),
               let range = caption.range(of: "@\(username)") {
                let before = String(caption[..<range.lowerBound])
                let after = String(caption[range.upperBound...])
                
                HStack(spacing: 0) {
                    Text(before)
                    if let user = taggedUser {
                        NavigationLink(destination: ProfileView(user: user)) {
                            Text("@\(user.username)")
                                .foregroundStyle(Color(.systemBlue))
                        }
                    } else {
                        Text("@\(username)")
                            .foregroundStyle(Color(.systemBlue))
                    }
                    
                    Text(after)
                }
                .onAppear {
                    Task {
                        self.taggedUser = try await UserService.fetchUserByUsername(username)
                    }
                }
            } else {
                Text(post.caption ?? "")
            }
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

#Preview {
    FeedCell(post: Post.MOCK_POSTS[0], userProfileView: false)
}
