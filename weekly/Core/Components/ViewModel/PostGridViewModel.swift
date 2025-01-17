//
//  PostGridViewModel.swift
//  weekly
//
//  Created by Cooper Senior on 12/13/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class PostGridViewModel: ObservableObject {
    private let user: User
    @Published var posts = [Post]()
    private var postsListener: ListenerRegistration?
    
    init(user: User) {
        self.user = user
        Task{ try await fetchUserPosts() }
        listenToUserPosts()
    }
    
    @MainActor
    func fetchUserPosts() async throws {
        self.posts = try await PostService.fetchUserPosts(uid: user.id)
        
        for i in 0 ..< posts.count {
            posts[i].user = self.user
        }
    }
    
    func listenToUserPosts() {
        // Listen to posts from this user in Firestore
        postsListener = Firestore.firestore()
            .collection("posts")
            .whereField("ownerUid", isEqualTo: user.id) // Filter posts by user ID
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening to user posts: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = snapshot else { return }
                
                // Convert the snapshot documents into posts
                var fetchedPosts = snapshot.documents.compactMap { document -> Post? in
                    try? document.data(as: Post.self)
                }
                fetchedPosts.sort(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
                // Update the posts array with the fetched posts
                DispatchQueue.main.async {
                    self?.posts = fetchedPosts
                }
            }
    }
    
    func stopListening() {
        postsListener?.remove() // Remove the listener when no longer needed
    }
}
