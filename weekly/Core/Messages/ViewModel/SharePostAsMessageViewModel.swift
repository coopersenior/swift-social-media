//
//  ShareProfileAsMessageViewModel.swift
//  Weekly
//
//  Created by Cooper Senior on 1/24/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class SharePostAsMessageViewModel: ObservableObject {
    let users = Firestore.firestore().collection("users")
    let currentUserUid = Auth.auth().currentUser!.uid // within messages a user must exist
    
    func sendPost(postId: String, receivingUserUid: String) {
        Task {
            let msgId = UUID()
            let fromMessage = Message(id: "\(msgId)", sendingUserUid: currentUserUid, receivingUserUid: receivingUserUid, text: "72deda80-3bfc-4496-8bc5-04e7c6d7c362", timestamp: Timestamp(), isRead: true, postId: postId)
            
            try users.document(currentUserUid).collection("messages").document().setData(from: fromMessage)
            
            let toMessage = Message(id: "\(msgId)", sendingUserUid: currentUserUid, receivingUserUid: receivingUserUid, text: "72deda80-3bfc-4496-8bc5-04e7c6d7c362", timestamp: Timestamp(), isRead: false, postId: postId)
            try users.document(receivingUserUid).collection("messages").document().setData(from: toMessage)
        }
    }
    
    func sendMessage(text: String, receivingUserUid: String) {
        Task {
            let msgId = UUID()
            let fromMessage = Message(id: "\(msgId)", sendingUserUid: currentUserUid, receivingUserUid: receivingUserUid, text: text, timestamp: Timestamp(), isRead: true, postId: "")
            
            try users.document(currentUserUid).collection("messages").document().setData(from: fromMessage)
            
            let toMessage = Message(id: "\(msgId)", sendingUserUid: currentUserUid, receivingUserUid: receivingUserUid, text: text, timestamp: Timestamp(), isRead: false, postId: "")
            try users.document(receivingUserUid).collection("messages").document().setData(from: toMessage)
        }
    }
}
