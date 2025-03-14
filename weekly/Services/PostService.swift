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
    static let postResetDate = 6 // 6 for Friday, 2 for Monday
    
    static func fetchFeedPosts(uid: String) async throws -> [Post] {
        var hasDecodingError = false
        
        let snapshot = try await postsCollection.getDocuments()

        var posts: [Post] = snapshot.documents.compactMap { document in
            do {
                return try document.data(as: Post.self)
            } catch {
                print("Skipping document: \(document.documentID), error: \(error)")
                hasDecodingError = true // Flag for cache reset
                return nil
            }
        }

        // If missing data was found, remove that document
        if hasDecodingError {
            var posts: [Post] = []
            // Iterate over documents and attempt to decode each
            for document in snapshot.documents {
                do {
                    // Attempt to decode the document to a Post object
                    if let post = try? document.data(as: Post.self) {
                        posts.append(post)  // Add valid post to the array
                    } else {
                        // If decoding fails, delete the problematic document from Firestore
                        print("Skipping and deleting document: \(document.documentID), decoding failed")

                        // Delete the document from Firestore
                        do {
                            try await postsCollection.document(document.documentID).delete()
                            print("Deleted problematic document: \(document.documentID)")
                        } catch {
                            print("Failed to delete document: \(document.documentID), error: \(error)")
                        }
                    }
                }
            }
        }
        // Fetch user data
        let hasPosted = try await checkHasPosted(uid: uid)
        let userPostsCount = try await numberOfUserPosts(uid: uid)
        let lastUserPostDate = await lastUserPostDate(uid: uid)
        let calendar = Calendar.current
        let today = Date()

        // Find last check day
        let lastCheckDay: Date? = {
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
            components.weekday = postResetDate
            
            guard let computedDate = calendar.date(from: components) else { return nil }
            
            // If computedDate is in the future, subtract 7 days to get the past occurrence
            if computedDate > today {
                return calendar.date(byAdding: .day, value: -7, to: computedDate)
            }
            return computedDate
        }()
        
        let lastPostConvertedToCheckDay: Date? = {
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastUserPostDate)
            components.weekday = postResetDate
            
            guard let computedDate = calendar.date(from: components) else { return nil }
            //print("computedDate ", computedDate)
            // If computedDate is in the future, subtract 7 days to get the past occurrence
            if lastUserPostDate > computedDate {
                return calendar.date(byAdding: .day, value: 7, to: computedDate)
            }
            return computedDate
        }()
        
        
