//
//  ProfileSettingsView.swift
//  Weekly
//
//  Created by Cooper Senior on 2/7/25.
//

import Foundation
import SwiftUI

struct ProfileSettingsView: View {
    
    var body: some View {
        NavigationStack {
            
            Spacer()
            
            Button {
                AuthService.shared.signOut()
            } label : {
                Text("Sign Out")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
            .padding()
        }
        .navigationTitle("Settings")
    }
}
