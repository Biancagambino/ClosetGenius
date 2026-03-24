//
//  ProfileView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var imageManager = ProfileImageManager()
    @State private var showingThemePicker = false
    @State private var showingImagePicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var uploadError: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        // Profile picture with upload button
                        ZStack(alignment: .bottomTrailing) {
                            ProfilePictureView(
                                imageURL: authViewModel.currentUser?.profileImageURL,
                                displayName: authViewModel.currentUser?.displayName ?? "User",
                                size: 80
                            )
                            
                            Button(action: { showingImagePicker = true }) {
                                Image(systemName: "camera.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(themeManager.currentTheme.color)
                                            .frame(width: 28, height: 28)
                                    )
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authViewModel.currentUser?.displayName ?? "User")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if imageManager.isUploading {
                                ProgressView(value: imageManager.uploadProgress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: themeManager.currentTheme.color))
                            }
                        }
                        .padding(.leading)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Closet Stats")) {
                    HStack {
                        Text("Total Items")
                        Spacer()
                        Text("\(authViewModel.currentUser?.closetItemCount ?? 0)")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Sustainability Score")
                        Spacer()
                        Text("\(authViewModel.currentUser?.sustainabilityScore ?? 0)")
                            .foregroundColor(.green)
                    }
                }
                
                Section(header: Text("Sustainability Impact")) {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                        Text("Items Reworn")
                        Spacer()
                        Text("\(authViewModel.currentUser?.itemsReworn ?? 0)")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.blue)
                        Text("Trades Made")
                        Spacer()
                        Text("\(authViewModel.currentUser?.tradesMade ?? 0)")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "cart.fill")
                            .foregroundColor(.orange)
                        Text("New Items Purchased")
                        Spacer()
                        Text("\(authViewModel.currentUser?.newItemsPurchased ?? 0)")
                            .foregroundColor(.gray)
                    }
                    
                    // Impact ratio
                    if let user = authViewModel.currentUser, (user.itemsReworn + user.tradesMade) > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Impact")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            let sustainableActions = user.itemsReworn + user.tradesMade
                            let totalActions = sustainableActions + user.newItemsPurchased
                            let percentage = totalActions > 0 ? (Double(sustainableActions) / Double(totalActions) * 100) : 0
                            
                            HStack {
                                ProgressView(value: Double(sustainableActions), total: Double(totalActions))
                                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                Text("\(Int(percentage))%")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .fontWeight(.bold)
                            }
                            
                            Text("sustainable fashion choices")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Appearance")) {
                    Button(action: { showingThemePicker = true }) {
                        HStack {
                            Text("Theme Color")
                            Spacer()
                            Circle()
                                .fill(themeManager.currentTheme.color)
                                .frame(width: 24, height: 24)
                            Text(themeManager.currentTheme.rawValue)
                                .foregroundColor(.gray)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section {
                    Button("Settings") {}
                    Button("Privacy") {}
                    Button("Help & Support") {}
                }
                
                Section {
                    if authViewModel.currentUser?.profileImageURL != nil {
                        Button("Remove Profile Picture") {
                            Task {
                                if let userId = authViewModel.currentUser?.id {
                                    try? await imageManager.deleteProfileImage(userId: userId)
                                    authViewModel.updateProfileImage(url: "")
                                }
                            }
                        }
                        .foregroundColor(.orange)
                    }
                    
                    Button("Sign Out") {
                        authViewModel.signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                authViewModel.refreshUserData()
            }
            .sheet(isPresented: $showingThemePicker) {
                ThemePickerView()
            }
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data),
                       let userId = authViewModel.currentUser?.id {
                        
                        do {
                            let url = try await imageManager.uploadProfileImage(image, userId: userId)
                            authViewModel.updateProfileImage(url: url)
                            authViewModel.refreshUserData()
                        } catch {
                            uploadError = "Failed to upload image: \(error.localizedDescription)"
                            showingError = true
                            print("Profile upload error: \(error)")
                        }
                    }
                }
            }
            .alert("Upload Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(uploadError ?? "Unknown error")
            }
        }
    }
}

struct ThemePickerView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button(action: {
                        themeManager.currentTheme = theme
                        dismiss()
                    }) {
                        HStack {
                            Circle()
                                .fill(theme.color)
                                .frame(width: 40, height: 40)
                            
                            Text(theme.rawValue)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.color)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Choose Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.color)
                }
            }
        }
    }
}
