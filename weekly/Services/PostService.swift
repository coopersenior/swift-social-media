//
//  PostService.swift
//  weekly
//
//  Created by Cooper Senior on 12/13/24.
//

import Firebase
import FirebaseAuth

struct PostService {
    
    private static let postsCollection = Firestore.firestore().collection("posts")
    static let postResetDate = 5 // 5 for Friday, 2 for Monday
    
    static func fetchFeedPosts(uid: String) async throws -> [Post] {
        let snapshot = try await postsCollection.getDocuments()
        var posts = try snapshot.documents.compactMap({ try $0.data(as: Post.self) })
        // Fetch user data
        let hasPosted = try await isLastPostRecentAndAfterResetDate(uid: uid)
        let userPostsCount = try await numberOfUserPosts(uid: uid)
        let calendar = Calendar.current
        let today = Date()

        // Find last check day
        let lastCheckDay: Date? = {
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
            components.weekday = postResetDate // Monday is 2 in the Gregorian calendar
            return calendar.date(from: components)
        }()
        for i in 0 ..< posts.count {
            let post = posts[i]
            let ownerUid = post.ownerUid
            let postUser = try await UserService.fetchUser(withUid: ownerUid)
            posts[i].user = postUser

            let postDate = post.timestamp.dateValue()
            
            // Default: don't blur the post
            posts[i].blurred = false

            // If the user has no posts, blur everything
            if userPostsCount < 1 {
                posts[i].blurred = true
            }
            // If the user hasn't posted since Monday, blur new posts
            else if ownerUid != uid, let lastCheckDay, !hasPosted, postDate > lastCheckDay {
                posts[i].blurred = true
            }
        }
        return posts.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
    }
    
    static func fetchUserPosts(uid: String) async throws -> [Post] {
        let snapshot = try await postsCollection.whereField("ownerUid", isEqualTo: uid).getDocuments()
        var posts = try snapshot.documents.compactMap({ try $0.data(as: Post.self) })
        guard let userUid = Auth.auth().currentUser?.uid else { return posts }
        // Fetch user's posting history
        let hasPosted = try await PostService.isLastPostRecentAndAfterResetDate(uid: userUid)

        let userPostsCount = try await numberOfUserPosts(uid: userUid)

        let calendar = Calendar.current
        let today = Date()

        // Find last check day
        let lastCheckDay: Date? = {
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
            components.weekday = postResetDate // Monday is 2 in the Gregorian calendar
            return calendar.date(from: components)
        }()

        for i in 0 ..< posts.count {
            let post = posts[i]
            let postDate = post.timestamp.dateValue()
            let ownerUid = post.ownerUid

            // Default: don't blur the post
            posts[i].blurred = false

            // If the user has no posts, blur everything
            if userPostsCount < 1 {
                posts[i].blurred = true
            }
            // If the user hasn't posted since reset date, blur new posts
            else if ownerUid != userUid, let lastCheckDay, !hasPosted, postDate > lastCheckDay {
                posts[i].blurred = true
            }
        }

        return posts.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
    }
    
    static func numberOfUserPosts(uid: String) async throws -> Int {
        let snapshot = try await postsCollection.whereField("ownerUid", isEqualTo: uid).getDocuments()
        let posts = try snapshot.documents.compactMap({ try $0.data(as: Post.self ) })
        return posts.count
    }
    
    static func isLastPostRecentAndAfterResetDate(uid: String) async throws -> Bool {
        let snapshot = try await postsCollection.whereField("ownerUid", isEqualTo: uid).getDocuments()
        let allPosts = try snapshot.documents.compactMap({ try $0.data(as: Post.self ) })
        let posts = allPosts.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
        
        guard let lastPost = posts.first else { return false } // Ensure there's at least one post
        
        let lastPostDate = lastPost.timestamp.dateValue()
        let calendar = Calendar.current
        // Check if past the new posting date
        let pastNewPostDate = calendar.component(.weekday, from: lastPostDate) >= postResetDate
        // Check if it's within the last 7 days
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let isRecent = lastPostDate >= oneWeekAgo
        print("posted past reset date ", pastNewPostDate, " is in recent week ", isRecent)
        return pastNewPostDate && isRecent
    }
}
