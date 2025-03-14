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
    @State private var selectedUser: User?
    @State private var postSent: Bool = false
    @StateObject var viewModel = AddOrSearchViewModel()
    @StateObject var messageViewModel = SharePostAsMessageViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State var text = ""
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    init(post: Post) {
        self.post = post
    }
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return viewModel.friends
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
        // search bar
        if selectedUser == nil {
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
        }
        
        // view
        ScrollView {
            LazyVStack (spacing: 12){
                
                if let selectedUser = selectedUser {
                    HStack {
                        CircularProfileImageView(user: selectedUser, size: .small)
                        
                        VStack(alignment: .leading) {
                            Text(selectedUser.username)
                                .fontWeight(.semibold)
                            if let fullname = selectedUser.fullname {
                                Text(fullname)
                            }
                            
                        }
                        .font(.footnote)
                       
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    .onTapGesture {
                        self.selectedUser = nil
                        text = ""
                    }
                } else {
                    if (!searchText.isEmpty) {
                        Text("Searching all users")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    
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
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                        .onTapGesture {
                            selectedUser = user;
                        }
                    }
                }
               
            }
        }
        .overlay(
            ZStack {
                HStack {
                    Text("Post sent!")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.25) : Color.gray.opacity(0.25))
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
            .padding()
            .opacity(postSent ? 1 : 0)  // Heart fades in and out
            .animation(.easeInOut(duration: 0.1), value: postSent)
        )
        
        if let selectedUser = selectedUser {
            HStack {
                TextField("Add a messsage...", text: $text)
                
                Button {
                    impactFeedbackGenerator.prepare()
                    impactFeedbackGenerator.impactOccurred()
                    // always send post even without message
                    messageViewModel.sendPost(postId: post.id, receivingUserUid: selectedUser.id)
                    if text.count > 0 {
                        // if message exists send that too
                        messageViewModel.sendMessage(text: text, receivingUserUid: selectedUser.id)
                        text = ""
                    }
                    self.selectedUser = nil
                    postSent = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        postSent = false
                    }
                } label : {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(Color(.white))
                        .padding(10)
                        .background(Color(.systemBlue))
                        .cornerRadius(50)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(uiColor: .systemGray5))
            .cornerRadius(50)
            .padding()
        }
    }
}
