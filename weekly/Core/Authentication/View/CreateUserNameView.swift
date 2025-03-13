//
//  CreateUserNameView.swift
//  weekly
//
//  Created by Cooper Senior on 12/11/24.
//

import SwiftUI

struct CreateUserNameView: View {
    @Environment(\.dismiss) var dismiss
    @State private var usernameAvailable = false
    @EnvironmentObject var viewModel: RegistrationViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Create username")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Pick a username for your new account.")
                .font(.footnote)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            TextField("username", text: $viewModel.username)
                .autocapitalization(.none)
                .modifier(TextFieldModifier())
                .padding(.top)
                .onChange(of: viewModel.username) {
                    Task {
                        do {
                            usernameAvailable = try await viewModel.checkIfUsernameValid(from: viewModel.username)
                        } catch {
                            print("Error checking username: \(error.localizedDescription)")
                            usernameAvailable = false // Assume unavailable if an error occurs
                        }
                    }
                }
            
            if !usernameAvailable && !viewModel.username.isEmpty {
                Text("Username unavailable. Please choose another.")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
            
            NavigationLink {
                CreatePasswordView()
                    .navigationBarBackButtonHidden()
            } label: {
                Text("Next")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 360, height: 44)
                    .background(Color(.systemBlue))
                    .cornerRadius(8)
            }
            .padding(.vertical)
            .disabled(viewModel.username.isEmpty || !usernameAvailable)
            // function to check if that usernanme is taken

            
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Image(systemName: "chevron.left")
                    .imageScale(.large)
                    .onTapGesture {
                        viewModel.username = ""
                        dismiss()
                    }
            }
        }
    }
}

#Preview {
    CreateUserNameView()
}
