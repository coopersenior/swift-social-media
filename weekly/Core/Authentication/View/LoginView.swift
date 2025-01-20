//
//  LoginView.swift
//  weekly
//
//  Created by Cooper Senior on 12/11/24.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @StateObject var viewModel = LoginViewModel()
    @State private var incorrectLoginDetails = false
    
    var body: some View {
        NavigationStack {
            VStack {
                
                Spacer()
                
                // logo image
                Image("instagram")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 100)
                // text fields
                
                VStack {
                    TextField("Enter your email", text: $viewModel.email)
                        .autocapitalization(.none)
                        .modifier(TextFieldModifier())
                    
                    SecureField("Enter your password", text: $viewModel.password)
                        .modifier(TextFieldModifier())
                }
                
                if incorrectLoginDetails {
                    Text("Email or password is incorrect!")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                }
                
                NavigationLink {
                    ForgotPasswordView()
                        .navigationBarBackButtonHidden()
                } label: {
                    Text("Forgot Password?")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .padding(.top)
                        .padding(.trailing, 28)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                Button {
                    Task {
                        do {
                            // Attempt to sign in
                            try await viewModel.signIn()
                        } catch {
                            incorrectLoginDetails = true
                        }
                    }
                } label: {
                    Text("Login")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 360, height: 44)
                        .background(Color(.systemBlue))
                        .cornerRadius(8)
                }
                .padding(.vertical)
                
                Spacer()
                
                Divider()
                
                NavigationLink {
                    AddEmailView()
                        .navigationBarBackButtonHidden()
                } label: {
                    HStack(spacing: 3) {
                        Text("Don't have an account? ") +
                        
                        Text("Sign Up")
                            .fontWeight(.semibold)
                    }
                    .font(.footnote)
                }
                .padding(.vertical, 16)
            }
        }
        .onAppear() {
            incorrectLoginDetails = false
        }
    }
}

#Preview {
    LoginView()
}
