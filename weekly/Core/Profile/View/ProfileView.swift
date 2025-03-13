//
//  ProfileView.swift
//  weekly
//
//  Created by Cooper Senior on 12/11/24.
//

import SwiftUI

struct ProfileView: View {
    
    @State var user: User
    @State private var dragOffset: CGFloat = 0
    @Environment(\.dismiss) var dismiss
  
    var body: some View {
        NavigationStack {
            ScrollView {
                // header
                ProfileHeaderView(user: $user)
                
                // post grid view
                PostGridView(user: user)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let screenWidth = UIScreen.main.bounds.width
                        if value.startLocation.x < 100 && value.translation.width > screenWidth * 0.4 {
                            withAnimation(.easeInOut) {
                                dismiss()
                            }
                        }
                    }
            )
        }
    }
}

#Preview {
    ProfileView(user: User.MOCK_USERS[0])
}
