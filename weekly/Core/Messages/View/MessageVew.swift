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
    @State private var selectedMessageId: String? = nil
    @State private var selectedReceiverId: String? = nil
    @State private var showConfirmation = false
    @StateObject var viewModel = MessagesViewModel()
    
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    
    private var timeElapsed: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let date = message.timestamp.dateValue()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser() {
                VStack {
                    Text(message.text)
                        .padding()
                        .background(Color(uiColor: .systemBlue))
                        .cornerRadius(20)
                        .font(.subheadline)
                        .frame(maxWidth: 260, alignment: .trailing)
                    
                    Text(timeElapsed)
                        .font(.footnote)
                        .padding(.top, 0.5)
                        .foregroundStyle(.gray)
                        .frame(maxWidth: 260, alignment: .trailing)
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
                    HStack {
                        CircularProfileImageView(user: user, size: .xSmall)
                        HStack {
                            Text(message.text)
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
                .frame(maxWidth: 360, alignment: .leading)
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
}

#Preview {
    MessageVew(message: Message(id: "123", sendingUserUid: "12345", receivingUserUid: "12315", text: "The framing better be better on this nice chat being sent", timestamp: Timestamp()), user: User.MOCK_USERS[0])
}
