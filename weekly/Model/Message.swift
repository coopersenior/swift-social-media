//
//  Message.swift
//  weekly
//
//  Created by Cooper Senior on 12/30/24.
//

import Foundation
import Firebase
import FirebaseAuth

struct Message: Decodable, Identifiable, Encodable {
    let id: String
    let sendingUserUid: String
    let receivingUserUid: String
    let text: String
    let timestamp: Timestamp
    var isRead: Bool = false
    
    func isFromCurrentUser() -> Bool {
        guard let currUser = Auth.auth().currentUser else {
            return false
        }
        
        if currUser.uid == sendingUserUid {
            return true
        } else {
            return false
        }
    }
}
