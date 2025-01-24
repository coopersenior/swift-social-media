//
//  ForgotPasswordView.swift
//  weekly
//
//  Created by Cooper Senior on 1/20/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @EnvironmentObject var viewModel: RegistrationViewModel
    @State private var isEmailSent = false
    @State private var emailSending = false
    @State private var sendFailed: String? = nil
    
    var body: some View {
        VStack(spacing: 12) {
            if isEmailSent {
                Text("Email sent sucessfully!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Check your email for a password reset link")
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            } else {
                Text("Reset your password")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("A password reset email will be sent to your inbox")
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .modifier(TextFieldModifier())
                .padding(.top)
                .disabled(isEmailSent)
                .opacity(isEmailSent ? 0.5 : 1.0)
            
            if let sendFailedMsg = sendFailed {
                Text(sendFailedMsg)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Button {
                emailSending = true
                sendFailed = nil
                if isEmailSent {
                    print("return to sign in")
                    dismiss()
                } else {
                    
                    viewModel.sendPasswordResetEmail(to: email) { result in
                        switch result {
                            case .success(let message):
                            emailSending = false
                            isEmailSent = true
                                print(message)
                            case .failure(let error):
                                emailSending = false
                                sendFailed = "Error sending password reset email: \(error.localizedDescription)"
                                print("Error sending password reset email: \(error.localizedDescription)")
                        }
                    }
                }
            } label: {
                if isEmailSent {
                    Text("Return to login")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 360, height: 44)
                        .background(Color(.systemBlue))
                        .cornerRadius(8)
                } else {
                    Text("Send email")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 360, height: 44)
                        .background(Color(.systemBlue))
                        .cornerRadius(8)
                }
            }
            .padding(.vertical)
            .disabled(emailSending)
            .opacity(emailSending ? 0.5 : 1.0)
            
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Image(systemName: "chevron.left")
                    .imageScale(.large)
                    .onTapGesture {
                        dismiss()
                    }
            }
        }
        .onAppear {
            isEmailSent = false
        }
    }
}

#Preview {
    ForgotPasswordView()
}
