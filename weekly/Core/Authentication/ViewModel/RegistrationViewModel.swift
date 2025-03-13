//
//  RegistrationViewModel.swift
//  weekly
//
//  Created by Cooper Senior on 12/13/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class RegistrationViewModel: ObservableObject {
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    
    @MainActor
    func createUser() async throws {
        do {
            try await AuthService.shared.createUser(email: email, password: password, username: username)
            username = ""
            email = ""
            password = ""
        }  catch {
            throw error
        }
    }
    
    func checkIfUsernameValid(from text: String) async throws -> Bool {
        let db = Firestore.firestore()
        let usersRef = db.collection("users")
        
        let querySnapshot = try await usersRef.getDocuments()
        for document in querySnapshot.documents {
            if let username = document.data()["username"] as? String, username == text {
                return false
            }
        }
        return true
    }
     
    func sendPasswordResetEmail(to email: String, completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error)) 
            } else {
                completion(.success("Password reset email sent successfully to \(email)."))
            }
        }
    }
}
