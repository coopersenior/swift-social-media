//
//  FeedViewModel.swift
//  weekly
//
//  Created by Cooper Senior on 12/13/24.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseStorage

class FeedViewModel: ObservableObject {
    @Published var posts = [Post]()
    private var postsListener: ListenerRegistration?
    
    init() {
        Task {
            try await fetchPosts()
            listenToPosts()
        }
    }
    
    @MainActor
    func fetchPosts() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let friends = try await UserService.fetchAllFriends(withUid: uid)
            
        let allPosts = try await PostService.fetchFeedPosts()
        
        self.posts = allPosts.filter { post in
            // Include posts from friends or the current user
            friends.contains(where: { $0.id == post.ownerUid }) || post.ownerUid == uid
        }
    }
    
    func likePost(postId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        // Reference to the specific post document
        let postRef = Firestore.firestore().collection("posts").document(postId)
        
        let likesRef = postRef.collection("likes").document(uid)
        
        // Set the liked status for this user
        try await likesRef.setData(["liked": true])
        
        // Increment the 'likes' field atomically
        try await postRef.updateData([
            "likes": FieldValue.increment(Int64(1)) // Increment by 1
        ])
    }
    
    func unlikePost(postId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let postRef = Firestore.firestore().collection("posts").document(postId)
        
        let likesRef = postRef.collection("likes").document(uid)
        
        // Remove the like document for this user
        try await likesRef.delete()
        
        // Decrement the likes count in the post document
        try await postRef.updateData([
            "likes": FieldValue.increment(Int64(-1))
        ])
    }
    
    func fetchLikeStatus(postId: String) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false}
        
        let likesRef = Firestore.firestore()
                .collection("posts")
                .document(postId)
                .collection("likes")
                .document(uid)
        do {
            // Try to fetch the document snapshot
            let document = try await likesRef.getDocument()
            return document.exists
        } catch {
            print("Error fetching like status: \(error.localizedDescription)")
            throw error
        }
    }
    
    // listeners for live updates
    func listenToPosts() {
        postsListener = Firestore.firestore()
            .collection("posts")
            .order(by: "timestamp", descending: true) // Order posts by timestamp
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening to posts: \(error.localizedDescription)")
                    return
                }

                // Trigger a re-render without modifying the posts array
                DispatchQueue.main.async {
                    self?.triggerReRender()
                }
            }
    }
    
    func triggerReRender() {
        Task { try await fetchPosts() }
        // This function doesn't need to do anything with the posts.
        // Its purpose is to trigger a re-render of the View.
        objectWillChange.send()
    }

    func stopListening() {
        postsListener?.remove()
    }
    
    func deletePost(postId: String) async throws {
        // Reference to the specific post document
        let postRef = Firestore.firestore().collection("posts").document(postId)
        
        // Fetch the post document to get the imageUrl
        let snapshot = try await postRef.getDocument()
        guard let postData = snapshot.data(),
              let imageUrl = postData["imageUrl"] as? String else {
            throw NSError(domain: "DeletePostError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Post or image URL not found."])
        }
        
        // Extract the path from the imageUrl
        guard let storagePath = extractStoragePath(from: imageUrl) else {
            throw NSError(domain: "DeletePostError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid image URL format."])
        }
        
        // Delete the file from Firebase Storage
        let storageRef = Storage.storage().reference(withPath: storagePath)
        do {
            try await storageRef.delete()
            print("File deleted successfully from storage.")
        } catch {
            print("Failed to delete file from storage: \(error.localizedDescription)")
        }
        
        // Delete the post document from Firestore
        try await postRef.delete()
        print("Post deleted successfully.")
    }

    // Helper function to extract the path from the imageUrl
    private func extractStoragePath(from imageUrl: String) -> String? {
        // Example URL: https://firebasestorage.googleapis.com:443/v0/b/<bucket>/o/images%2F<filename>?alt=media&token=<token>
        guard let components = URLComponents(string: imageUrl),
              let path = components.path.split(separator: "/").last else {
            return nil
        }
        
        // Reconstruct the storage path
        return "images/\(path.removingPercentEncoding ?? String(path))"
    }
    
    func fetchUser(withUid uid: String) async throws -> User {
        return try await UserService.fetchUser(withUid: uid)
    }
}
