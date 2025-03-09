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
    @Published var displayTimeToPostMessage: Bool = false
    
    init() {
        Task {
            try await fetchPosts()
            //listenToPosts()
        }
    }
    
    @MainActor
    func fetchPosts() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let friends = try await UserService.fetchAllFriends(withUid: uid)
            
        let allPosts = try await PostService.fetchFeedPosts(uid: uid)
        
        self.posts = allPosts.filter { post in
            // Include posts from friends or the current user
            friends.contains(where: { $0.id == post.ownerUid }) || post.ownerUid == uid
        }
    }
    
    func getDisplayTimeToPostMessage() {
        Task {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let hasPosted = await (try? PostService.checkHasPosted(uid: uid)) ?? false
            DispatchQueue.main.async {
                //print("OUTPUT from time to post!!: ", !hasPosted)
                self.displayTimeToPostMessage = !hasPosted  // TODO verify logic but user should always be prompted to post if they havent
            }
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
    
    func listenToLikes(for postId: String, updateLikes: @escaping (Int) -> Void) {
        let postRef = Firestore.firestore().collection("posts").document(postId)
        
        postRef.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error listening to likes: \(error.localizedDescription)")
                return
            }
            
            // If there's new data for the post, update the likes count
            if let data = snapshot?.data(), let likes = data["likes"] as? Int {
                DispatchQueue.main.async {
                    updateLikes(likes) // Update the likes count
                }
            }
        }
    }
    
    func listenToComments(for postId: String, updateComments: @escaping (Int) -> Void) {
        let commentsRef = Firestore.firestore()
            .collection("posts")
            .document(postId)
            .collection("comments")

        commentsRef.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error listening to comments: \(error.localizedDescription)")
                return
            }

            // If there are comments, count them, otherwise return 0
            let count = snapshot?.documents.count ?? 0
            
            DispatchQueue.main.async {
                updateComments(count) // Update the UI with the comment count
            }
        }
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
        getDisplayTimeToPostMessage()
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
        Task {
            try await fetchPosts()
            getDisplayTimeToPostMessage()
        }
        // This function doesn't need to do anything with the posts.
        // Its purpose is to trigger a re-render of the View.
        objectWillChange.send()
    }

    func stopListening() {
        postsListener?.remove()
    }
    
    func deletePost(postId: String) async throws {
        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(postId)

        // Fetch the post document to get the imageUrl
        let snapshot = try await postRef.getDocument()
        guard let postData = snapshot.data(),
              let imageUrl = postData["imageUrl"] as? String else {
            throw NSError(domain: "DeletePostError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Post or image URL not found."])
        }

        // Extract the storage path from the imageUrl
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

        // delete all subcollections
        let subcollections = ["comments", "likes"] // Add more if needed
        for subcollection in subcollections {
            let subcollectionRef = postRef.collection(subcollection)
            let subcollectionDocs = try await subcollectionRef.getDocuments()

            for document in subcollectionDocs.documents {
                try await document.reference.delete()
            }
        }

        // delete the post document
        try await postRef.delete()
        print("Post deleted successfully.")

        try await AuthService().checkHasPosted()
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
