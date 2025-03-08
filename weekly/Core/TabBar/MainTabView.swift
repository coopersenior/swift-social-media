//
//  MainTabView.swift
//  weekly
//
//  Created by Cooper Senior on 12/11/24.
//

import SwiftUI

struct MainTabView: View {
    let user: User
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedIndex = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            FeedView()
                .onAppear {
                    selectedIndex = 0
                }
                .tabItem {
                    Image(systemName: "house")
                }.tag(0)
            
//            SearchView()
//                .onAppear {
//                    selectedIndex = 1
//                }
//                .tabItem {
//                    Image(systemName: "magnifyingglass")
//                }.tag(1)
            
            UploadPostView(tabIndex: $selectedIndex)
                .onAppear {
                    selectedIndex = 1
                }
                .tabItem {
                    Image(systemName: "plus.app")
                }.tag(1)
            
//            Text("Notifications")
//                .onAppear {
//                    selectedIndex = 3
//                }
//                .tabItem {
//                    Image(systemName: "heart")
//                }.tag(3)
            
            CurrentUserProfileView(user: user)
                .onAppear {
                    selectedIndex = 2
                }
                .tabItem {
                    Image(systemName: "person.fill")
                }.tag(2)
        }
        .tint(colorScheme == .dark ? .white : .black)
        .imageScale(.large)
        .opacity(opacity) // Use the state for opacity
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                opacity = 1.0
            }
        }
    }
}

// TODO: change where these icons are 

#Preview {
    MainTabView(user: User.MOCK_USERS[0])
}
