//
//  UploadPostView.swift
//  weekly
//
//  Created by Cooper Senior on 12/12/24.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct UploadPostView: View {
    @State private var caption = ""
    @State private var imagePickerPresented = false
    @State private var cameraPickerPresented = false
    @StateObject var viewModel = UploadPostViewModel()
    @Binding var tabIndex: Int
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    @State private var showErrorAlert = false
    
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
                            .opacity(viewModel.postImage == nil ? 0.5 : 1.0)
                    }
                }
                .disabled(viewModel.postImage == nil)
            }
            .padding(.horizontal)
            
            // post image and caption
            VStack(spacing: 8) {
                if let image = viewModel.postImage {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300, maxHeight: 200)
                        .clipped()
                        .cornerRadius(7)
                } else {
                    HStack {
                        Spacer()
                        Button {
                            imagePickerPresented.toggle()
                        } label: {
                            Image(systemName: "photo.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 65)
                        }
                        .padding()
                        
                        Spacer()
                        
                        Button {
                            cameraPickerPresented.toggle()
                        } label: {
                            Image(systemName: "camera.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 60)
                        }
                        .padding()
                        Spacer()
                    }
                }
                
                Divider()
                
                TextField("Enter your caption...", text: $caption)
                    .padding()
            }
            .padding()
            
            Spacer()
        }
        .photosPicker(isPresented: $imagePickerPresented, selection: $viewModel.selectedImage)
        .fullScreenCover(isPresented: $cameraPickerPresented) {
            CameraView(viewModel: viewModel)
        }
        .onReceive(viewModel.$imageError) { error in
            if error != nil {
                showErrorAlert = true
            }
        }
        .alert(isPresented: $showErrorAlert, content: {
            Alert(
                title: Text("Image Error"),
                message: Text(viewModel.imageError?.localizedDescription ?? "An unknown error occurred."),
                dismissButton: .default(Text("OK")) {
                    showErrorAlert = false
                    viewModel.imageError = nil // Reset error after dismissing
                }
            )
        })
    }
    
    func clearPostDataAndReturnToFeed() {
        caption = ""
        viewModel.selectedImage = nil
        viewModel.postImage = nil
        tabIndex = 0
        dismiss()
    }
}

struct CameraView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: UploadPostViewModel

    var body: some View {
        CameraCaptureView { image in
            viewModel.uiImage = image // Store raw UIImage in viewModel
            viewModel.postImage = Image(uiImage: image) // Update SwiftUI Image
            presentationMode.wrappedValue.dismiss()
        }
    }
}


#Preview {
    UploadPostView(tabIndex: .constant(0))
}
