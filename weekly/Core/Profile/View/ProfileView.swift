//
//  ProfileView.swift
//  weekly
//
//  Created by Cooper Senior on 12/11/24.
//

import SwiftUI

struct ProfileView: View {
    
    @State var user: User
  
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
        }
    }
}

#Preview {
    ProfileView(user: User.MOCK_USERS[0])
}
