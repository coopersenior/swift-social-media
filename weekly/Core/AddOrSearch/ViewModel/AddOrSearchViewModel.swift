//
//  AddOrSearchViewModel.swift
//  weekly
//
//  Created by Cooper Senior on 1/14/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AddOrSearchViewModel: ObservableObject {
    @Published var users = [User]()
    @Published var suggestedUsers = [User]()
    @Published var friendRequests = [User]()
    @Published var friends = [User]()
    
    private var friendRequestsListener: ListenerRegistration?
    private var friendsListener: ListenerRegistration?
    private var usersListener: ListenerRegistration?
    private var suggestUsersListener: ListenerRegistration?
    
    
    init() {
        listenToFriends()
        listenToAllUsers()
        listenToFriendRequests()
        listenToSuggestedUsers()
    }
    
    // Suggested Users Listener
    func listenToSuggestedUsers() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No current user UID found")
            return
        }
        suggestUsersListener = Firestore.firestore()
            .collection("users")
            .document(uid)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Snapshot listener error: \(error.localizedDescription)")
                    return
                }
                
                guard documentSnapshot != nil else {
                    print("No document snapshot received")
                    return
                }
                
                Task {
                    // 1. Get current user's friends
                    let friendDocs = try? await Firestore.firestore()
                        .collection("users")
                        .document(uid)
                        .collection("friends")
                        .getDocuments()
                    
                    let friendIds = friendDocs?.documents.compactMap { document in
                        // Extract friendUid from the document data
                        document.data()["friendUid"] as? String
                    } ?? []
                    
                    guard !friendIds.isEmpty else {
                        print("User has no friends, setting empty suggestions")
                        await MainActor.run {
                            self.suggestedUsers = []
                        }
                        return
                    }
                    
                    // 2. Fetch friends of friends
                    var friendsOfFriends: Set<String> = []
                    for friendId in friendIds {
                        do {
                            let fofDocs = try await Firestore.firestore()
                                .collection("users")
                                .document(friendId)
                                .collection("friends")
                                .getDocuments()
                            
                            let fofIds = fofDocs.documents.compactMap { document -> String? in
                                // Extract friendUid from each friend's friends
                                document.data()["friendUid"] as? String
                            }
                            friendsOfFriends.formUnion(fofIds)
                        } catch {
                            print("Error fetching friends for \(friendId): \(error.localizedDescription)")
                        }
                    }
                    
                    // 3. Filter out current user and direct friends
                    friendsOfFriends.remove(uid)
                    friendsOfFriends.subtract(friendIds)
                    
                    // 4. Fetch user details
                    let suggestedUsers: [User]
                    if !friendsOfFriends.isEmpty {
                        let suggestedUserDocs = try? await Firestore.firestore()
                            .collection("users")
                            .whereField(FieldPath.documentID(), in: Array(friendsOfFriends))
                            .getDocuments()
                        
                        suggestedUsers = suggestedUserDocs?.documents.compactMap { document -> User? in
                            try? document.data(as: User.self)
                        } ?? []
                    } else {
                        suggestedUsers = []
                    }
                    
                    // 5. Update UI
                    await MainActor.run {
                        self.suggestedUsers = suggestedUsers
                    }
                }
            }
    }
    
    func listenToAllUsers() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        usersListener = Firestore.firestore()
            .collection("users")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to suggested users: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task {
                    let fetchedUsers = documents.compactMap { document -> User? in
                        try? document.data(as: User.self)
                    }
                    
                    // Filter out the current user
                    let filteredUsers = fetchedUsers.filter { $0.id != uid }
                    
                    await MainActor.run {
                        self.users = filteredUsers
                    }
                }
            }
    }
    
    func listenToRequestStatus(for userId: String, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        // Listen to the target user's requests collection in real-time
        Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("requests")
            .whereField("requestingUserUid", isEqualTo: uid)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to friend requests: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                // Check if the current user has a pending request
                if let snapshot = snapshot, !snapshot.isEmpty {
                    completion(true) // Friend request has been sent
                } else {
                    completion(false) // No request found
                }
            }
    }
    
    // Friend Requests Listener
    func listenToFriendRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let requestsCollection = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("requests")
        
        friendRequestsListener = requestsCollection.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error listening to friend requests: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            Task {
                // Use TaskGroup to fetch user data concurrently
                let requests: [User] = await withTaskGroup(of: User?.self) { group in
                    for document in documents {
                        if let requestingUserUid = document.data()["requestingUserUid"] as? String {
                            group.addTask {
                                do {
                                    return try await UserService.fetchUser(withUid: requestingUserUid)
                                } catch {
                                    print("Error fetching user for friend request: \(error.localizedDescription)")
                                    return nil
                                }
                            }
                        }
                    }
                    
                    // Collect valid users
                    var usersArray: [User] = []
                    for await user in group {
                        if let user = user {
                            usersArray.append(user)
                        }
                    }
                    return usersArray
                }
                
                await MainActor.run {
                    self.friendRequests = requests
                }
            }
        }
    }
    
    // Friends Listener
    func listenToFriends() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let friendsCollection = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("friends")
        
        friendsListener = friendsCollection.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error listening to friends: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            Task {
                // Use TaskGroup to fetch friend data concurrently
                let friends: [User] = await withTaskGroup(of: User?.self) { group in
                    for document in documents {
                        if let friendUid = document.data()["friendUid"] as? String {
                            group.addTask {
                                do {
                                    return try await UserService.fetchUser(withUid: friendUid)
                                } catch {
                                    print("Error fetching friend: \(error.localizedDescription)")
                                    return nil
                                }
                            }
                        }
                    }
                    
                    // Collect valid friends
                    var friendsArray: [User] = []
                    for await friend in group {
                        if let friend = friend {
                            friendsArray.append(friend)
                        }
                    }
                    return friendsArray
                }
                
                await MainActor.run {
                    self.friends = friends
                    self.listenToSuggestedUsers()
                }
            }
        }
    }
    
    func stopListening() {
        friendRequestsListener?.remove()
        friendsListener?.remove()
        usersListener?.remove()
        suggestUsersListener?.remove()
        
    }
    
    func addFriend(friendUid: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
                
        let friendRequestsCollection = Firestore.firestore()
            .collection("users")
            .document(friendUid)
            .collection("requests")
        
        friendRequestsCollection.document(uid).setData([
            "requestingUserUid": uid
        ]) { error in
            if let error = error {
                print("Failed to add friend request: \(error.localizedDescription)")
            } else {
                print("Friend request added successfully")  // debugging
            }
        }
    }
    
    func acceptFriendRequest(friendUid: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
                
        let friendsCollection = Firestore.firestore()
            .collection("users")
            .document(friendUid)
            .collection("friends")
        // add to current users friends
        friendsCollection.document().setData([
            "friendUid": uid,
            "timestamp": Timestamp()
        ]) { error in
            if let error = error {
                print("Failed to accept friend request: \(error.localizedDescription)")
            } else {
                print("Friend added successfully")  // debugging
            }
        }
        let currentUserCollection = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("friends")
        // add to friends friends collection
        currentUserCollection.document()
            .setData([
            "friendUid": friendUid,
            "timestamp": Timestamp()
        ]) { error in
            if let error = error {
                print("Failed to accept friend request: \(error.localizedDescription)")
            } else {
                print("Friend added successfully")  // debugging
            }
        }
        // add to friends
        denyFriendRequest(friendUid: friendUid)
        // remove from requests (call deny func)
    }
    
    func denyFriendRequest(friendUid: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
            
            // Reference to the friend's requests collection
        let currentUserCollection = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("requests")
        
        // Query to find the document with the requestingUserUid matching the current user's UID
        // remove from current users requests collection
        currentUserCollection.whereField("requestingUserUid", isEqualTo: friendUid).getDocuments { snapshot, error in
            if let error = error {
                print("Error retrieving friend requests: \(error.localizedDescription)")
                return
            }
            
            // If the document exists, delete it
            if let document = snapshot?.documents.first {
                document.reference.delete { error in
                    if let error = error {
                        print("Failed to remove friend request: \(error.localizedDescription)")
                    } else {
                        print("Friend request removed successfully")
                    }
                }
            } else {
                print("No friend request found for this user")
            }
        }
        let friendCollection = Firestore.firestore()
            .collection("users")
            .document(friendUid)
            .collection("requests")
        // remove from friends requests collection
        friendCollection.whereField("requestingUserUid", isEqualTo: uid).getDocuments { snapshot, error in
            if let error = error {
                print("Error retrieving friend requests: \(error.localizedDescription)")
                return
            }
            
            // If the document exists, delete it
            if let document = snapshot?.documents.first {
                document.reference.delete { error in
                    if let error = error {
                        print("Failed to remove friend request: \(error.localizedDescription)")
                    } else {
                        print("Friend request removed successfully")
                    }
                }
            } else {
                print("No friend request found for this user")
            }
        }
    }
    
    func removeFriend(friendUid: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
            
            // Reference to the friend's requests collection
        let currentUserCollection = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("friends")
        
        // Query to find the document with the requestingUserUid matching the current user's UID
        // remove from current users requests collection
        currentUserCollection.whereField("friendUid", isEqualTo: friendUid).getDocuments { snapshot, error in
            if let error = error {
                print("Error retrieving friend: \(error.localizedDescription)")
                return
            }
            
            // If the document exists, delete it
            if let document = snapshot?.documents.first {
                document.reference.delete { error in
                    if let error = error {
                        print("Failed to remove friend: \(error.localizedDescription)")
                    } else {
                        print("Friend removed successfully")
                    }
                }
            } else {
                print("No friend found for this user")
            }
        }
        let friendCollection = Firestore.firestore()
            .collection("users")
            .document(friendUid)
            .collection("friends")
        // remove from friends requests collection
        friendCollection.whereField("friendUid", isEqualTo: uid).getDocuments { snapshot, error in
            if let error = error {
                print("Error retrieving friend: \(error.localizedDescription)")
                return
            }
            
            // If the document exists, delete it
            if let document = snapshot?.documents.first {
                document.reference.delete { error in
                    if let error = error {
                        print("Failed to remove friend: \(error.localizedDescription)")
                    } else {
                        print("Friend removed successfully")
                    }
                }
            } else {
                print("No friend found for this user")
            }
        }
    }
    
    func isFriend(userId: String) -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        
        return friends.contains { $0.id == userId } || uid == userId
    }
    
    func fetchFollowerCount(for userId: String, completion: @escaping (Int) -> Void) {
        Firestore.firestore()
            .collection("users")
            .document(userId)  // Use the passed userId here
            .collection("friends")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to fetch follower count: \(error.localizedDescription)")
                    completion(0)
                    return
                }
                let count = snapshot?.documents.count ?? 0
                completion(count)
            }
    }
    
    func isRequestRecieved(userId: String) -> Bool {
        return friendRequests.contains { $0.id == userId }
    }
    
    func isRequestSent(to userId: String, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let friendRequestsCollection = Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("requests")
        
        // Query the target user's requests collection to check if your UID exists
        friendRequestsCollection.whereField("requestingUserUid", isEqualTo: uid).getDocuments { snapshot, error in
            if let error = error {
                print("Error checking if friend request was sent: \(error.localizedDescription)")
                completion(false)
                return
            }

            // If a document exists, a request has been sent
            if let documents = snapshot?.documents, !documents.isEmpty {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
}
