//
//  CommentCircularProfileImageView.swift
//  weekly
//
//  Created by Cooper Senior on 1/21/25.
//

import SwiftUI
import Kingfisher

enum CommentProfileImageSize {
    case xSmall
    case small
    case medium
    case large
    
    var dimension: CGFloat {
        switch self {
        case .xSmall:
            return 40
        case .small:
            return 48
        case .medium:
            return 64
        case .large:
            return 80
        }
    }
}

struct CommentCircularProfileImageView: View {
    let comment: Comment
    let size: CommentProfileImageSize
    @State private var user: User?
    
    var body: some View {
        Group {
            if let imageUrl = user?.profileImageUrl {
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.dimension, height: size.dimension)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: size.dimension, height: size.dimension)
                    .clipShape(Circle())
                    .foregroundStyle(Color(.systemGray4))
            }
        }
        .task {
            // Fetch the user asynchronously when the view appears
            do {
                user = try await UserService.fetchUser(withUid: comment.commentUserId)
            } catch {
                print("Failed to fetch user: \(error.localizedDescription)")
            }
        }
    }
}

