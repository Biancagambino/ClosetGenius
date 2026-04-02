//
//  ProfileView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var imageManager = ProfileImageManager()
    @State private var showingThemePicker = false
    @State private var showingImagePicker = false
    @State private var showingSettings = false
    @State private var showingPrivacy = false
    @State private var showingHelp = false
    @State private var showEditName = false
    @State private var editedName = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var uploadError: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            List {
                // Profile header
                Section {
                    HStack(spacing: 14) {
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
                            Button {
                                editedName = authViewModel.currentUser?.displayName ?? ""
                                showEditName = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(authViewModel.currentUser?.displayName ?? "User")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Image(systemName: "pencil")
                                        .font(.caption)
                                        .foregroundColor(themeManager.currentTheme.color)
                                }
                            }

                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            if imageManager.isUploading {
                                ProgressView(value: imageManager.uploadProgress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: themeManager.currentTheme.color))
                            }
                        }
                        .padding(.leading, 4)
                    }
                    .padding(.vertical, 8)
                }

                // Closet stats
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

                // Sustainability impact
                Section(header: Text("Sustainability Impact")) {
                    HStack {
                        Image(systemName: "leaf.fill").foregroundColor(.green)
                        Text("Items Reworn")
                        Spacer()
                        Text("\(authViewModel.currentUser?.itemsReworn ?? 0)").foregroundColor(.gray)
                    }
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(.blue)
                        Text("Trades Made")
                        Spacer()
                        Text("\(authViewModel.currentUser?.tradesMade ?? 0)").foregroundColor(.gray)
                    }
                    HStack {
                        Image(systemName: "cart.fill").foregroundColor(.orange)
                        Text("New Items Purchased")
                        Spacer()
                        Text("\(authViewModel.currentUser?.newItemsPurchased ?? 0)").foregroundColor(.gray)
                    }

                    if let user = authViewModel.currentUser, (user.itemsReworn + user.tradesMade) > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Impact").font(.caption).foregroundColor(.gray)
                            let sustainableActions = user.itemsReworn + user.tradesMade
                            let totalActions = sustainableActions + user.newItemsPurchased
                            let percentage = totalActions > 0 ? (Double(sustainableActions) / Double(totalActions) * 100) : 0
                            HStack {
                                ProgressView(value: Double(sustainableActions), total: Double(totalActions))
                                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                Text("\(Int(percentage))%").font(.caption).foregroundColor(.green).fontWeight(.bold)
                            }
                            Text("sustainable fashion choices").font(.caption2).foregroundColor(.gray)
                        }
                    }
                }

                // Appearance
                Section(header: Text("Appearance")) {
                    Button(action: { showingThemePicker = true }) {
                        HStack {
                            Text("Theme Color")
                            Spacer()
                            Circle().fill(themeManager.currentTheme.color).frame(width: 24, height: 24)
                            Text(themeManager.currentTheme.rawValue).foregroundColor(.gray)
                        }
                    }
                    .foregroundColor(.primary)
                }

                // Account
                Section(header: Text("Account")) {
                    Button(action: { showingSettings = true }) {
                        Label("Settings", systemImage: "gearshape")
                            .foregroundColor(.primary)
                    }
                    Button(action: { showingPrivacy = true }) {
                        Label("Privacy", systemImage: "lock.shield")
                            .foregroundColor(.primary)
                    }
                    Button(action: { showingHelp = true }) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                            .foregroundColor(.primary)
                    }
                }

                // Danger zone
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
            .onAppear { authViewModel.refreshUserData() }
            .sheet(isPresented: $showingThemePicker) { ThemePickerView() }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingPrivacy) { PrivacyView() }
            .sheet(isPresented: $showingHelp) { HelpSupportView() }
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
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditName) {
                EditNameSheet(initialName: editedName) { newName in
                    authViewModel.updateDisplayName(newName)
                }
                .environmentObject(themeManager)
            }
            .alert("Upload Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(uploadError ?? "Unknown error")
            }
        }
    }
}

// MARK: - Edit Name Sheet

struct EditNameSheet: View {
    let initialName: String
    let onSave: (String) -> Void

    @State private var name: String = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @FocusState private var focused: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Display Name")) {
                    TextField("Your name", text: $name)
                        .focused($focused)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeManager.currentTheme.color)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.color)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.height(200)])
        .onAppear {
            name = initialName
            focused = true
        }
    }
}

// MARK: - Theme Picker

