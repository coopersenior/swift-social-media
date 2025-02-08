//
//  CurrentUserProfileView.swift
//  weekly
//
//  Created by Cooper Senior on 12/12/24.
//

import SwiftUI

struct CurrentUserProfileView: View {
    
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileSettingsView().hideTabBar()) {
                        Image(systemName: "line.3.horizontal")
                    }
                }
            }
        }
    }
}

#Preview {
    CurrentUserProfileView(user: User.MOCK_USERS[0])
}
