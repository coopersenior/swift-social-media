//
//  SearchViewModel.swift
//  weekly
//
//  Created by Cooper Senior on 12/13/24.
//

import Foundation
import FirebaseAuth

class SearchViewModel: ObservableObject {
    @Published var users = [User]()
    
    init() {
        Task { try await fetchAllUsers() }
    }
    
    @MainActor
    func fetchAllUsers() async throws {
        self.users = try await UserService.fetchAllUsers()
        guard let uid = Auth.auth().currentUser?.uid else { return }
                
        self.users = self.users.filter { $0.id != uid }
    }
}