struct ThemePickerView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button(action: { themeManager.currentTheme = theme; dismiss() }) {
                        HStack {
                            Circle().fill(theme.color).frame(width: 40, height: 40)
                            Text(theme.rawValue).font(.headline).foregroundColor(.primary)
                            Spacer()
                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark").foregroundColor(theme.color).fontWeight(.bold)
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
                    Button("Done") { dismiss() }.foregroundColor(themeManager.currentTheme.color)
                }
            }
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = true
    @AppStorage("outfitSuggestionsEnabled") private var outfitSuggestionsEnabled = true
    @State private var showTradingHistory = false
    @State private var colabURL = AIClassificationService.baseURL
    @State private var colabConnected: Bool? = nil
    @State private var isPinging = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Appearance")) {
                    Toggle(isOn: $darkModeEnabled) {
                        Label("Dark Mode", systemImage: "moon.fill")
                    }
                    .tint(themeManager.currentTheme.color)
                }

                Section(header: Text("Notifications")) {
                    Toggle(isOn: $dailyReminderEnabled) {
                        Label("Daily Outfit Reminder", systemImage: "bell.fill")
                    }
                    .tint(themeManager.currentTheme.color)
                    .onChange(of: dailyReminderEnabled) { _, newValue in
                        NotificationManager.shared.scheduleDailyOutfitReminder(enabled: newValue)
                    }

                    Toggle(isOn: $outfitSuggestionsEnabled) {
                        Label("AI Outfit Suggestions", systemImage: "sparkles")
                    }
                    .tint(themeManager.currentTheme.color)
                    .onChange(of: outfitSuggestionsEnabled) { _, newValue in
                        NotificationManager.shared.scheduleAISuggestionNotification(enabled: newValue)
                    }
                }

                Section(header: Text("Activity")) {
                    Button {
                        showTradingHistory = true
                    } label: {
                        Label("Trading History", systemImage: "arrow.triangle.2.circlepath")
                            .foregroundColor(.primary)
                    }
                }

                Section(header: Text("AI Server"), footer: Text("Paste your ngrok URL here every time you restart Colab.")) {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .foregroundColor(themeManager.currentTheme.color)
                        TextField("https://your-ngrok-url.ngrok-free.app", text: $colabURL)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                            .font(.caption)
                            .onSubmit { saveColabURL() }
                    }

                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(themeManager.currentTheme.color)
                        Text("Colab Status")
                        Spacer()
                        if isPinging {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Circle()
                                .fill(colabConnected == nil ? Color.gray : colabConnected! ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(colabConnected == nil ? "Unknown" : colabConnected! ? "Connected" : "Offline")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Button("Test") { pingColab() }
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.color)
                    }

                    Button("Save URL") { saveColabURL() }
                        .foregroundColor(themeManager.currentTheme.color)
                        .font(.subheadline)
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(.gray)
                    }
                    HStack {
                        Text("Built with")
                        Spacer()
                        Text("Florence-2 + Llama 3").foregroundColor(.gray).font(.caption)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(themeManager.currentTheme.color)
                }
            }
            .onAppear {
                NotificationManager.shared.scheduleDailyOutfitReminder(enabled: dailyReminderEnabled)
                NotificationManager.shared.scheduleAISuggestionNotification(enabled: outfitSuggestionsEnabled)
            }
            .sheet(isPresented: $showTradingHistory) {
                TradingHistoryView()
                    .environmentObject(themeManager)
                    .environmentObject(authViewModel)
            }
            .onAppear { colabURL = AIClassificationService.baseURL }
        }
    }

    private func saveColabURL() {
        let trimmed = colabURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        AIClassificationService.baseURL = trimmed
        pingColab()
    }

    private func pingColab() {
        isPinging = true
        colabConnected = nil
        Task {
            let result = await AIClassificationService.ping()
            await MainActor.run {
                colabConnected = result
                isPinging = false
            }
        }
    }
}

struct TradingHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var myListings: [TradeListing] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading history...")
                } else if myListings.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No trading history yet")
                            .font(.headline)
                        Text("Your listings and trades will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(myListings) { listing in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(listing.description)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                Spacer()
                                Text(listing.tradeType.displayName)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(themeManager.currentTheme.color)
                                    .cornerRadius(6)
                            }
                            HStack {
                                Text(listing.condition.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if let price = listing.price {
                                    Text("$\(String(format: "%.0f", price))")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                            }
                            Text(listing.datePosted.formatted(.dateTime.month().day().year()))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Trading History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(themeManager.currentTheme.color)
                }
            }
            .onAppear { loadHistory() }
        }
    }

    private func loadHistory() {
        guard let userId = authViewModel.currentUser?.id else { isLoading = false; return }
        let db = Firestore.firestore()
        db.collection("tradeListings")
            .whereField("ownerID", isEqualTo: userId)
            .getDocuments { snapshot, _ in
                DispatchQueue.main.async {
                    self.myListings = snapshot?.documents.compactMap {
                        try? $0.data(as: TradeListing.self)
                    } ?? []
                    self.isLoading = false
                }
            }
    }
}

// MARK: - Privacy

