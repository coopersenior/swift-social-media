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
    
    @State private var selectedUserId: String? = nil
    @State private var showConfirmation = false
    
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        Button {
            impactFeedbackGenerator.prepare()
            impactFeedbackGenerator.impactOccurred()
            if viewModel.isFriend(userId: user.id){
                // call remove friend with same warning popup
                selectedUserId = user.id
                showConfirmation = true
            } else if isRequestSent {
                // call deny request
                print("unsend req")
                viewModel.denyFriendRequest(friendUid: user.id)
                isRequestSent = false
            } else if viewModel.isRequestRecieved(userId: user.id){
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
            Text(viewModel.isFriend(userId: user.id) ? "Remove Friend" : isRequestSent ? "Request Sent" : viewModel.isRequestRecieved(userId: user.id) ? "Accept Request" : "Add Friend")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 360, height: 32)
                .background(viewModel.isFriend(userId: user.id) ? .white : isRequestSent ? .white : Color(.systemBlue))
                .foregroundColor(viewModel.isFriend(userId: user.id) ? .black : isRequestSent ? .black : .white)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(viewModel.isFriend(userId: user.id) ? Color.gray : isRequestSent ? Color.gray : .clear, lineWidth: 1)
                )
        }
        .onAppear {
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
