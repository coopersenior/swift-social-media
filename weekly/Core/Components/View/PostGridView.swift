//
//  PostGridview.swift
//  weekly
//
//  Created by Cooper Senior on 12/12/24.
//

import SwiftUI
import Kingfisher

struct PostGridView: View {
    @ObservedObject var viewModel: PostGridViewModel
    @StateObject var friendsViewModel = AddOrSearchViewModel()
    @State private var showMessage = false
    
    let user: User
    
    init(user: User) {
        self.user = user
        self.viewModel = PostGridViewModel(user: user)
    }
    
    private let gridItems: [GridItem] = [
        .init(.flexible(), spacing: 1),
        .init(.flexible(), spacing: 1),
        .init(.flexible(), spacing: 1)
    ]
    
    private let imageDimension: CGFloat = (UIScreen.main.bounds.width - 2) / 3
    
    var body: some View {
        // if they are friends they can see this, otherwise render text ("Must be firends to view posts")
        if (friendsViewModel.isFriend(userId: user.id)) {
            LazyVGrid(columns: gridItems, spacing: 1) {
                ForEach(viewModel.posts) { post in
                    NavigationLink(destination: FeedCell(post: post, userProfileView: true)) {
                        KFImage(URL(string: post.imageUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(width: imageDimension, height: imageDimension)
                            .blur(radius: (post.blurred ?? false) ? 15 : 0)
                            .clipped()
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("")
            .onDisappear {
                viewModel.stopListening()  // Stop listening to posts when the view disappears
            }
            .onAppear() {
                viewModel.listenToUserPosts()
            }
        } else {
            VStack {
                if showMessage {
                    Text("Must be friends to view posts")
                        .fontWeight(.semibold)
                        .font(.footnote)
                        .padding()
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showMessage = true
                }
            }
        }
    }
}

#Preview {
    PostGridView(user: User.MOCK_USERS[0])
}
