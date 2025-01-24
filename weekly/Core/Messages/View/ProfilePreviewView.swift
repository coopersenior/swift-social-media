//
//  ProfilePreviewView.swift
//  Weekly
//
//  Created by Cooper Senior on 1/24/25.
//

import SwiftUI

struct ProfilePreviewView: View {
    @State private var user: User? = nil
    
    let profileId: String
    
    init(profileId: String) {
        self.profileId = profileId
    }
    
    var body: some View {
        VStack {
            if let user = user {
                HStack {
                    NavigationLink(destination: ProfileView(user: user)) {
                        CircularProfileImageView(user: user, size: .medium)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(user.username)
                            .fontWeight(.semibold)
                        if let fullname = user.fullname {
                            Text(fullname)
                        }
                    }
                    .font(.footnote)
                    .padding(.horizontal)
                    .padding(.vertical)
                }
            } else {
                Text("Failed to load user.")
            }
        }
        .onAppear {
            loadUser()
        }
    }
    
    func loadUser() {
        Task {
            do {
                let fetchedUser = try await UserService.fetchUser(withUid: profileId)
                self.user = fetchedUser
            } catch {
                print("Failed to fetch user: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ProfilePreviewView(profileId: "sampleProfileId")
}
