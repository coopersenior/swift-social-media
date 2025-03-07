//
//  UploadPostViewModel.swift
//  weekly
//
//  Created by Cooper Senior on 12/12/24.
//

import Foundation
import PhotosUI
import SwiftUI
import UIKit
import FirebaseAuth
import Firebase

enum ImageError: Error, LocalizedError {
    case aspectRatioTooTall

    var errorDescription: String? {
        switch self {
        case .aspectRatioTooTall:
            return "The selected image is too tall. Please choose an image with a 16:9 aspect ratio or wider."
        }
    }
}

@MainActor
class UploadPostViewModel: ObservableObject {
    
    @Published var selectedImage: PhotosPickerItem? {
            didSet {
                Task {
                    do {
                        try await loadImage(fromItem: selectedImage)
                    } catch {
                        DispatchQueue.main.async {
                            self.imageError = error // Capture the error
                        }
                    }
                }
            }
        }
    
    @Published var postImage: Image?
    @Published var uiImage: UIImage?
    @Published var imageError: Error?

    func loadImage(fromItem item: PhotosPickerItem?) async throws {
        guard let item = item else { return }
        
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        
        guard let uiImage = UIImage(data: data) else { return }
        
        let imageWidth = uiImage.size.width
        let imageHeight = uiImage.size.height
        let aspectRatio = imageHeight / imageWidth
        
        // Check if the image is taller than a 16:9 ratio (9/16 = 0.5625)
        if aspectRatio > (16.0 / 9.0) {
            throw ImageError.aspectRatioTooTall
        }

        self.uiImage = uiImage
        self.postImage = Image(uiImage: uiImage)
    }
    
    func uploadPost(caption: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let uiImage = uiImage else { return }
        
        let postRef = Firestore.firestore().collection("posts").document()
        guard let imageUrl = try await ImageUploader.uploadImage(image: uiImage) else { return }
        let post = Post(id: postRef.documentID, ownerUid: uid, caption: caption, likes: 0, imageUrl: imageUrl, timestamp: Timestamp())
        guard let encodedPost = try? Firestore.Encoder().encode(post) else { return }
        
        try await postRef.setData(encodedPost)
        try await AuthService().checkHasPosted()
    }
}

