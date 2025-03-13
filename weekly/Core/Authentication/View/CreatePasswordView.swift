//
//  CreatePasswordView.swift
//  weekly
//
//  Created by Cooper Senior on 12/11/24.
//

import SwiftUI

struct CreatePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: RegistrationViewModel
    
    var isPasswordValid: Bool {
        return viewModel.password.count >= 6
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Create password")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Your password must be at least 6 characters in length.")
                .font(.footnote)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            SecureField("password", text: $viewModel.password)
                .autocapitalization(.none)
                .modifier(TextFieldModifier())
                .padding(.top)
            
            if !isPasswordValid && !viewModel.password.isEmpty {
                Text("Password must be at least 6 characters long.")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
            
            NavigationLink {
                if isPasswordValid {
                    CompleteSignUpView()
                        .navigationBarBackButtonHidden()
                }
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
            .disabled(!isPasswordValid)
            
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Image(systemName: "chevron.left")
                    .imageScale(.large)
                    .onTapGesture {
                        viewModel.password = ""
                        dismiss()
                    }
            }
        }
    }
}

#Preview {
    CreatePasswordView()
}
