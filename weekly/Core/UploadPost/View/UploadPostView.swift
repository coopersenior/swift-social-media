//
//  UploadPostView.swift
//  weekly
//
//  Created by Cooper Senior on 12/12/24.
//

import SwiftUI
import PhotosUI

struct UploadPostView: View {
    @State private var caption = ""
    @State private var imagePickerPresented = false
    @StateObject var viewModel = UploadPostViewModel()
    @Binding var tabIndex: Int
    @State private var isButtonDisabled = false
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            // action toolbar
            HStack {
                Button {
                    clearPostDataAndReturnToFeed()
                } label: {
                    Text("Cancel")
                }
                
                Spacer()
                
                Text("New Post")
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    isButtonDisabled = true
                    // start loading spinner
                    isLoading = true
                    Task {
                        try await viewModel.uploadPost(caption: caption)
                        // stop loading spinner
                        isLoading = false
                        clearPostDataAndReturnToFeed()
                    }
                } label: {
                    if isLoading {
                        ProgressView() // Display spinner inside button
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding(.leading, 37)
                    } else {
                        Text("Upload")
                            .fontWeight(.semibold)
                            .opacity(isButtonDisabled ? 0.5 : 1.0)
                    }
                }
                .disabled(isButtonDisabled)

            }
            .padding(.horizontal)
            
            // post image and caption
            HStack(spacing: 8) {
                if let image = viewModel.postImage {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(7)
                }
                    
                TextField("Enter your caption...", text: $caption, axis: .vertical)
            }
            .padding()
            
            Spacer()
        }
        .onAppear {
            imagePickerPresented.toggle()
            isButtonDisabled = false
        }
        .photosPicker(isPresented: $imagePickerPresented, selection: $viewModel.selectedImage)
    }
    
    func clearPostDataAndReturnToFeed() {
        caption = ""
        viewModel.selectedImage = nil
        viewModel.postImage = nil
        tabIndex = 0
        dismiss()
    }
}

#Preview {
    UploadPostView(tabIndex: .constant(0))
}
