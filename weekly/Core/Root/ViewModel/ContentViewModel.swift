//
//  ContentViewModel.swift
//  weekly
//
//  Created by Cooper Senior on 12/13/24.
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
class ContentViewModel: ObservableObject {
    
    private let service = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    
    init() {
        setupSubscribers()
    }
    
    @MainActor
    func setupSubscribers() {
        service.$userSession
            .receive(on: DispatchQueue.main) // Ensure updates happen on the main thread
            .sink { [weak self] userSession in
                self?.userSession = userSession
            }
            .store(in: &cancellables)
        
        service.$currentUser
            .receive(on: DispatchQueue.main) // Ensure updates happen on the main thread
            .sink { [weak self] currentUser in
                self?.currentUser = currentUser
            }
            .store(in: &cancellables)
    }
}
