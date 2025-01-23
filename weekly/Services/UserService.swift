//
//  UserService.swift
//  weekly
//
//  Created by Cooper Senior on 12/13/24.
//

import Foundation
import Firebase
import FirebaseAuth

struct UserService {
    
    static func fetchUser(withUid uid: String) async throws -> User {
        let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
        return try snapshot.data(as: User.self)
    }
    
    static func isNotSelf(withUid uid: String) -> Bool {
        guard let currentUserUid = Auth.auth().currentUser?.uid else { return false }
        return currentUserUid != uid
    }
    
    static func fetchAllUsers() async throws -> [User] {
        let snapshot = try await Firestore.firestore().collection("users").getDocuments()
        return snapshot.documents.compactMap({ try? $0.data(as: User.self) })
    }
    
    static func fetchAllFriends(withUid uid: String) async throws -> [User] {
        let snapshot = try await Firestore.firestore().collection("users").document(uid).collection("friends").getDocuments()
        var friends: [User] = []

           // Loop through each document to extract the friendUid and fetch user data
           for document in snapshot.documents {
               // Extract the friendUid from the document
               if let friendUid = document.data()["friendUid"] as? String {
                   // Fetch the full user data for the friendUid
                   let friend = try await UserService.fetchUser(withUid: friendUid)
                   friends.append(friend)
               }
           }
           
           return friends
    }
    
    static func fetchAllFriendRequests(userUid: String) async throws -> [User] {
        let snapshot = try await Firestore.firestore().collection("users").document(userUid).collection("requests").getDocuments()
        var users: [User] = []

        // Loop through each request document to get the requesting user's UID
        for document in snapshot.documents {
            // Extract the requestingUserUid from the document
            if let requestingUserUid = document.data()["requestingUserUid"] as? String {
                // Fetch the full user data for the requesting user
                let user = try await UserService.fetchUser(withUid: requestingUserUid)
                users.append(user)
            }
        }
        
        return users
    }
}
