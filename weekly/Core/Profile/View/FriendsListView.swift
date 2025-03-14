//
//  FriendsList.swift
//  Weekly
//
//  Created by Cooper Senior on 3/4/25.
//

import SwiftUI

struct FriendsListView: View {
    @StateObject var viewModel = FriendsListViewModel()
    let user: User
    @State private var searchText = ""
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return viewModel.userFriendList
        } else {
            return viewModel.userFriendList.filter {
                $0.username.lowercased().contains(searchText.lowercased()) ||
                ($0.fullname?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text("Friends")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                
                if viewModel.isLoading {
                    // Show a loading spinner while data is being fetched
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    LazyVStack (spacing: 12){
                        ForEach(filteredUsers) { friend in
                            NavigationLink(destination: ProfileView(user: friend)) {
                                HStack {
                                    CircularProfileImageView(user: friend, size: .small)
                                    
                                    VStack(alignment: .leading) {
                                        Text(friend.username)
                                            .fontWeight(.semibold)
                                        if let fullname = friend.fullname {
                                            Text(fullname)
                                        }
                                    }
                                    .font(.footnote)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search friends")
                }
            }
            .onAppear {
                viewModel.fetchUserFriends(uid: user.id)
            }
            .onDisappear {
                viewModel.stopListening()
            }
            .navigationTitle("@\(user.username)") // username of who we are on
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


