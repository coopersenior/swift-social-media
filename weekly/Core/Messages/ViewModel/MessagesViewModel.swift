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
        listenToUnreadMessages()
        // sort users by recent messaging
    }
    
    @MainActor
    func fetchAllUsers() async throws {
        self.users = try await UserService.fetchAllUsers()
        guard let uid = Auth.auth().currentUser?.uid else { return }
                
        self.users = self.users.filter { $0.id != uid }
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
    
}
