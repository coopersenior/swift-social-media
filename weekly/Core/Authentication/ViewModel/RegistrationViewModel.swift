//
//  RegistrationViewModel.swift
//  weekly
//
//  Created by Cooper Senior on 12/13/24.
//

import Foundation

class RegistrationViewModel: ObservableObject {
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    
    @MainActor
    func createUser() async throws {
        try await AuthService.shared.createUser(email: email, password: password, username: username)
        
        username = ""
        email = ""
        password = ""
    }
}
