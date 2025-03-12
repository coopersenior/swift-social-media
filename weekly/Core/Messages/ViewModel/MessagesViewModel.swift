//
//  MessagesViewModel.swift
//  weekly
//
//  Created by Cooper Senior on 12/18/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore


class MessagesViewModel: ObservableObject {
    @Published var users = [User]()
    @Published var usersFriends = [User]()
    @Published var hasUnreadMessages: Bool = false
    @Published private(set) var unreadMessageUsers: Set<String> = []
    @Published private(set) var recentUsers: [String] = [] {
        didSet {
            saveRecentUsers()
        }
    }
    
    private var messagesListener: ListenerRegistration?
    private var userListener: ListenerRegistration?
    private let recentUsersKey = "recentUsersKey"
    
    init() {
        loadRecentUsers()
        Task { try await fetchAllUsers() }
        Task { try await fetchAllFriends() }
        listenToUnreadMessages()
        // sort users by recent messaging
    }
    
    @MainActor
    func fetchAllUsers() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        self.users = try await UserService.fetchAllUsers()
                
        self.users = self.users.filter { $0.id != uid }
    }
    
    @MainActor
    func fetchAllFriends() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        self.usersFriends = try await UserService.fetchAllFriends(withUid: uid)
                
        self.usersFriends = self.usersFriends.filter { $0.id != uid }
    }
    
    func listenToMessages() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        // Listen to the current user's messages collection
        messagesListener = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("messages")
            .whereField("isRead", isEqualTo: false) // Query only unread messages
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to messages: \(error.localizedDescription)")
                    return
                }

                // Update hasUnreadMessages based on the query result
            self.hasUnreadMessages = !(snapshot?.isEmpty ?? true)
        }
    }

    private func listenToUnreadMessages() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        messagesListener = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("messages")
            .whereField("isRead", isEqualTo: false) // Only track unread messages
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching unread messages: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // Extract the sending user IDs from unread messages
                let senders = documents.compactMap { $0.data()["sendingUserUid"] as? String }
                DispatchQueue.main.async {
                    self.unreadMessageUsers = Set(senders)
            }
        }
    }
        
    func hasUnreadMessages(for userId: String) -> Bool {
        return unreadMessageUsers.contains(userId)
    }
    
    func updateRecentUser(userId: String) {
        DispatchQueue.main.async {
            // Remove the user if they already exist in the list
            self.recentUsers.removeAll(where: { $0 == userId })
            
            // Add the user to the beginning of the list
            self.recentUsers.insert(userId, at: 0)
            
            // Ensure the list only keeps the last 10 entries
            if self.recentUsers.count > 10 {
                self.recentUsers.removeLast(self.recentUsers.count - 10)
            }
        }
    }
    
    func removeRecentUser(userId: String) {
        DispatchQueue.main.async {
            // Remove the user if they already exist in the list
            self.recentUsers.removeAll(where: { $0 == userId })
        }
    }
    
    private func saveRecentUsers() {
        UserDefaults.standard.set(recentUsers, forKey: recentUsersKey)
    }
        
    private func loadRecentUsers() {
        if let savedUsers = UserDefaults.standard.array(forKey: recentUsersKey) as? [String] {
            self.recentUsers = savedUsers
        }
    }
    
    func stopListening() {
        messagesListener?.remove()
    }
    
    func deleteMessage(messageId: String, for receiverUserId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "DeleteMessageError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }

        // Reference to the messages collection
        let senderMessagesRef = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("messages")
        
        let receiverMessagesRef = Firestore.firestore()
            .collection("users")
            .document(receiverUserId)
            .collection("messages")

        // Query the message by its `id` field
        let senderQuery = senderMessagesRef.whereField("id", isEqualTo: messageId)
        let receiverQuery = receiverMessagesRef.whereField("id", isEqualTo: messageId)

        do {
            // Fetch and delete the sender's message
            let senderSnapshot = try await senderQuery.getDocuments()
            if let senderDocument = senderSnapshot.documents.first {
                try await senderDocument.reference.delete()
                print("Message with ID \(messageId) deleted from sender's collection.")
            } else {
                print("Message not found in sender's collection.")
            }

            // Fetch and delete the receiver's message
            let receiverSnapshot = try await receiverQuery.getDocuments()
            if let receiverDocument = receiverSnapshot.documents.first {
                try await receiverDocument.reference.delete()
                print("Message with ID \(messageId) deleted from receiver's collection.")
            } else {
                print("Message not found in receiver's collection.")
            }
        } catch {
            throw NSError(domain: "DeleteMessageError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to delete the message. \(error.localizedDescription)"])
        }
    }
    
}
