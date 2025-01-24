//
//  MessagesService.swift
//  weekly
//
//  Created by Cooper Senior on 1/3/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class MessagesService: ObservableObject {
    @Published private(set) var messages: [Message] = []
    @Published private(set) var lastMessageId = ""
    
    private let otherUser: User
    
    let users = Firestore.firestore().collection("users")
    let currentUserUid = Auth.auth().currentUser!.uid // within messages a user must exist
    
    init(currentUser: User) {
        self.otherUser = currentUser
        getMessages()
    }
    
    func getMessages() {
        let userRef = users.document(currentUserUid).collection("messages")
        
        let sentMessagesQuery = userRef
            .whereField("sendingUserUid", isEqualTo: currentUserUid)
            .whereField("receivingUserUid", isEqualTo: otherUser.id)
        
        // Query 2: Messages sent by the other user to the current user
        let receivedMessagesQuery = userRef
            .whereField("sendingUserUid", isEqualTo: otherUser.id)
            .whereField("receivingUserUid", isEqualTo: currentUserUid)
        
        sentMessagesQuery.addSnapshotListener { sentSnapshot, sentError in
            guard let sentDocuments = sentSnapshot?.documents else {
                print("Error fetching sent messages: \(String(describing: sentError))")
                return
            }
            
            receivedMessagesQuery.addSnapshotListener { receivedSnapshot, receivedError in
                guard let receivedDocuments = receivedSnapshot?.documents else {
                    print("Error fetching received messages: \(String(describing: receivedError))")
                    return
                }
                
                let allDocuments = sentDocuments + receivedDocuments
                self.messages = allDocuments.compactMap { document -> Message? in
                    do {
                        return try document.data(as: Message.self)
                    } catch {
                        print("Error decoding document into Message: \(error)")
                        return nil
                    }
                }
                self.messages.sort(by: { $0.timestamp.dateValue() < $1.timestamp.dateValue() })
                
                if let id = self.messages.last?.id {
                    self.lastMessageId = id
                }
            }
        }
    }
    
    func sendMessage(text: String, receivingUserUid: String) {
        Task {
            let msgId = UUID()
            let fromMessage = Message(id: "\(msgId)", sendingUserUid: currentUserUid, receivingUserUid: receivingUserUid, text: text, timestamp: Timestamp(), isRead: true, profileId: "")
            
            try users.document(currentUserUid).collection("messages").document().setData(from: fromMessage)
            
            let toMessage = Message(id: "\(msgId)", sendingUserUid: currentUserUid, receivingUserUid: receivingUserUid, text: text, timestamp: Timestamp(), isRead: false, profileId: "")
            try users.document(receivingUserUid).collection("messages").document().setData(from: toMessage)
        }
    }
    
    func markMessagesAsRead() {
        let userRef = users.document(currentUserUid).collection("messages")

        // Query for messages sent by the other user to the current user that are not marked as read
        let unreadMessagesQuery = userRef
            .whereField("sendingUserUid", isEqualTo: otherUser.id)
            .whereField("receivingUserUid", isEqualTo: currentUserUid)
            .whereField("isRead", isEqualTo: false) // Only get unread messages

        unreadMessagesQuery.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching unread messages: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("No unread messages found.")
                return
            }

            for document in documents {
                // Update each unread message's `isRead` field to `true`
                document.reference.updateData(["isRead": true]) { error in
                    if let error = error {
                        print("Failed to mark message as read: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
