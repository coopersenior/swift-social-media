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
            .toolbar(.hidden, for: .tabBar)
    }
}

@MainActor
struct FeedView: View {
    @StateObject var viewModel = FeedViewModel()
    @StateObject var friendRequestsViewModel = AddOrSearchViewModel()
    @StateObject var messagesViewModel = MessagesViewModel()
    @State private var showNoPostsMessage = false
    @State private var isLoading = true
    @State private var navigateToUpload = false
    @State private var isShowingSplash = true
    @State private var selectedIndex: Int = 0
    @State private var isShowingLeftView = false
    @State private var dragOffset: CGFloat = 0 // Track drag offset for swipe-to-dismiss
    @State private var backgroundOffset: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        ZStack {
            if isShowingSplash {
                SplashScreenView().hideTabBar()
            } else {
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
                            
                            if viewModel.posts.isEmpty {
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
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                withAnimation(.easeInOut) {
                                    isShowingLeftView.toggle()
                                }
                                impactFeedbackGenerator.prepare()
                                impactFeedbackGenerator.impactOccurred()
                            }) {
                                ZStack {
                                    Image(systemName: "person.2.badge.gearshape.fill")
                                        .imageScale(.large)
                                    
                                    if !friendRequestsViewModel.friendRequests.isEmpty {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 10, height: 10)
                                            .offset(x: 12, y: -10)
                                    }
                                }
                            }
                        }
                        ToolbarItem(placement: .principal) {
                            Image(colorScheme == .dark ? "weekly-light" : "weekly-dark")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 35)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            NavigationLink(destination: MessagesView().hideTabBar()) {
                                ZStack {
                                    Image(systemName: "ellipsis.message.fill")
                                        .imageScale(.large)
                                    
                                    if messagesViewModel.hasUnreadMessages {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 10, height: 10)
                                            .offset(x: 12, y: -10)
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
                .offset(x: backgroundOffset * 0.3)
                    .animation(.easeInOut(duration: 0.3), value: isShowingLeftView)
                
                // Left slide-in view with swipe-to-dismiss
                ZStack(alignment: .leading) {
                    if isShowingLeftView {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    isShowingLeftView = false
                                }
                            }
                        
                        AddOrSearchView(isPresented: $isShowingLeftView)
                            .hideTabBar()
                            .frame(width: UIScreen.main.bounds.width)
                            .background(Color(.systemBackground))
                            .offset(x: dragOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let screenWidth = UIScreen.main.bounds.width
                                        // Allow dragging if it starts within 100 points of the right edge and moves left
                                        if value.startLocation.x > (screenWidth - 100) && value.translation.width < 0 {
                                            dragOffset = value.translation.width
                                            backgroundOffset = (UIScreen.main.bounds.width) + (value.translation.width)
                                        }
                                    }
                                    .onEnded { value in
                                        let screenWidth = UIScreen.main.bounds.width
                                        if value.startLocation.x > (screenWidth - 100) && -value.translation.width > screenWidth * 0.4 {
                                            withAnimation(.easeInOut) {
                                                isShowingLeftView = false
                                            }
                                        }
                                        withAnimation(.easeInOut) {
                                            dragOffset = 0
                                        }
                                    }
                            )
                            .transition(.move(edge: .leading))
                            .zIndex(1)
                    }
                }
            }
        }
        .onChange(of: isShowingLeftView) { // Updated syntax
            withAnimation(.easeInOut(duration: 0.3)) {
                backgroundOffset = isShowingLeftView ? UIScreen.main.bounds.width * 0.85 : 0
            }
        }
        .onAppear {
            viewModel.getDisplayTimeToPostMessage()
            Task {
                if viewModel.posts.isEmpty {
                    await hideSplashScreenWithDelay()
                } else {
                    isShowingSplash = false
                }
            }
            Task {
                if viewModel.posts.isEmpty {
                    try await viewModel.fetchPosts()
                    isLoading = false
                } else {
                    isLoading = false
                    isShowingSplash = false
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
    
    func hideSplashScreenWithDelay() async {
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        withAnimation(.easeOut(duration: 0.5)) {
            isShowingSplash = false
        }
    }
}

struct SplashScreenView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            Image(colorScheme == .dark ? "weekly-light" : "weekly-dark")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 0.5)) {
                        opacity = 0.9
                    }
                }
        }
    }
}

#Preview {
    FeedView()
}
