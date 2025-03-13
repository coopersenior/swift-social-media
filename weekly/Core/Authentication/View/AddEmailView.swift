//
//  AddEmailView.swift
//  weekly
//
//  Created by Cooper Senior on 12/11/24.
//

import SwiftUI

struct AddEmailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: RegistrationViewModel
    
    @State private var showError: Bool = false

    var isEmailValid: Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: viewModel.email)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Add your email")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("You'll use this email to sign into your account")
                .font(.footnote)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            TextField("Email", text: $viewModel.email)
                .autocapitalization(.none)
                .modifier(TextFieldModifier())
                .padding(.top)
            
            if !isEmailValid && !viewModel.email.isEmpty {
                Text("Please enter a valid email address")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
            
            NavigationLink {
                if isEmailValid {
                    CreateUserNameView()
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
            .disabled(!isEmailValid)
            
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Image(systemName: "chevron.left")
                    .imageScale(.large)
                    .onTapGesture {
                        viewModel.email = ""
                        dismiss()
                    }
            }
        }
    }
}

#Preview {
    AddEmailView()
}