//        print(lastCheckDay)
//        print(lastUserPostDate)
//        print("CHECK THIS ", lastPostConvertedToCheckDay)
//        
        for i in 0 ..< posts.count {
            let post = posts[i]
            let ownerUid = post.ownerUid
            let postUser = try await UserService.fetchUser(withUid: ownerUid)
            posts[i].user = postUser

            let postDate = post.timestamp.dateValue()
            
            // Default: don't blur the post
            posts[i].blurred = false

            // If the user has no posts, blur everything // probably unessesary this is already done in checkhasPosted
            if userPostsCount < 1 {
                posts[i].blurred = true
            }
            // If the user hasn't posted since reset, blur new posts
            //print("HERE NEW!!! postDate:", postDate, "lastCheckDay:", lastCheckDay ?? "nil", "Comparison:", postDate > (lastCheckDay ?? Date.distantPast))
            if ownerUid != uid{
                if !hasPosted {
                    if let lastCheckDay, postDate > lastCheckDay {
                        print("blurred")
                        posts[i].blurred = true
                    } else if let lastPostConvertedToCheckDay, postDate > lastPostConvertedToCheckDay {
                        print("blurred")
                        posts[i].blurred = true
                    }
                    // blur all new posts that are after the lastuserpostdate
                }
            }
        }
        return posts.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
    }
    
    static func fetchUserPosts(uid: String) async throws -> [Post] {
        let snapshot = try await postsCollection.whereField("ownerUid", isEqualTo: uid).getDocuments()
        var posts = try snapshot.documents.compactMap({ try $0.data(as: Post.self) })
        guard let userUid = Auth.auth().currentUser?.uid else { return posts }
        // Fetch user's posting history
        let hasPosted = try await PostService.checkHasPosted(uid: userUid)

        let userPostsCount = try await numberOfUserPosts(uid: userUid)
        let lastUserPostDate = await lastUserPostDate(uid: userUid)

        let calendar = Calendar.current
        let today = Date()

        // Find last check day
        let lastCheckDay: Date? = {
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
            components.weekday = postResetDate
            
            guard let computedDate = calendar.date(from: components) else { return nil }
            
            // If computedDate is in the future, subtract 7 days to get the past occurrence
            if computedDate > today {
                return calendar.date(byAdding: .day, value: -7, to: computedDate)
            }
            return computedDate
        }()

        let lastPostConvertedToCheckDay: Date? = {
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastUserPostDate)
            components.weekday = postResetDate
            
            guard let computedDate = calendar.date(from: components) else { return nil }
            //print("computedDate ", computedDate)
            // If computedDate is in the future, subtract 7 days to get the past occurrence
            if lastUserPostDate > computedDate {
                return calendar.date(byAdding: .day, value: 7, to: computedDate)
            }
            return computedDate
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
            if ownerUid != userUid{
                if !hasPosted {
                    if let lastCheckDay, postDate > lastCheckDay {
                        print("blurred")
                        posts[i].blurred = true
                    } else if let lastPostConvertedToCheckDay, postDate > lastPostConvertedToCheckDay {
                        print("blurred")
                        posts[i].blurred = true
                    }
                    // blur all new posts that are after the lastuserpostdate
                }
            }
        }

        return posts.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
    }
    
    static func numberOfUserPosts(uid: String) async throws -> Int {
        let snapshot = try await postsCollection.whereField("ownerUid", isEqualTo: uid).getDocuments()
        let posts = try snapshot.documents.compactMap({ try $0.data(as: Post.self ) })
        return posts.count
    }
    
    static func lastUserPostDate(uid: String) async -> Date {
        let snapshot = try? await postsCollection.whereField("ownerUid", isEqualTo: uid).getDocuments()
        let allPosts = snapshot?.documents.compactMap { try? $0.data(as: Post.self) } ?? []
        
        let lastPostDate = allPosts.max(by: { $0.timestamp.dateValue() < $1.timestamp.dateValue() })?.timestamp.dateValue()
        
        // Return last post date if found, otherwise return a very old default date
        return lastPostDate ?? Date(timeIntervalSince1970: 0) // January 1, 1970
    }
    
    static func checkHasPosted(uid: String) async throws -> Bool {
        let snapshot = try await postsCollection.whereField("ownerUid", isEqualTo: uid).getDocuments()
        let allPosts = try snapshot.documents.compactMap({ try $0.data(as: Post.self ) })
        let posts = allPosts.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
        
        guard let lastPost = posts.first else {
            print("No posts found for user \(uid). Returning false.")
            return false
            // not posted if they don't have any posts
        }
        // post is after or = to the reset date
        
        
        let lastPostDate = lastPost.timestamp.dateValue()
        let calendar = Calendar.current
        let lastPostWeekday = calendar.component(.weekday, from: lastPostDate)
        let lastResetDate = getLastPostResetDate()

        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: lastResetDate)!
        // date of last reset

        // Check if today is past the reset date
        let pastResetDate = isPastPostResetDate()

