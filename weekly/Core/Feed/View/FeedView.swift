//
//  FeedView.swift
//  weekly
//
//  Created by Cooper Senior on 12/11/24.
//

import SwiftUI

extension View {
    func hideTabBar() -> some View {
        self
            .toolbar(.hidden, for: .tabBar) // Hides the tab bar
    }
}

@MainActor
struct FeedView: View {
    @StateObject var viewModel = FeedViewModel()
    @StateObject var friendRequestsViewModel = AddOrSearchViewModel()
    @StateObject var messagesViewModel = MessagesViewModel()
    @State private var showNoPostsMessage = false
    
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 32) {
                    ForEach(viewModel.posts) { post in
                        FeedCell(post: post)
                    }
                }
                .padding(.top, 8)
                
                if showNoPostsMessage && viewModel.posts.isEmpty {
                    Text("No posts to view")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: AddOrSearchView().hideTabBar()) {
                        ZStack {
                            Image(systemName: "person.2.fill")
                                .imageScale(.large)

                                // Add red dot if there are friend requests
                                if !friendRequestsViewModel.friendRequests.isEmpty {
                                    Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 12, y: -10) // Position the red dot
                                }
                            }
                    }
                    .foregroundStyle(.black)
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            impactFeedbackGenerator.prepare()
                            impactFeedbackGenerator.impactOccurred()
                        }
                    )
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: MessagesView().hideTabBar()) {
                        ZStack {
                            Image(systemName: "paperplane.fill")
                                .imageScale(.large)

                            // Add red dot if there are new messages
                            if messagesViewModel.hasUnreadMessages {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 12, y: -10) // Position the red dot
                            }
                        }
                    }
                    .foregroundStyle(.black)
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            impactFeedbackGenerator.prepare()
                            impactFeedbackGenerator.impactOccurred()
                        }
                    )
                }
            }
        }
        .onAppear {
            if viewModel.posts.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showNoPostsMessage = true
                }
            }
            viewModel.listenToPosts()
            friendRequestsViewModel.listenToFriendRequests()
            messagesViewModel.listenToMessages()
        }
        .onDisappear {
            viewModel.stopListening()
            friendRequestsViewModel.stopListening()
            messagesViewModel.stopListening()
        }
    }
}


#Preview {
    FeedView()
}
