//
//  CompleteSignUpView.swift
//  weekly
//
//  Created by Cooper Senior on 12/11/24.
//

import SwiftUI

struct CompleteSignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: RegistrationViewModel
    
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack(spacing: 12) {
            
            Spacer()
            
            Text("Welcome to Weekly, \(viewModel.username)")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
                .multilineTextAlignment(.center)
            
            Text("Click below to complete registration and start using Weekly.")
                .font(.footnote)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            // Show error if registration fails
            if showError {
                VStack {
                    Text("Failed to create account!")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                    
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
            }
            
            Button {
                Task {
                    do {
                        try await viewModel.createUser()
                    } catch {
                        DispatchQueue.main.async {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
            } label: {
                Text("Complete Sign Up")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 360, height: 44)
                    .background(Color(.systemBlue))
                    .cornerRadius(8)
            }
            .padding(.vertical)
            .disabled(showError)
            .opacity(showError ? 0.5 : 1)
            
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
    }
}

#Preview {
    CompleteSignUpView()
}