//        print("Last post date: \(lastPostDate)")
//        print("Last post weekday: \(lastPostWeekday) (1 = Sunday, 7 = Saturday)")
//        print("Post reset day: \(postResetDate)")
//        print("Is today past reset date?: \(pastResetDate)")
//        print("Was the last post made in the last 7 days?: \(lastPostDate >= oneWeekAgo)")

        if pastResetDate {
            // Check if the last post was **after or on** the reset date AND within the last 7 days
            let hasPostedAfterReset = lastPostWeekday >= postResetDate
//            print("Has user posted after reset date?: \(hasPostedAfterReset)")
//            print("-----")
//            print(lastPostDate)
//            print(lastResetDate)
//            print("-----")
//            print("OUTPUT lastPostDate >= lastResetDate ", lastPostDate >= lastResetDate)
            return hasPostedAfterReset && lastPostDate >= lastResetDate
        } else {
            // If today is **before** the reset date, just check if the last post was recent
            //print("Else case - Last post is within the last week: \(lastPostDate >= oneWeekAgo)")
            return lastPostDate >= oneWeekAgo
        }
        // if past
            // check new last post is also past it
        // else
            // make sure recent post is within a week old

    }
    
    static func getLastPostResetDate() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)

//        print("Today’s weekday: \(currentWeekday) (1 = Sunday, 7 = Saturday)")
//        print("Post reset weekday: \(postResetDate)")

        // Find the most recent reset date before today
        var daysToSubtract = currentWeekday - postResetDate

        if daysToSubtract < 0 {
            // If today is BEFORE the reset day, go back an extra week
            daysToSubtract += 7
        }

        // Get the reset date without time components
        let lastResetDateRaw = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!
        let lastResetDate = calendar.startOfDay(for: lastResetDateRaw) // Ensures time is set to 00:00:00

        //print("Last post reset date (midnight): \(lastResetDate)")

        return lastResetDate
    }
    
    static func isPastPostResetDate() -> Bool {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Calculate the postResetDate (assuming it's a fixed weekday, for example, Monday = 2)
        let postResetDate = postResetDate // Replace this with your actual postResetDate value, which could be a fixed weekday (e.g., Monday = 2)
        
        // Get today's date and the date for postResetDate
        let components = calendar.dateComponents([.year, .month, .day], from: currentDate)
        
        // Find the date of the postResetDate this week
        var resetDate = calendar.date(from: components) ?? currentDate
        while calendar.component(.weekday, from: resetDate) != postResetDate {
            resetDate = calendar.date(byAdding: .day, value: 1, to: resetDate) ?? currentDate
        }
        
        // Check if today is past the postResetDate or within 7 days after
        if currentDate > resetDate && currentDate <= calendar.date(byAdding: .day, value: 7, to: resetDate)! {
            return true
        }
        
        return currentDate >= resetDate
    }
    
    static func getPostResetDateAsDay() -> String {
        let calendar = Calendar.current
        let weekdaySymbols = calendar.weekdaySymbols // ["Sunday", "Monday", ..., "Saturday"]
        
        // Ensure postResetDate is a valid index (1 = Sunday, 7 = Saturday)
        guard postResetDate >= 1 && postResetDate <= 7 else { return "Invalid day" }
        
        return weekdaySymbols[postResetDate - 1] // Convert 1-based index to 0-based array index
    }
    
    static func timeSincePostReset() -> String {
        let now = Date()
        // Ensure postResetDate is valid (1 = Sunday, ..., 7 = Saturday)
        let resetDate = getLastPostResetDate()

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        //print("time since last post reset: ", formatter.localizedString(for: resetDate, relativeTo: now))
        return formatter.localizedString(for: resetDate, relativeTo: now)
    }
    
    static func fetchPostById(postId: String) async throws -> Post? {
        guard let userUid = Auth.auth().currentUser?.uid else { return nil }
        // Run both asynchronous calls concurrently
        async let friends = UserService.fetchAllFriends(withUid: userUid)
        async let posts = fetchFeedPosts(uid: userUid)
        
        // Wait for results
        let (friendsList, allPosts) = try await (friends, posts)
        
        // Iterate through the posts and check if any post matches the provided postId
        for index in 0..<allPosts.count {
            var post = allPosts[index]  // Make post mutable
            
            // Check if the current post matches the provided postId
            if post.id == postId {
                // Check if the current user is friends with the post's owner, or the post owner is the current user
                post.hiddenFromNonFriends = !(post.ownerUid == userUid || friendsList.contains(where: { $0.id == post.ownerUid }))
                return post
            }
        }
        
        return nil
    }
}
