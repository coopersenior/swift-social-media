//
//  ChatViewModel.swift
//  weekly
//
//  Created by Cooper Senior on 12/31/24.
//

import Foundation
import FirebaseAuth
import Firebase

class ChatViewModel: ObservableObject {
    
    @Published var messages = [Message]()
    
    @Published var mockData = [
        Message(id: "123", sendingUserUid: "12345", receivingUserUid: "134", text: "Hello this is a message from me", timestamp: Timestamp()),
        Message(id: "123", sendingUserUid: "12345", receivingUserUid: "134", text: "Hello this is a message from me", timestamp: Timestamp()),
        Message(id: "123", sendingUserUid: "12345", receivingUserUid: "134", text: "Hello this is a message from me", timestamp: Timestamp()),
        Message(id: "123", sendingUserUid: "12345", receivingUserUid: "134", text: "Hello this is a message from me", timestamp: Timestamp()),
        Message(id: "123", sendingUserUid: "12345", receivingUserUid: "134", text: "Hello this is a message from me", timestamp: Timestamp()),
        Message(id: "123", sendingUserUid: "12345", receivingUserUid: "134", text: "Hello this is a message from me", timestamp: Timestamp())
    ]
}