struct PrivacyView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("hideFromSearch") private var hideFromSearch = false
    @AppStorage("showWearCount") private var showWearCount = true
    @State private var showBlockedUsers = false

    var visibilityOptions: [(String, String, String)] = [
        ("Public",       "Everyone can see your closet and posts",       "globe"),
        ("Friends Only", "Only your friends can see your closet",        "person.2.fill"),
        ("Private",      "Only you can see your closet",                 "lock.fill"),
    ]

    var currentVisibility: String {
        authViewModel.currentUser?.closetVisibility ?? "public"
    }

    var body: some View {
        NavigationView {
            List {
                Section(
                    header: Text("Closet Visibility"),
                    footer: Text("Controls who can see your clothing items and outfits.")
                ) {
                    ForEach(visibilityOptions, id: \.0) { option in
                        Button {
                            let key = option.0 == "Friends Only" ? "friends" : option.0.lowercased()
                            authViewModel.updateClosetVisibility(key)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: option.2)
                                    .foregroundColor(themeManager.currentTheme.color)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.0)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    Text(option.1)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                let key = option.0 == "Friends Only" ? "friends" : option.0.lowercased()
                                if currentVisibility == key {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(themeManager.currentTheme.color)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section(header: Text("Discoverability")) {
                    Toggle(isOn: $hideFromSearch) {
                        Label("Hide from Search", systemImage: "magnifyingglass.circle")
                    }
                    .tint(themeManager.currentTheme.color)
                }

                Section(header: Text("What Others See")) {
                    Toggle(isOn: $showWearCount) {
                        Label("Show Wear Count on Items", systemImage: "repeat")
                    }
                    .tint(themeManager.currentTheme.color)
                }

                Section(header: Text("Blocked Users")) {
                    let blocked = authViewModel.currentUser?.blockedUserIDs ?? []
                    if blocked.isEmpty {
                        Text("No blocked users")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        Button {
                            showBlockedUsers = true
                        } label: {
                            HStack {
                                Label("Manage Blocked Users", systemImage: "hand.raised.fill")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(blocked.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section(header: Text("Data")) {
                    HStack {
                        Image(systemName: "lock.shield.fill").foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your data is secure").font(.subheadline)
                            Text("Stored in Firebase with end-to-end encryption")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(themeManager.currentTheme.color)
                }
            }
            .sheet(isPresented: $showBlockedUsers) {
                BlockedUsersView()
                    .environmentObject(authViewModel)
                    .environmentObject(themeManager)
            }
        }
    }
}

struct BlockedUsersView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var blockedNames: [String: String] = [:]

    var body: some View {
        NavigationView {
            Group {
                let blocked = authViewModel.currentUser?.blockedUserIDs ?? []
                if blocked.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "hand.raised")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No blocked users")
                            .font(.headline)
                    }
                } else {
                    List {
                        ForEach(blocked, id: \.self) { userId in
                            HStack {
                                Image(systemName: "person.crop.circle.fill.badge.minus")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text(blockedNames[userId] ?? userId)
                                    .font(.subheadline)
                                Spacer()
                                Button("Unblock") {
                                    authViewModel.unblockUser(id: userId)
                                }
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.color)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Blocked Users")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(themeManager.currentTheme.color)
                }
            }
        }
    }
}

// MARK: - Help & Support

struct HelpSupportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var expandedFAQ: String? = nil

    let faqs: [(String, String)] = [
        ("How do I scan a clothing item?",
         "Tap the camera icon in the Closet tab. Choose a photo from your library or take one. Florence-2 AI will automatically detect the category, color, season, and generate a description."),
        ("Why is my AI server not working?",
         "The AI server runs on Google Colab and needs to be restarted each session. Open your Colab notebook and run all cells. Update the ngrok URL in AIClassificationService.swift with the new URL."),
        ("How do I create an outfit?",
         "Go to the Outfits tab and tap the + button. Select items from your closet and save the combination. You can also use the Outfit Builder with smart filters."),
        ("How does trading work?",
         "Go to the Trading tab, tap + to create a listing from one of your closet items. Other users can see your listing and request a trade or purchase."),
        ("How do I change my profile picture?",
         "On the Profile tab, tap the camera icon on your profile picture and choose a photo from your library."),
        ("How do I change the app theme?",
         "Go to Profile → Theme Color and pick from the available colors."),
        ("What is Nova?",
         "Nova is your AI style assistant powered by Llama 3. Tap the sparkle button to chat with Nova about outfit ideas, styling tips, and more based on your closet."),
    ]

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Frequently Asked Questions")) {
                    ForEach(faqs, id: \.0) { faq in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedFAQ == faq.0 },
                                set: { expandedFAQ = $0 ? faq.0 : nil }
                            )
                        ) {
                            Text(faq.1)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 6)
                        } label: {
                            Text(faq.0)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }

                Section(header: Text("Contact Us")) {
                    Button {
                        if let url = URL(string: "mailto:closetgeniusai@gmail.com") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Email Support", systemImage: "envelope.fill")
                            .foregroundColor(themeManager.currentTheme.color)
                    }
                }

                Section(header: Text("Coming Soon")) {
                    HStack {
                        Image(systemName: "video.fill").foregroundColor(.purple)
                        Text("Tutorial Videos")
                        Spacer()
                        Text("Soon").font(.caption).foregroundColor(.secondary)
                    }
                    HStack {
                        Image(systemName: "book.fill").foregroundColor(.blue)
                        Text("Style Guide")
                        Spacer()
                        Text("Soon").font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(themeManager.currentTheme.color)
                }
            }
        }
    }
}
