//
//  MessageVew.swift
//  weekly
//
//  Created by Cooper Senior on 12/30/24.
//

import SwiftUI
import Firebase
import Kingfisher

struct MessageVew: View {
    var message: Message
    let user: User
    @State private var taggedUser: User?
    @State private var post : Post?
    @State private var selectedMessageId: String? = nil
    @State private var selectedReceiverId: String? = nil
    @State private var showConfirmation = false
    @StateObject var viewModel = MessagesViewModel()
    
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    
    private var timeElapsed: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short

        let date = message.timestamp.dateValue()
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        if timeInterval < 5 {
            return "Just now"
        }

        return formatter.localizedString(for: date, relativeTo: now)
    }
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser() {
                // if message.postId != "" then render post preview
                // check for custom message key
                VStack {
                    if message.text == "72deda80-3bfc-4496-8bc5-04e7c6d7c362" {
                        if let post = post {
                            VStack {
                                NavigationLink(destination: FeedCell(post: post, userProfileView: false)) {
                                    KFImage(URL(string: post.imageUrl))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 200)
                                        .blur(radius: (post.blurred ?? false) ? 15 : 0)
                                        .clipped()
                                        .cornerRadius(10)
                                }
                                if let caption = post.caption, !caption.isEmpty {
                                    Text(caption)
                                        .font(.footnote)
                                        .padding(.top, 0.5)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .padding()
                            .background(Color(uiColor: .systemBlue))
                            .cornerRadius(15)
                            .foregroundColor(.white)
                            .frame(maxWidth: 260, alignment: .trailing)
                            Text(timeElapsed)
                                .font(.footnote)
                                .padding(.top, 0.5)
                                .foregroundStyle(.gray)
                                .frame(maxWidth: 260, alignment: .trailing)
                        } else {
                            // loading state
                            VStack {
                                Image(systemName: "exclamationmark.icloud")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding()
                            }
                            .frame(width: 200, height: 200)
                            .padding()
                            .background(Color(uiColor: .systemBlue))
                            .cornerRadius(15)
                            .foregroundColor(.white)
                        }
                    } else {
                        formatMessageText(from: message.text)
                            .padding()
                            .background(Color(uiColor: .systemBlue))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .font(.subheadline)
                            .frame(maxWidth: 260, alignment: .trailing)
                        //Text(message.text)
                            
                        Text(timeElapsed)
                            .font(.footnote)
                            .padding(.top, 0.5)
                            .padding(.leading, 30)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: 260, alignment: .trailing)
                    }
                }
                .frame(maxWidth: 360, alignment: .trailing)
                .gesture(
                    LongPressGesture(minimumDuration: 0.5) // Adjust duration as needed
                        .onEnded { _ in
                            impactFeedbackGenerator.prepare()
                            impactFeedbackGenerator.impactOccurred()
                            selectedMessageId = message.id
                            selectedReceiverId = message.receivingUserUid
                            showConfirmation = true
                        }
                )
            } else {
                VStack {
                    if message.text == "72deda80-3bfc-4496-8bc5-04e7c6d7c362" {
                        if let post = post {
                            HStack {
                                CircularProfileImageView(user: user, size: .xSmall)
                                VStack {
                                    NavigationLink(destination: FeedCell(post: post, userProfileView: false)) {
                                        KFImage(URL(string: post.imageUrl))
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 200, height: 200)
                                            .blur(radius: (post.blurred ?? false) ? 15 : 0)
                                            .blur(radius: (post.hiddenFromNonFriends ?? false) ? 15 : 0)
                                            .clipped()
                                            .cornerRadius(10)
                                            .overlay(
                                                HStack {
                                                    if let hidden = post.hiddenFromNonFriends, hidden {
                                                        VStack {
                                                            Text("You are not friends with the owner of the post.")
                                                                .font(.footnote)
                                                                .fontWeight(.bold)
                                                                .foregroundColor(.white)
                                                                .padding()
                                                        }
                                                    }
                                                }
                                                        
                                            )
                                    }
                                    if let caption = post.caption, !caption.isEmpty {
                                        Text(caption)
                                            .font(.footnote)
                                            .padding(.top, 0.5)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                .padding()
                                .background(Color(uiColor: .systemGray5))
                                .cornerRadius(15)
                                .frame(maxWidth: 260, alignment: .leading)
                            }
                            Text(timeElapsed)
                                .font(.footnote)
                                .padding(.top, 0.5)
                                .padding(.leading, 30)
                                .foregroundStyle(.gray)
                                .frame(maxWidth: 260, alignment: .leading)
                        } else {
                            // loading state
                            VStack {
                                Image(systemName: "exclamationmark.icloud")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding()
                            }
                            .frame(width: 200, height: 200)
                            .padding()
                            .background(Color(uiColor: .systemGray5))
                            .cornerRadius(15)
                        }
                    } else {
                        HStack {
                            CircularProfileImageView(user: user, size: .xSmall)
                            HStack {
                                formatMessageText(from: message.text)
                                    .padding()
                                    .background(Color(uiColor: .systemGray5))
                                    .cornerRadius(20)
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: 260, alignment: .leading)
                        }
                        Text(timeElapsed)
                            .font(.footnote)
                            .padding(.top, 0.5)
                            .padding(.leading, 30)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: 260, alignment: .leading)
                    }
                    
                }
                .frame(maxWidth: 360, alignment: .leading)
            }
        }
        .onAppear {
            if message.text == "72deda80-3bfc-4496-8bc5-04e7c6d7c362" {
                if let postId = message.postId {
                    Task {
                        do {
                            if let post = try await PostService.fetchPostById(postId: postId) {
                                // Set the post object here
                                self.post = post
                            }
                        } catch {
                            print("Error fetching post: \(error)")
                        }
                    }
                }
            }
        }
        .alert("Are you sure?", isPresented: $showConfirmation, actions: {
            Button("Delete Message", role: .destructive) {
                if let messageId = selectedMessageId {
                    if let receiverId = selectedReceiverId {
                        Task {
                            do {
                                try await viewModel.deleteMessage(messageId: messageId, for: receiverId)
                            } catch {
                                print("Failed to delete post: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }, message: {
            Text("This action cannot be undone.")
        })
    }
    
    @ViewBuilder
        func formatMessageText(from message: String) -> some View {
            if let username = extractUsername(from: message),
               let range = message.range(of: "@\(username)") {
                let before = String(message[..<range.lowerBound])
                let after = String(message[range.upperBound...])
                
                HStack(spacing: 0) {
                    Text(before)
                    if let user = taggedUser {
                        NavigationLink(destination: ProfileView(user: user)) {
                            Text("@\(user.username)")
                        }
                    } else {
                        Text("@\(username)")
                    }
                    
                    Text(after)
                }
                .onAppear {
                    Task {
                        self.taggedUser = try await UserService.fetchUserByUsername(username)
                    }
                }
                
            } else {
                Text(message)
            }
        }
        
        func extractUsername(from text: String) -> String? {
            let words = text.components(separatedBy: .whitespaces)
            if let mentionWord = words.first(where: { $0.hasPrefix("@") }) {
                let username = String(mentionWord.dropFirst())
                return username.isEmpty ? nil : username
            }
            return nil
        }
}

#Preview {
    MessageVew(message: Message(id: "123", sendingUserUid: "12345", receivingUserUid: "12315", text: "The framing better be better on this nice chat being sent", timestamp: Timestamp(), postId: ""), user: User.MOCK_USERS[0])
}
