//
//  ProfileFriendButton.swift
//  weekly
//
//  Created by Cooper Senior on 1/16/25.
//

import SwiftUI

struct ProfileFriendButton: View {
    @StateObject var viewModel = AddOrSearchViewModel()
    let user: User
    @State private var isRequestSent: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedUserId: String? = nil
    @State private var showConfirmation = false
    @State private var isLoading: Bool = true
    
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        let isFriend = viewModel.isFriend(userId: user.id)
        let isRequestRecieved = viewModel.isRequestRecieved(userId: user.id)
        Button {
            impactFeedbackGenerator.prepare()
            impactFeedbackGenerator.impactOccurred()
            if isFriend {
                // call remove friend with same warning popup
                selectedUserId = user.id
                showConfirmation = true
            } else if isRequestSent {
                // call deny request
                print("unsend req")
                viewModel.denyFriendRequest(friendUid: user.id)
                isRequestSent = false
            } else if isRequestRecieved {
                // accept friend req
                print("accept req")
                viewModel.acceptFriendRequest(friendUid: user.id)
                isRequestSent = false
            } else {
                // add friend
                print("add friend")
                viewModel.addFriend(friendUid: user.id)
                isRequestSent = true
            }
        } label: {
            if !isLoading {
                Text(isFriend ? "Remove Friend" : isRequestSent ? "Request Sent" : isRequestRecieved ? "Accept Request" : "Add Friend")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 360, height: 32)
                    .background(viewModel.isFriend(userId: user.id) ? .clear : isRequestSent ? .clear : Color(.systemBlue))
                    .foregroundColor(viewModel.isFriend(userId: user.id) ? colorScheme == .dark ? .white : .black : isRequestSent ? colorScheme == .dark ? .white : .black : .white)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isFriend ? Color.gray : isRequestSent ? Color.gray : .clear, lineWidth: 1)
                    )
            } else {
                Text("")
                    .frame(width: 360, height: 32)
                    .background(.clear)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray, lineWidth: 1)
                    )
            }
            
        }
        .onAppear {
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000) // 500ms (half a second)
                isLoading = false
            }
            viewModel.listenToFriendRequests()
            viewModel.listenToFriends()
            viewModel.listenToSuggestedUsers()
            
            viewModel.listenToRequestStatus(for: user.id) { sent in
                isRequestSent = sent
            }
        }
        .onDisappear {
            viewModel.stopListening() // Stop listeners when the view disappears
        }
        .alert("Are you sure?", isPresented: $showConfirmation, actions: {
            Button("Remove", role: .destructive) {
                if let userId = selectedUserId {
                    viewModel.removeFriend(friendUid: userId)
                    print("remove friend")
                }
            }
            Button("Cancel", role: .cancel) {}
        }, message: {
            Text("This will remove the friend from your list.")
        })
    }
}

#Preview {
    ProfileFriendButton(user: User.MOCK_USERS[0])
}
