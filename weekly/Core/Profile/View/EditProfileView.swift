//
//  EditProfileView.swift
//  weekly
//
//  Created by Cooper Senior on 12/13/24.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: EditProfileViewModel
    @Binding var user: User
    @State private var isLoading = false
    
    init(user: Binding<User>) {
        self._viewModel = StateObject(wrappedValue: EditProfileViewModel(user: user.wrappedValue))
        self._user = user // Initialize the Binding
    }
    
    var body: some View {
        VStack {
            // toolbar
            VStack {
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Text("Edit Profile")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button {
                        isLoading = true
                        Task {
                            try await viewModel.updateUserData()
                            user.fullname = viewModel.fullname // Update fullname
                            user.bio = viewModel.bio // Update bio
                            if let url = viewModel.profileImageURl {
                                user.profileImageUrl = url
                                }
                            }
                            isLoading = false
                            dismiss()
                    } label: {
                        if isLoading {
                            ProgressView() // Display spinner inside button
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Done")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
            }
            
            // edit profile pic
            PhotosPicker(selection: $viewModel.selectedImage) {
                VStack {
                        if let image = viewModel.profileImage {
                            image
                                .resizable()
                                .scaledToFill()
                                .foregroundStyle(.gray)
                                .clipShape(Circle())
                                .frame(width: 80, height: 80)
                        } else {
                            CircularProfileImageView(user: viewModel.user, size: .large)
                        }
                    
                    Text("Edit profile picture")
                        .font(.footnote)
                        .fontWeight(.semibold)
                    
                    Divider()
                }
            }
            .padding(.vertical, 8)
            
            // edit profile info
            
            VStack {
                EditProfileRowView(title: "Name", placeholder: "Enter your name..", text: $viewModel.fullname)
                
                EditProfileRowView(title: "Bio", placeholder: "Enter your bio..", text: $viewModel.bio)

            }
            
            Spacer()
            
        }
    }
}

struct EditProfileRowView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        
        HStack {
            Text(title)
                .padding(.leading, 8)
                .frame(width: 100, alignment: .leading)
            
            VStack {
                TextField(placeholder, text: $text)
                
                Divider()
            }
        }
        .font(.subheadline)
        .frame(height: 36)
    }
}

//#Preview {
//    EditProfileView(user: User.MOCK_USERS[0])
//}
