//
//  SingleMessagerView.swift
//  weekly
//
//  Created by Cooper Senior on 12/18/24.
//

import SwiftUI

struct SingleChatView: View {
    @StateObject var chatViewModel = ChatViewModel()
    @StateObject private var messagesService: MessagesService
    
    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    let user: User

    @State var text = ""
    
    init(user: User) {
        self.user = user
        _messagesService = StateObject(wrappedValue: MessagesService(currentUser: user))
    }
    
    var body: some View {
        VStack {
            NavigationLink(destination: ProfileView(user: user)) {
                HStack {
                    CircularProfileImageView(user: user, size: .small)
                    VStack(alignment: .leading) {
                        if let fullname = user.fullname {
                            Text(fullname)
                                .fontWeight(.semibold)
                        }
                        Text(user.username)
                        
                    }
                    .font(.footnote)
                    Spacer()
                }
                .foregroundStyle(.black)
                .padding(.horizontal)
            }
        }
        .navigationTitle("")
        .toolbarRole(.editor)  // hides back bar title name
        .navigationBarBackButtonHidden(false)
        Divider()
        // here
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(messagesService.messages, id: \.id) { message in
                        MessageVew(message: message, user: user)
                    }
                }
                .onChange(of: messagesService.lastMessageId) { oldValue, id in
                    withAnimation {
                        proxy.scrollTo(id, anchor: .bottom)
                    }
                }
            }
        }
        // message field
        HStack {
            TextField("Message...", text: $text)
            
            Button {
                if text.count > 0 {
                    impactFeedbackGenerator.prepare()
                    impactFeedbackGenerator.impactOccurred()
                    messagesService.sendMessage(text: text, receivingUserUid: user.id)
                    text = ""
                }
            } label : {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(Color(.white))
                    .padding(10)
                    .background(Color(.systemBlue))
                    .cornerRadius(50)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(uiColor: .systemGray5))
        .cornerRadius(50)
        .padding()
        .onDisappear {
            messagesService.markMessagesAsRead()
        }
    }
}

#Preview {
    SingleChatView(user: User.MOCK_USERS[0])
}
