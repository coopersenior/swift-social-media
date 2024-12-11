//
//  ProfileHeaderView.swift
//  weekly
//
//  Created by Cooper Senior on 12/12/24.
//

import SwiftUI

struct ProfileHeaderView: View {
    let user: User
    @State private var showEditProfile = false
    @State private var postCount: Int = 0
    @State private var followerCount: Int = 0
    @StateObject var viewModel = AddOrSearchViewModel()
    
    var body: some View {
        VStack(spacing: 10) {
            // pic and stats
            HStack {
                CircularProfileImageView(user: user, size: .large)
                
                Spacer()
                
                HStack(spacing: 8) {
                    UserStatView(value: postCount, title: postCount == 1 ? "Post" : "Posts")
                    
                    UserStatView(value: followerCount, title: followerCount == 1 ? "Friend" : "Friends")
                }
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 4) {
                // name and bio
                if let fullname = user.fullname {
                    Text(fullname)
                        .font(.footnote)
                        .fontWeight(.semibold)
                }
                if let bio  = user.bio {
                    Text(bio)
                        .font(.footnote)
                }
                
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            // action button
            if user.isCurrentUser {
                Button {
                    showEditProfile.toggle()
                } label: {
                    Text("Edit Profile")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 360, height: 32)
                        .background(.white)
                        .foregroundColor(.black)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
            } else {
                ProfileFriendButton(user: user)
            }
            
            Divider() // TODO: remove this just have a break/space i dont like the line
        }
        .fullScreenCover(isPresented: $showEditProfile) {
            EditProfileView(user: user)
        }
        .onAppear {
            fetchPostCount()
            fetchFollowerCount()
        }
    }
    
    private func fetchPostCount() {
        Task {
            do {
                let count = try await PostService.numberOfUserPosts(uid: user.id)
                DispatchQueue.main.async {
                    postCount = count
                }
            } catch {
                print("Failed to fetch post count: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchFollowerCount() {
        // Fetch follower count from ViewModel
        viewModel.fetchFollowerCount(for: user.id) { count in
            followerCount = count
        }
    }
    
}

#Preview {
    ProfileHeaderView(user: User.MOCK_USERS[0])
}
