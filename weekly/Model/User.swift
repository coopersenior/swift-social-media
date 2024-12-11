//
//  User.swift
//  weekly
//
//  Created by Cooper Senior on 12/12/24.
//

import Foundation
import FirebaseAuth

struct User: Identifiable, Hashable, Codable {
    let id: String
    var username: String
    var profileImageUrl: String?
    var fullname: String?
    var bio: String?
    let email: String
    
    var isCurrentUser: Bool {
        guard let currentUid = Auth.auth().currentUser?.uid else { return false }
        return currentUid == id
    }
}

extension User {
    static var MOCK_USERS: [User] = [
        .init(id: NSUUID().uuidString, username: "batman", profileImageUrl:
                "https://firebasestorage.googleapis.com:443/v0/b/weekly-84923.firebasestorage.app/o/profile_images%2F4BC061BE-7E42-4267-BB30-64190331B957?alt=media&token=1d8a9c49-5446-4719-abdb-26548a9e9cbc", fullname: "Bruce Wayne", bio: "Gothem's dark knight", email: "batman@gmail.com")
    ]
}
