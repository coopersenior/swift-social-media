//
//  Comment.swift
//  weekly
//
//  Created by Cooper Senior on 1/20/25.
//

import Foundation
import Firebase
import FirebaseAuth

struct Comment: Decodable, Identifiable, Encodable, Hashable {
    let id: String
    let postId: String
    let commentUserId: String
    let profileImageUrl: String?
    let commentUsername: String?
    let commentFullname: String?
    let text: String
    let timestamp: Timestamp
    
//    func isFromCurrentUser() -> Bool {
//        guard let currUser = Auth.auth().currentUser else {
//            return false
//        }
//        
//        if currUser.uid == sendingUserUid {
//            return true
//        } else {
//            return false
//        }
//    }
}
