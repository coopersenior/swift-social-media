//
//  FriendsListViewModel.swift
//  Weekly
//
//  Created by Cooper Senior on 3/4/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FriendsListViewModel: ObservableObject {
    @Published var userFriendList = [User]()
    @Published var isLoading = false
    private var friendsListener: ListenerRegistration?
    
    func fetchUserFriends(uid: String) {
        // Set loading state to true
        isLoading = true
        
        // Firestore reference to the user's friends collection
        let friendsCollection = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("friends")
        
        // Listen to the friend's collection for real-time updates
        friendsListener = friendsCollection.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error listening to friends: \(error.localizedDescription)")
                self.isLoading = false
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.isLoading = false
                return
            }
            
            // Use TaskGroup to fetch friend data concurrently
            Task {
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
                
                // Update the UI on the main thread once the data is fetched
                await MainActor.run {
                    self.userFriendList = friends
                    self.isLoading = false
                }
            }
        }
    }
    
    // Function to stop listening to updates when the view disappears (optional)
    func stopListening() {
        friendsListener?.remove()
    }
}
