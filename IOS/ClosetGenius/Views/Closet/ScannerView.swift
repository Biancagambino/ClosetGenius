//
//  ScannerView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI
import PhotosUI
import FirebaseAuth

// MARK: - Scanner Phase

private enum ScanPhase {
    case pickPhoto      // initial state: no photo yet
    case analyzing      // Florence-2 call in progress
    case review         // labels filled in, user can edit
    case generatingDesc // Ollama call in progress
    case saving         // Firebase upload in progress
}

// MARK: - View

struct ScannerView: View {
    @ObservedObject var viewModel: ClosetViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    // Phase tracking
    @State private var phase: ScanPhase = .pickPhoto
    @State private var aiError: String? = nil
    
    // Photo
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    // Labels — pre-filled by Florence-2, editable by user
    @State private var itemName = ""
    @State private var selectedCategory = ClothingItem.ClothingCategory.tops
    @State private var selectedColor = ClothingItem.ClothingColor.black
    @State private var selectedPattern = ClothingItem.ClothingPattern.solid
    @State private var selectedSeason = ClothingItem.Season.allSeason
    @State private var selectedStyle = ClothingItem.ClothingStyle.casual
    @State private var selectedFormality = ClothingItem.Formality.casual
    @State private var itemDescription = ""
    @State private var customTags: [String] = []
    @State private var newTag = ""
    
    // Upload progress
    @State private var uploadProgress: Double = 0
    
    var body: some View {
        NavigationView {
            Group {
                switch phase {
                case .pickPhoto:
                    photoPickerPhase
                case .analyzing:
                    analyzingPhase
                case .review, .generatingDesc:
                    reviewPhase
                case .saving:
                    savingPhase
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if phase == .review || phase == .generatingDesc {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            Task { await saveItem() }
                        }
                        .disabled(itemName.isEmpty || phase == .generatingDesc)
                        .fontWeight(.semibold)
                    }
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        await runAIAnalysis(image: image)
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation Title
    
    private var navigationTitle: String {
        switch phase {
        case .pickPhoto: return "Add Item"
        case .analyzing: return "Analyzing..."
        case .review: return "Review Labels"
        case .generatingDesc: return "Writing Description..."
        case .saving: return "Saving..."
        }
    }
    
    // MARK: - Phase Views
    
    private var photoPickerPhase: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(themeManager.currentTheme.color.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Scan Your Item")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("ClosetGenius AI will automatically\ndetect category, color, season & more")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Choose Photo")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeManager.currentTheme.color)
                .cornerRadius(14)
                .padding(.horizontal, 40)
            }
            
            if let error = aiError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
    }
    
