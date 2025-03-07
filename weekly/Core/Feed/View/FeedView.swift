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
    @State private var isLoading = false
    @State private var isViewLoaded = false
    @State private var navigateToUpload = false
    @State private var selectedIndex: Int = 0
    @Environment(\.colorScheme) var colorScheme
    
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    LazyVStack(spacing: 32) {
                        if viewModel.displayTimeToPostMessage {
                            VStack {
                                HStack {
                                    Image("icon")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                    
                                    Text("Weekly")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                    Spacer()
                                }
                                .padding(.leading, 8)
                                
                                Image("weeklyTime")
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(Rectangle())
                                    .blur(radius: 20)
                                    .cornerRadius(10)
                                
                                //print(PostService.timeSincePostReset())
                                Text(PostService.timeSincePostReset())
                                    .font(.footnote)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 10)
                                    .padding(.top, 0.5)
                                    .foregroundStyle(.gray)
                            }
                            .overlay(
                                VStack {
                                    Text("It's time to post this week! A new posting week starts each \(PostService.getPostResetDateAsDay())!")
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
                                            Text("Share a post now!")
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
                            )
                        }
                        ForEach(viewModel.posts) { post in
                            FeedCell(post: post, userProfileView: false)
                        }
                        
                    }
                    .padding(.top, 4)

                    if showNoPostsMessage {
                        Text("No posts to view")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding()
                    }
                }
            }
            .fullScreenCover(isPresented: $navigateToUpload) {
                UploadPostView(tabIndex: $selectedIndex)
                    .navigationBarBackButtonHidden()
            }
//            .overlay(
//                ZStack {
//                    if isViewLoaded && viewModel.displayTimeToPostMessage {
//                        HStack {
//                            Text("It's time to post this week!")
//                                .font(.subheadline)
//                                .fontWeight(.semibold)
//                                .padding(12)
//                                .background(.ultraThinMaterial) // Blurred background
//                                .clipShape(RoundedRectangle(cornerRadius: 12))
//                        }
//                        .transition(.opacity) // Smooth fade-in
//                        .frame(height: 20)
//                    }
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//                .padding(.top, 10)
//            )
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: AddOrSearchView().hideTabBar()) {
                        ZStack {
                            Image(systemName: "person.2.badge.gearshape.fill")
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
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            impactFeedbackGenerator.prepare()
                            impactFeedbackGenerator.impactOccurred()
                        }
                    )
                }
                ToolbarItem(placement: .principal) { // Center the image like a title
                    Image(colorScheme == .dark ? "weekly-light" : "weekly-dark")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 35) // Adjust the size of the image
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: MessagesView().hideTabBar()) {
                        ZStack {
                            Image(systemName: "ellipsis.message.fill")
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
            viewModel.getDisplayTimeToPostMessage()
            Task {
                if viewModel.posts.isEmpty { // Only fetch if there are no cached posts
                    isLoading = true
                    try await viewModel.fetchPosts()
                    showNoPostsMessage = viewModel.posts.isEmpty
                    isLoading = false
                } else {
                    showNoPostsMessage = viewModel.posts.isEmpty
                    isLoading = false // Skip loading if posts already exist
                }
                isViewLoaded = true
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
