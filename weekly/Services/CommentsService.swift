//
//  CommentsService.swift
//  weekly
//
//  Created by Cooper Senior on 1/20/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class CommentsService: ObservableObject {
    @Published private(set) var comments: [Comment] = []
    
    private let post: Post
    
    let posts = Firestore.firestore().collection("posts")
    let currentUserUid = Auth.auth().currentUser!.uid // within messages a user must exist
    
    init(post: Post) {
        self.post = post
        getComments()
    }
    
    func sendComment(text: String) {
        Task {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let user = try await UserService.fetchUser(withUid: uid)
            
            let comment = Comment(id: "\(UUID())", postId: post.id, commentUserId: uid, commentUsername: user.username, commentFullname: user.fullname, text: text, timestamp: Timestamp())
            
            try posts.document(post.id).collection("comments").document().setData(from: comment)
        }
    }
    
    func getComments() {
        let commentsRef = posts.document(post.id).collection("comments")
        
        // Fetch comments ordered by timestamp in descending order (newest first)
        commentsRef.order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching comments: \(String(describing: error))")
                    return
                }
                
                self.comments = documents.compactMap { document -> Comment? in
                    do {
                        return try document.data(as: Comment.self)
                    } catch {
                        print("Error decoding document into Comment: \(error)")
                        return nil
                    }
                }
            }
    }
    
    func isCommentAuthor(withUid uid: String) -> Bool {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return false }
        return uid == currentUserUid
    }
    
    func deleteComment(postId: String, commentId: String) async throws {
        let commentsRef = posts.document(postId).collection("comments")
        
        // Query the comments collection to find the comment with the given commentId
        let snapshot = try await commentsRef.whereField("id", isEqualTo: commentId).getDocuments()
        
        // Ensure that a document with the given commentId was found
        guard let document = snapshot.documents.first else {
            throw NSError(domain: "CommentsServiceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "No comment found with the given commentId"])
        }
        
        // Reference to the specific comment document
        let commentRef = commentsRef.document(document.documentID)
        
        // Perform the delete operation
        do {
            try await commentRef.delete()
            print("Comment deleted successfully")
        } catch {
            throw NSError(domain: "CommentsServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Error deleting comment: \(error.localizedDescription)"])
        }
    }
}
