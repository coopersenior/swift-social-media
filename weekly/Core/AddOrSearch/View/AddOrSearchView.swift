//
//  AddOrSearchView.swift
//  weekly
//
//  Created by Cooper Senior on 1/14/25.
//

import SwiftUI

struct AddOrSearchView: View {
    @State private var searchText = ""
    @StateObject var viewModel = AddOrSearchViewModel()
    @State private var selectedUserId: String? = nil
    @State private var showConfirmation = false
    @Binding var isPresented: Bool
    
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return viewModel.users
        } else {
            return viewModel.users.filter {
                $0.username.lowercased().contains(searchText.lowercased()) ||
                ($0.fullname?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // removes other sections when search starts
                if (searchText.isEmpty) {                        //         --------- Friend Requests -----------
                    // check if there are any request to display
                    if (viewModel.friendRequests.count > 0) {
                        Text("Friend Requests")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    
                    LazyVStack (spacing: 12){
                        ForEach(viewModel.friendRequests) { user in
            
                            NavigationLink(destination: ProfileView(user: user)) {
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
                                    
                                    Button {
                                        impactFeedbackGenerator.prepare()
                                        impactFeedbackGenerator.impactOccurred()
                                        viewModel.acceptFriendRequest(friendUid: user.id)
                                    } label: {
                                        Image(systemName: "person.fill.checkmark")
                                            .imageScale(.large)
                                            .padding()
                                    }
                                    
                                    Button {
                                        impactFeedbackGenerator.prepare()
                                        impactFeedbackGenerator.impactOccurred()
                                        viewModel.denyFriendRequest(friendUid: user.id)
                                    } label: {
                                        Image(systemName: "person.fill.xmark")
                                            .imageScale(.medium)
                                            .padding()
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
    //         --------- My Friends -----------
                    Text("My Friends")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    
                    LazyVStack (spacing: 12){
                        ForEach(viewModel.friends) { user in
                            NavigationLink(destination: ProfileView(user: user)) {
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
                                    
                                    Button {
                                        impactFeedbackGenerator.prepare()
                                        impactFeedbackGenerator.impactOccurred()
                                        selectedUserId = user.id
                                        showConfirmation = true
                                    } label: {
                                        Image(systemName: "person.fill.xmark")
                                            .imageScale(.medium)
                                            .padding()
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                        }
                    }
                    //         --------- Suggested Requests -----------
                    Text("Suggested Friends")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    // TODO: find a way to suggest people they know
                    LazyVStack (spacing: 12){
                        ForEach(viewModel.suggestedUsers) { user in  // change to the sorting by people they may know and remove current friends 
                            NavigationLink(destination: ProfileView(user: user)) {
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
                                }
                                .padding(.horizontal)
                            }
                            
                        }
                    }
                }
//         --------- Searching all users -----------
                if (!searchText.isEmpty) {
                    Text("Searching all users")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                // TODO: find a way to suggest people they know
                LazyVStack (spacing: 12){
                    if (!searchText.isEmpty) {
                        ForEach(filteredUsers) { user in
                            NavigationLink(destination: ProfileView(user: user)) {
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
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.top, 8)
                .searchable(text: $searchText, prompt: "Add or search friends")
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Manage Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false // Dismiss the view
                        }
                    }) {
                        Image(systemName: "chevron.right") // Back arrow
                            .imageScale(.large)
                    }
                }
            }
        }
        .onAppear {
            viewModel.listenToFriendRequests()
            viewModel.listenToFriends()
            viewModel.listenToSuggestedUsers()
        }
        .onDisappear {
            viewModel.stopListening() // Stop listeners when the view disappears
        }
        .alert("Are you sure?", isPresented: $showConfirmation, actions: {
            Button("Remove", role: .destructive) {
                if let userId = selectedUserId {
                    viewModel.removeFriend(friendUid: userId)
                }
            }
            Button("Cancel", role: .cancel) {}
        }, message: {
            Text("This will remove the friend from your list.")
        })
    }
}

#Preview {
    AddOrSearchView(isPresented: .constant(true))
}
