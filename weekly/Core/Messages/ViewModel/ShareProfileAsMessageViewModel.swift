//
//  ShareProfileAsMessageViewModel.swift
//  Weekly
//
//  Created by Cooper Senior on 1/24/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class ShareProfileAsMessageViewModel: ObservableObject {
    let users = Firestore.firestore().collection("users")
    let currentUserUid = Auth.auth().currentUser!.uid // within messages a user must exist
    
    func sendMessage(profileId: String, receivingUserUid: String) {
        Task {
            let msgId = UUID()
            let fromMessage = Message(id: "\(msgId)", sendingUserUid: currentUserUid, receivingUserUid: receivingUserUid, text: "72deda80-3bfc-4496-8bc5-04e7c6d7c362", timestamp: Timestamp(), isRead: true, profileId: profileId)
            
            try users.document(currentUserUid).collection("messages").document().setData(from: fromMessage)
            
            let toMessage = Message(id: "\(msgId)", sendingUserUid: currentUserUid, receivingUserUid: receivingUserUid, text: "72deda80-3bfc-4496-8bc5-04e7c6d7c362", timestamp: Timestamp(), isRead: false, profileId: profileId)
            try users.document(receivingUserUid).collection("messages").document().setData(from: toMessage)
        }
    }
}