    private var analyzingPhase: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager.currentTheme.color, lineWidth: 2)
                    )
            }
            
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(themeManager.currentTheme.color)
                
                Text("ClosetGenius is analyzing your item...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("Detecting category, color, season & usage")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.7))
            }
            
            Spacer()
        }
    }
    
    private var reviewPhase: some View {
        Form {
            // Photo preview
            Section {
                if let image = selectedImage {
                    HStack {
                        Spacer()
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            
            // AI status banner
            Section {
                HStack(spacing: 10) {
                    Image(systemName: phase == .generatingDesc ? "ellipsis.circle.fill" : "checkmark.circle.fill")
                        .foregroundColor(phase == .generatingDesc ? .orange : .green)
                    
                    if phase == .generatingDesc {
                        Text("AI is writing a description...")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("AI labels applied — edit anything below")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .listRowBackground(
                (phase == .generatingDesc ? Color.orange : Color.green).opacity(0.08)
            )
            
            // Basic info
            Section(header: Text("Basic Information")) {
                TextField("Item Name", text: $itemName)
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(ClothingItem.ClothingCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue.capitalized).tag(cat)
                    }
                }
            }
            
            // Color & Pattern
            Section(header: Text("Color & Pattern")) {
                Picker("Color", selection: $selectedColor) {
                    ForEach(ClothingItem.ClothingColor.allCases, id: \.self) { color in
                        HStack {
                            Circle()
                                .fill(swiftUIColor(for: color))
                                .frame(width: 18, height: 18)
                            Text(color.displayName)
                        }
                        .tag(color)
                    }
                }
                
                Picker("Pattern", selection: $selectedPattern) {
                    ForEach(ClothingItem.ClothingPattern.allCases, id: \.self) { p in
                        Text(p.displayName).tag(p)
                    }
                }
            }
            
            // Style details
            Section(header: Text("Style Details")) {
                Picker("Season", selection: $selectedSeason) {
                    ForEach(ClothingItem.Season.allCases, id: \.self) { s in
                        Text(s.displayName).tag(s)
                    }
                }
                
                Picker("Style", selection: $selectedStyle) {
                    ForEach(ClothingItem.ClothingStyle.allCases, id: \.self) { s in
                        Text(s.displayName).tag(s)
                    }
                }
                
                Picker("Formality", selection: $selectedFormality) {
                    ForEach(ClothingItem.Formality.allCases, id: \.self) { f in
                        Text(f.displayName).tag(f)
                    }
                }
            }
            
            // AI Description
            Section(header: Text("AI Description")) {
                if phase == .generatingDesc {
                    HStack {
                        ProgressView()
                            .tint(themeManager.currentTheme.color)
                        Text("Generating description...")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                    }
                } else {
                    ZStack(alignment: .topLeading) {
                        if itemDescription.isEmpty {
                            Text("AI description will appear here...")
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $itemDescription)
                            .frame(minHeight: 80)
                    }
                    
                    Button(action: {
                        Task { await regenerateDescription() }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Regenerate Description")
                        }
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.color)
                    }
                }
            }
            
            // Custom tags
            Section(header: Text("Custom Tags")) {
                HStack {
                    TextField("Add tag", text: $newTag)
                    Button(action: {
                        if !newTag.isEmpty {
                            customTags.append(newTag.lowercased())
                            newTag = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.currentTheme.color)
                    }
                }
                
                if !customTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(customTags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .font(.caption)
                                    Button(action: { customTags.removeAll { $0 == tag } }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(themeManager.currentTheme.color.opacity(0.15))
                                .cornerRadius(15)
                            }
                        }
                    }
                }
            }
            
            // Save button (also available in toolbar)
            Section {
                Button(action: {
                    Task { await saveItem() }
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "tray.and.arrow.down.fill")
                        Text("Add to Closet")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .foregroundColor(.white)
                .listRowBackground(
                    itemName.isEmpty ? Color.gray : themeManager.currentTheme.color
                )
                .disabled(itemName.isEmpty || phase == .generatingDesc)
            }
        }
    }
    
    private var savingPhase: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView(value: uploadProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: themeManager.currentTheme.color))
                .padding(.horizontal, 40)
            
            Text("Saving to your closet...")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
    
    // MARK: - AI Pipeline
    
    private func runAIAnalysis(image: UIImage) async {
        phase = .analyzing
        aiError = nil
        
        do {
            // Step 1: Florence-2 classification
            let result = try await AIClassificationService.classify(image: image)
            
            // Map results to app enums
            selectedCategory = AIClassificationService.mapCategory(result.category)
            selectedColor = AIClassificationService.mapColor(result.color)
            selectedSeason = AIClassificationService.mapSeason(result.season)
            selectedFormality = AIClassificationService.mapFormality(result.usage)
            selectedPattern = AIClassificationService.mapPattern(result.pattern)
            
            // Auto-generate a name from category + color if blank
            if itemName.isEmpty {
                itemName = "\(selectedColor.displayName) \(selectedCategory.rawValue.capitalized)"
            }

            // Use Florence description directly
            itemDescription = result.description ?? ""

            phase = .review
            
        } catch {
            // Florence-2 server not running — fall back to manual entry
            aiError = "AI server unavailable — fill in labels manually.\n(\(error.localizedDescription))"
            phase = .review
        }
    }
    
    private func generateDescription() async {
        phase = .generatingDesc
        let tags = customTags.isEmpty ? "" : ", tags: \(customTags.joined(separator: ", "))"
        let prompt = """
        Write 2-3 sentences describing this clothing item for a style app. Be specific and helpful for outfit planning. Do not start with "This item".
        Item: \(itemName), \(selectedColor.displayName) \(selectedCategory.rawValue), \(selectedPattern.displayName) pattern, \(selectedSeason.displayName), \(selectedStyle.displayName) style, \(selectedFormality.displayName)\(tags).
        Description:
        """
        do {
            itemDescription = try await AIClassificationService.chat(message: prompt, closetItems: [])
        } catch {
            itemDescription = ""
        }
        phase = .review
    }
    
    private func regenerateDescription() async {
        await generateDescription()
    }
    
    // MARK: - Save
    
    private func saveItem() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        phase = .saving
        uploadProgress = 0
        
        var imageURL: String? = nil
        if let image = selectedImage {
            imageURL = await uploadPhoto(image: image, userId: userId)
        }
        
        let newItem = ClothingItem(
            id: UUID().uuidString,
            name: itemName,
            category: selectedCategory,
            color: selectedColor,
            pattern: selectedPattern,
            season: selectedSeason,
            style: selectedStyle,
            formality: selectedFormality,
            description: itemDescription,
            imageURL: imageURL,
            wearCount: 0,
            dateAdded: Date(),
            notes: nil,
            customTags: customTags
        )
        
        viewModel.addItem(newItem)
        dismiss()
    }
    
    private func uploadPhoto(image: UIImage, userId: String) async -> String? {
        do {
            let url = try await CloudinaryService.upload(image: image)
            return url
        } catch {
            print("Cloudinary upload error: \(error)")
            return nil
        }
    }
    
    // MARK: - Color Helper
    
    private func swiftUIColor(for color: ClothingItem.ClothingColor) -> Color {
        switch color {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .yellow: return .yellow
        case .orange: return .orange
        case .purple: return .purple
        case .pink: return .pink
        case .brown: return .brown
        case .black: return .black
        case .white: return Color.gray.opacity(0.3)
        case .gray: return .gray
        case .beige: return Color(red: 0.96, green: 0.96, blue: 0.86)
        case .navy: return Color(red: 0, green: 0, blue: 0.5)
        case .burgundy: return Color(red: 0.5, green: 0, blue: 0.13)
        case .teal: return .teal
        case .cream: return Color(red: 1, green: 0.99, blue: 0.82)
        }
    }
}
