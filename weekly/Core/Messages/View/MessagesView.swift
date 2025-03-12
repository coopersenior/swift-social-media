//
//  SearchView.swift
//  weekly
//
//  Created by Cooper Senior on 12/11/24.
//

import SwiftUI

struct MessagesView: View {
    @State private var searchText = ""
    @StateObject var viewModel = MessagesViewModel()
    @State private var selectedUserId: String? = nil
    @State private var showConfirmation = false
    
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    var filteredUsers: [User] {
        // Get friends list
        let friends = viewModel.usersFriends
        
        // Get recent users that exist in viewModel.users
        let recentUsers = viewModel.recentUsers.compactMap { userId in
            viewModel.users.first(where: { $0.id == userId })
        }
        
        // Merge recent users and friends while ensuring no duplicates
        var uniqueUsers = [User]()
        var seenUserIds = Set<String>()
        
        for user in recentUsers + friends {
            if !seenUserIds.contains(user.id) {
                uniqueUsers.append(user)
                seenUserIds.insert(user.id)
            }
        }
        
        // Sort users by priority
        let sortedUsers = uniqueUsers.sorted { user1, user2 in
            let isRecent1 = viewModel.recentUsers.contains(user1.id)
            let isRecent2 = viewModel.recentUsers.contains(user2.id)
            
            // Prioritize recent users
            if isRecent1 != isRecent2 {
                return isRecent1
            }
            
            let hasUnread1 = viewModel.hasUnreadMessages(for: user1.id)
            let hasUnread2 = viewModel.hasUnreadMessages(for: user2.id)
            
            // Prioritize users with unread messages
            if hasUnread1 != hasUnread2 {
                return hasUnread1
            }
            
            // If both are recent, sort by their position in recentUsers
            if let index1 = viewModel.recentUsers.firstIndex(of: user1.id),
               let index2 = viewModel.recentUsers.firstIndex(of: user2.id) {
                return index1 < index2 // Lower index means more recent
            }
            
            return false
        }
        
        // Apply search filtering
        if searchText.isEmpty {
            return sortedUsers // Show only recent users + friends
        } else {
            return viewModel.users.filter {
                $0.username.lowercased().contains(searchText.lowercased()) ||
                ($0.fullname?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredUsers) { user in
                    NavigationLink(destination: SingleChatView(user: user)) {
                        HStack {
                            CircularProfileImageView(user: user, size: .small)
                            VStack(alignment: .leading) {
                                Text(user.username)
                                    .fontWeight(.semibold)
                                if let fullname = user.fullname {
                                    Text(fullname)
                                }
                            }
                            .font(.footnote)
                            Spacer()
                            
                            if viewModel.hasUnreadMessages(for: user.id) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                            }
                            
                        }
                        .padding(.horizontal)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        // Update the recent user cache
                        viewModel.updateRecentUser(userId: user.id)
                    })
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5) // Adjust duration as needed
                            .onEnded { _ in
                                if !viewModel.usersFriends.contains(where: { $0.id == user.id }) { // Check if user is not in usersFriends
                                    impactFeedbackGenerator.prepare()
                                    impactFeedbackGenerator.impactOccurred()
                                    selectedUserId = user.id
                                    showConfirmation = true
                                }
                            }
                    )
                }
            }
            .padding(.top, 8)
            .searchable(text: $searchText, prompt: "Search all users...")
        }
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.listenToMessages()
        }
        .onDisappear {
            viewModel.stopListening()
        }
        .alert("Are you sure?", isPresented: $showConfirmation, actions: {
            Button("Remove from recents", role: .destructive) {
                if let userId = selectedUserId {
                    viewModel.removeRecentUser(userId: userId)
                }
            }
            Button("Cancel", role: .cancel) {}
        }, message: {
            Text("This will not remove friends")
        })
    }
}

