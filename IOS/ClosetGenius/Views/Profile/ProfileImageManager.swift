//
//  ProfileImageManager.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/15/26.
//

import SwiftUI
import Combine
import PhotosUI
import FirebaseStorage
import FirebaseAuth

@MainActor
class ProfileImageManager: ObservableObject {
    @Published var profileImage: UIImage?
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    
    func uploadProfileImage(_ image: UIImage, userId: String) async throws -> String {
        isUploading = true
        uploadProgress = 0
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            isUploading = false
            throw ProfileImageError.invalidImage
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImagesRef = storageRef.child("profile_images/\(userId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload with progress tracking
        let uploadTask = profileImagesRef.putData(imageData, metadata: metadata)
        
        uploadTask.observe(.progress) { snapshot in
            if let progress = snapshot.progress {
                Task { @MainActor in
                    self.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    print("Upload progress: \(self.uploadProgress)")
                }
            }
        }
        
        do {
            _ = await uploadTask
            
            // Get download URL
            let downloadURL = try await profileImagesRef.downloadURL()
            
            isUploading = false
            print("Upload successful: \(downloadURL.absoluteString)")
            return downloadURL.absoluteString
        } catch {
            isUploading = false
            print("Upload error: \(error)")
            throw error
        }
    }
    
    func loadProfileImage(from urlString: String?) async {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    self.profileImage = image
                }
            }
        } catch {
            print("Error loading profile image: \(error)")
        }
    }
    
    func deleteProfileImage(userId: String) async throws {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImagesRef = storageRef.child("profile_images/\(userId).jpg")
        
        try await profileImagesRef.delete()
        profileImage = nil
    }
}

enum ProfileImageError: Error {
    case invalidImage
    case uploadFailed
}

// Reusable Profile Picture View Component
struct ProfilePictureView: View {
    let imageURL: String?
    let displayName: String
    let size: CGFloat
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Group {
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure:
                        fallbackView
                    @unknown default:
                        fallbackView
                    }
                }
            } else {
                fallbackView
            }
        }
    }
    
    var fallbackView: some View {
        Circle()
            .fill(themeManager.currentTheme.color.opacity(0.2))
            .frame(width: size, height: size)
            .overlay(
                Text(String(displayName.prefix(1)).uppercased())
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.color)
            )
    }
}
