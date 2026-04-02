//
//  DailyOutfitPromptView.swift
//  ClosetGenius
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

struct DailyOutfitPromptView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var selectedOutfit: Outfit? = nil
    @State private var caption = ""
    @State private var showingOutfitPicker = false
    @State private var isPosting = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var postImage: UIImage?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 60))
                        .foregroundColor(themeManager.currentTheme.color)
                        .symbolEffect(.bounce, options: .repeat(3))

                    Text("Time to share your outfit! ✨")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Show your friends what you're wearing today")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()

                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(themeManager.currentTheme.color)
                    Text(timeRemaining())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)

                if let outfit = selectedOutfit {
                    VStack(spacing: 12) {
                        ZStack {
                            if let img = postImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                            } else {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(themeManager.currentTheme.lightBackground)
                                    .frame(height: 200)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 36))
                                                .foregroundColor(themeManager.currentTheme.color)
                                            Text(outfit.name)
                                                .font(.headline)
                                            if !outfit.occasion.isEmpty {
                                                Text(outfit.occasion)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    )
                            }

                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Label(postImage == nil ? "Add Photo" : "Change Photo",
                                      systemImage: "camera.fill")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.45))
                                    .cornerRadius(20)
                            }
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        }
                        .frame(height: 200)
                        .onTapGesture { showingOutfitPicker = true }

                        TextField("Add a caption...", text: $caption)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let img = UIImage(data: data) {
                                postImage = img
                            }
                        }
                    }
                } else {
                    Button(action: { showingOutfitPicker = true }) {
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                            .fill(themeManager.currentTheme.color.opacity(0.3))
                            .frame(height: 180)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(themeManager.currentTheme.color)
                                    Text("Select Today's Outfit")
                                        .font(.headline)
                                        .foregroundColor(themeManager.currentTheme.color)
                                }
                            )
                    }
                    .padding(.horizontal)
                }

                Spacer()

                VStack(spacing: 15) {
                    if selectedOutfit != nil {
                        Button(action: postOutfit) {
                            HStack {
                                if isPosting {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("Post to Feed")
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isPosting ? themeManager.currentTheme.color.opacity(0.6) : themeManager.currentTheme.color)
                            .cornerRadius(14)
                        }
                        .disabled(isPosting)
                        .padding(.horizontal)
                    }

                    Button("Maybe Later") { isPresented = false }
                        .foregroundColor(.gray)
                }
                .padding(.bottom)
            }
            .navigationTitle("Daily Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { isPresented = false }
                }
            }
            .sheet(isPresented: $showingOutfitPicker) {
                SavedOutfitsPickerView(selectedOutfit: $selectedOutfit)
                    .environmentObject(themeManager)
            }
        }
    }

    private func timeRemaining() -> String {
        let calendar = Calendar.current
        let now = Date()
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
        let interval = endOfDay.timeIntervalSince(now)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "Post in the next \(hours)h \(minutes)m to appear in today's feed"
    }

    private func postOutfit() {
        guard let outfit = selectedOutfit,
              let userId = Auth.auth().currentUser?.uid else { return }
        isPosting = true

        Task {
            var uploadedURL: String? = nil
            if let img = postImage {
                uploadedURL = try? await CloudinaryService.upload(image: img)
            }

            let post = OutfitPost(
                id: UUID().uuidString,
                userID: userId,
                userName: authViewModel.currentUser?.displayName ?? "User",
                outfitID: outfit.id,
                caption: caption.trimmingCharacters(in: .whitespacesAndNewlines),
                imageURL: uploadedURL,
                datePosted: Date(),
                likes: [],
                comments: []
            )

            let db = Firestore.firestore()
            do {
                try db.collection("outfitPosts").document(post.id).setData(from: post)
            } catch { }

            await MainActor.run {
                isPosting = false
                isPresented = false
            }
        }
    }
}

// MARK: - Outfit Picker (Real Firestore)

struct SavedOutfitsPickerView: View {
    @Binding var selectedOutfit: Outfit?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    @State private var savedOutfits: [Outfit] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading outfits...")
                } else if savedOutfits.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "rectangle.3.group")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No saved outfits")
                            .font(.headline)
                        Text("Create an outfit in the Outfits tab first")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        Section(header: Text("Your Saved Outfits")) {
                            ForEach(savedOutfits) { outfit in
                                Button(action: {
                                    selectedOutfit = outfit
                                    dismiss()
                                }) {
                                    HStack(spacing: 12) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(themeManager.currentTheme.lightBackground)
                                            .frame(width: 56, height: 56)
                                            .overlay(
                                                Image(systemName: "rectangle.3.group.fill")
                                                    .foregroundColor(themeManager.currentTheme.color)
                                            )
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(outfit.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            if !outfit.occasion.isEmpty {
                                                Text(outfit.occasion)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Text("Worn \(outfit.wearCount)×")
                                                .font(.caption2)
                                                .foregroundColor(themeManager.currentTheme.color)
                                        }
                                        Spacer()
                                        if selectedOutfit?.id == outfit.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(themeManager.currentTheme.color)
                                        }
                                    }
                                }
                            }
                        }

                        Section {
                            NavigationLink(destination: OutfitBuilderView().environmentObject(themeManager)) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(themeManager.currentTheme.color)
                                    Text("Create New Outfit")
                                        .foregroundColor(themeManager.currentTheme.color)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeManager.currentTheme.color)
                }
            }
            .onAppear { loadOutfits() }
        }
    }

    private func loadOutfits() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        Firestore.firestore()
            .collection("users").document(userId).collection("outfits")
            .getDocuments { snapshot, _ in
                DispatchQueue.main.async {
                    self.savedOutfits = snapshot?.documents.compactMap {
                        try? $0.data(as: Outfit.self)
                    } ?? []
                    self.isLoading = false
                }
            }
    }
}
