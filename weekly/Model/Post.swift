//
//  Post.swift
//  weekly
//
//  Created by Cooper Senior on 12/12/24.
//

import Foundation
import Firebase

struct Post: Identifiable, Hashable, Codable {
    let id: String
    let ownerUid: String
    let caption: String?
    var likes: Int
    let imageUrl: String
    let timestamp: Timestamp
    var user: User?
    var blurred: Bool?
    var hiddenFromNonFriends: Bool?
}

extension Post {
    static var MOCK_POSTS: [Post] = [
        .init(
            id: NSUUID().uuidString,
            ownerUid: NSUUID().uuidString,
            caption: "This is a test caption",
            likes: 12,
            imageUrl: "ski1",
            timestamp: Timestamp(),
            user: User.MOCK_USERS[0]
        ),
        .init(
            id: NSUUID().uuidString,
            ownerUid: NSUUID().uuidString,
            caption: "Great day to ski",
            likes: 34,
            imageUrl: "ski2",
            timestamp: Timestamp(),
            user: User.MOCK_USERS[1]
        ),
        .init(
            id: NSUUID().uuidString,
            ownerUid: NSUUID().uuidString,
            caption: "It is a nice day out",
            likes: 46,
            imageUrl: "ski3",
            timestamp: Timestamp(),
            user: User.MOCK_USERS[2]
        ),
        .init(
            id: NSUUID().uuidString,
            ownerUid: NSUUID().uuidString,
            caption: "I am the best ",
            likes: 100,
            imageUrl: "ski4",
            timestamp: Timestamp(),
            user: User.MOCK_USERS[3]
        ),
        .init(
            id: NSUUID().uuidString,
            ownerUid: NSUUID().uuidString,
            caption: "Hah thats cool",
            likes: 69,
            imageUrl: "ski1",
            timestamp: Timestamp(),
            user: User.MOCK_USERS[4]
        )
    ]
}
