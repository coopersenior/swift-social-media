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
    @StateObject var viewModel = FeedViewModel()
    @State private var isLiked = false
    @State private var likes: Int
    @State private var showHeart = false
    
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    init(post: Post) {
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
                if let user = post.user {
                    NavigationLink(destination: ProfileView(user: user)) {
                        HStack {
                            CircularProfileImageView(user: user, size: .xSmall)
                            
                            Text(user.username)
                                .font(.footnote)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        .padding(.leading, 8)
                    }
                    .foregroundStyle(.black)
                }
                
                // Post image
                KFImage(URL(string: post.imageUrl))
                    .resizable()
                    .scaledToFit()
                    .clipShape(Rectangle())
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
                            .foregroundColor(isLiked ? .red : .black)
                    }
                    
                    Button {
                        print("comments")
                        impactFeedbackGenerator.prepare()
                        impactFeedbackGenerator.impactOccurred()
                    } label: {
                        Image(systemName: "bubble.right")
                            .imageScale(.large)
                    }
                    
                    Button {
                        impactFeedbackGenerator.prepare()
                        impactFeedbackGenerator.impactOccurred()
                    } label: {
                        Image(systemName: "paperplane")
                            .imageScale(.large)
                    }
                    
                    Spacer()
                }
                .padding(.leading, 8)
                .padding(.top, 4)
                .foregroundStyle(.black)
                
                // Likes label
                Text(likes == 1 ? "\(likes) like" : "\(likes) likes")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                    .padding(.top, 1)
                
                // Caption label
                HStack {
                    Text("\(post.user?.username ?? "") ").fontWeight(.semibold) +
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
            .onAppear {
                // Fetch like status on load
                Task {
                    if try await viewModel.fetchLikeStatus(postId: post.id) {
                        isLiked = true
                    }
                }
            }
        }
    }
}

#Preview {
    FeedCell(post: Post.MOCK_POSTS[0])
}
