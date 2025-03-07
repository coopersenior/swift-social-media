//
//  SharePostView.swift
//  Weekly
//
//  Created by Cooper Senior on 1/24/25.
//

import SwiftUI

struct SharePostView: View {
    let post : Post
    @State private var searchText = ""
    @StateObject var viewModel = AddOrSearchViewModel()
    @StateObject var messageViewModel = SharePostAsMessageViewModel()
    @Environment(\.colorScheme) var colorScheme
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    init(post: Post) {
        self.post = post
    }
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
        Text("Share post")
            .font(.subheadline)
            .fontWeight(.semibold)
            .padding(.top)
        
        Divider()
        HStack {
            // Magnifying Glass Icon
            Image(systemName: "magnifyingglass")
                .foregroundColor(colorScheme == .dark ? Color.secondary : Color.secondary)
            
            // Text Field
            TextField("Search all users", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(colorScheme == .dark ? Color.primary : Color.primary)
                .tint(colorScheme == .dark ? .white : .black)
                .disableAutocorrection(true)
                .autocapitalization(.none)
            
            // Clear Button
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(colorScheme == .dark ? Color.secondary : Color.secondary)
                }
            }
        }
        .padding(10)
        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    
        
        ScrollView {
            LazyVStack (spacing: 12){
                if (searchText.isEmpty) {
                    ForEach(viewModel.friends) { user in
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
                                messageViewModel.sendMessage(postId: post.id, receivingUserUid: user.id)
                            } label : {
                                Image(systemName: "paperplane.fill")
                                    .foregroundStyle(Color(.white))
                                    .padding(10)
                                    .background(Color(.systemBlue))
                                    .cornerRadius(50)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                    }
                    
                    ForEach(viewModel.suggestedUsers) { user in
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
                                messageViewModel.sendMessage(postId: post.id, receivingUserUid: user.id)
                            } label : {
                                Image(systemName: "paperplane.fill")
                                    .foregroundStyle(Color(.white))
                                    .padding(10)
                                    .background(Color(.systemBlue))
                                    .cornerRadius(50)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                    }
                } else {
                    Text("Searching all users")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    
                    ForEach(filteredUsers) { user in
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
                                messageViewModel.sendMessage(postId: post.id, receivingUserUid: user.id)
                            } label : {
                                Image(systemName: "paperplane.fill")
                                    .foregroundStyle(Color(.white))
                                    .padding(10)
                                    .background(Color(.systemBlue))
                                    .cornerRadius(50)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                    }
                }
            }
        }
    }
}
