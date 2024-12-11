//
//  PostService.swift
//  weekly
//
//  Created by Cooper Senior on 12/13/24.
//

import Firebase

struct PostService {
    
    private static let postsCollection = Firestore.firestore().collection("posts")
    
    static func fetchFeedPosts() async throws -> [Post] {
        let snapshot = try await postsCollection.getDocuments()
        var posts = try snapshot.documents.compactMap({ try $0.data(as: Post.self ) })
        
        for i in 0 ..< posts.count {
            let post = posts[i]
            let ownerUid = post.ownerUid
            let postUser = try await UserService.fetchUser(withUid: ownerUid)
            posts[i].user = postUser
        }
        return posts.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
    }
    
    static func fetchUserPosts(uid: String) async throws -> [Post] {
        let snapshot = try await postsCollection.whereField("ownerUid", isEqualTo: uid).getDocuments()
        let posts = try snapshot.documents.compactMap({ try $0.data(as: Post.self ) })
        return posts.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
    }
    
    static func numberOfUserPosts(uid: String) async throws -> Int {
        return try await fetchUserPosts(uid: uid).count
    }
}
