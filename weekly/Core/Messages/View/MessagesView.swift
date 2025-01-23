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
    
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    var filteredUsers: [User] {
        let sortedUsers = viewModel.users.sorted { user1, user2 in
            let hasUnread1 = viewModel.hasUnreadMessages(for: user1.id)
            let hasUnread2 = viewModel.hasUnreadMessages(for: user2.id)
            
            // Prioritize users with unread messages
            if hasUnread1 != hasUnread2 {
                return hasUnread1 && !hasUnread2
            }
            
            // Secondary sorting: Use index in recentUsers to sort by recency
            if let index1 = viewModel.recentUsers.firstIndex(of: user1.id),
               let index2 = viewModel.recentUsers.firstIndex(of: user2.id) {
                return index1 < index2 // Lower index means more recent
            }
            
            // If only one of the users is in recentUsers, prioritize the one in recentUsers
            if viewModel.recentUsers.contains(user1.id) {
                return true
            } else if viewModel.recentUsers.contains(user2.id) {
                return false
            }
            
            // Default: Keep original order or add any additional sorting logic here
            return false
        }
        
        if searchText.isEmpty {
            return sortedUsers
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
                        .foregroundStyle(.black)
                        .padding(.horizontal)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        // Update the recent user cache
                        viewModel.updateRecentUser(userId: user.id)
                    })
                }
            }
            .padding(.top, 8)
            .searchable(text: $searchText, prompt: "Search...")
        }
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.listenToMessages()
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }
}

