//
//  MessageVew.swift
//  weekly
//
//  Created by Cooper Senior on 12/30/24.
//

import SwiftUI
import Firebase
import Kingfisher

struct MessageVew: View {
    var message: Message
    let user: User
    
//    private var timeElapsed: String {
//        let formatter = RelativeDateTimeFormatter()
//        formatter.unitsStyle = .short
//        let date = message.timestamp.dateValue()
//        return formatter.localizedString(for: date, relativeTo: Date())
//    }
    
    var body: some View {
        if message.isFromCurrentUser() {
            HStack {
                HStack {
                    Text(message.text)
                        .padding()
                        .background(Color(uiColor: .systemBlue))
                        .cornerRadius(20)
                        .font(.subheadline)
                }
                .frame(maxWidth: 260, alignment: .trailing)
            }
            .frame(maxWidth: 360, alignment: .trailing)
        } else {
            HStack {
                CircularProfileImageView(user: user, size: .xSmall)
                HStack {
                    Text(message.text)
                        .padding()
                        .background(Color(uiColor: .systemGray5))
                        .cornerRadius(20)
                        .font(.subheadline)
                }
                .frame(maxWidth: 260, alignment: .leading)
            }
            .frame(maxWidth: 360, alignment: .leading)
        }
        // adding timestamps in 
//        Text(timeElapsed)
//            .font(.footnote)
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .padding(.leading, 10)
//            .padding(.top, 0.5)
//            .foregroundStyle(.gray)
    }
}

#Preview {
    MessageVew(message: Message(id: "123", sendingUserUid: "12345", receivingUserUid: "12315", text: "The framing better be better on this nice chat being sent", timestamp: Timestamp()), user: User.MOCK_USERS[0])
}
