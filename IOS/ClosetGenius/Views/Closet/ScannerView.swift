//
//  ScannerView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseAuth

// ===================================
// CLOSETGENIUS API
// ===================================

struct ClothingPrediction: Codable {
    let category: String
    let categoryConfidence: Double
    let color: String
    let colorConfidence: Double
    let season: String
    let seasonConfidence: Double
    let usage: String
    let usageConfidence: Double

    enum CodingKeys: String, CodingKey {
        case category
        case categoryConfidence = "category_confidence"
        case color
        case colorConfidence    = "color_confidence"
        case season
        case seasonConfidence   = "season_confidence"
        case usage
        case usageConfidence    = "usage_confidence"
    }
}

class ClosetGeniusAPI {
    // 🔴 Update this URL every time you restart Cell 4 in Colab
    static let baseURL = "https://heretical-unabdicated-gricelda.ngrok-free.dev"

    static func predict(image: UIImage, completion: @escaping (Result<ClothingPrediction, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/predict") else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary       = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { return }
            do {
                let prediction = try JSONDecoder().decode(ClothingPrediction.self, from: data)
                completion(.success(prediction))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// ===================================
// SCANNER VIEW
// ===================================

struct ScannerView: View {
    @ObservedObject var viewModel: ClosetViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    @State private var itemName          = ""
    @State private var selectedCategory  = ClothingItem.ClothingCategory.tops
    @State private var selectedColor     = ClothingItem.ClothingColor.black
    @State private var selectedPattern   = ClothingItem.ClothingPattern.solid
    @State private var selectedSeason    = ClothingItem.Season.allSeason
    @State private var selectedStyle     = ClothingItem.ClothingStyle.casual
    @State private var selectedFormality = ClothingItem.Formality.casual
    @State private var customTags: [String] = []
    @State private var newTag            = ""

    // Photo
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isUploading       = false
    @State private var uploadProgress: Double = 0

    // AI Scanning
    @State private var isScanning        = false
    @State private var scanComplete      = false
    @State private var scanError         = false
    @State private var confidenceScores: [String: Double] = [:]

    var body: some View {
        NavigationView {
            Form {

                // ===================================
                // PHOTO SECTION
                // ===================================
                Section(header: Text("Photo")) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                Button(action: {
                                    selectedImage  = nil
                                    selectedPhoto  = nil
                                    scanComplete   = false
                                    scanError      = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .padding(8),
                                alignment: .topTrailing
                            )

                        // AI SCAN BUTTON
                        Button(action: { scanImage() }) {
                            HStack {
                                if isScanning {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Scanning...")
                                } else if scanComplete {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Scan Complete — Tap to Re-scan")
                                } else {
                                    Image(systemName: "brain.head.profile")
                                    Text("Auto-fill with AI Scan")
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                scanComplete
                                    ? Color.green
                                    : themeManager.currentTheme.color
                            )
                            .cornerRadius(10)
                        }
                        .disabled(isScanning)

                        // SCAN ERROR MESSAGE
                        if scanError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Could not connect to AI server. Fill in manually.")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }

                        // CONFIDENCE SCORES
                        if scanComplete && !confidenceScores.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI Confidence")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                ForEach(confidenceScores.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    HStack {
                                        Text(key.capitalized)
                                            .font(.caption)
                                            .frame(width: 70, alignment: .leading)
                                        ProgressView(value: value / 100)
                                            .progressViewStyle(LinearProgressViewStyle(
                                                tint: value > 70 ? .green : value > 50 ? .orange : .red
                                            ))
                                        Text("\(Int(value))%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(width: 35)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }

                    } else {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(themeManager.currentTheme.color)
                                Text("Add Photo")
                                    .foregroundColor(themeManager.currentTheme.color)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.currentTheme.color.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }

                    if isUploading {
                        ProgressView(value: uploadProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: themeManager.currentTheme.color))
                    }
                }

                // ===================================
                // BASIC INFO
                // ===================================
                Section(header: Text("Basic Information")) {
                    TextField("Item Name", text: $itemName)

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ClothingItem.ClothingCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized).tag(category)
                        }
                    }
                }

                // ===================================
                // COLOR & PATTERN
                // ===================================
                Section(header: Text("Color & Pattern")) {
                    Picker("Color", selection: $selectedColor) {
                        ForEach(ClothingItem.ClothingColor.allCases, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(getSwiftUIColor(for: color))
                                    .frame(width: 20, height: 20)
                                Text(color.displayName)
                            }
                            .tag(color)
                        }
                    }

                    Picker("Pattern", selection: $selectedPattern) {
                        ForEach(ClothingItem.ClothingPattern.allCases, id: \.self) { pattern in
                            Text(pattern.displayName).tag(pattern)
                        }
                    }
                }

                // ===================================
                // STYLE DETAILS
                // ===================================
                Section(header: Text("Style Details")) {
                    Picker("Season", selection: $selectedSeason) {
                        ForEach(ClothingItem.Season.allCases, id: \.self) { season in
                            Text(season.displayName).tag(season)
                        }
                    }

                    Picker("Style", selection: $selectedStyle) {
                        ForEach(ClothingItem.ClothingStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }

                    Picker("Formality", selection: $selectedFormality) {
                        ForEach(ClothingItem.Formality.allCases, id: \.self) { formality in
                            Text(formality.displayName).tag(formality)
                        }
                    }
                }

                // ===================================
                // CUSTOM TAGS
                // ===================================
                Section(header: Text("Custom Tags")) {
                    HStack {
                        TextField("Add custom tag", text: $newTag)
                        Button(action: {
                            if !newTag.isEmpty {
                                customTags.append(newTag)
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
                                    HStack {
                                        Text(tag).font(.caption)
                                        Button(action: { customTags.removeAll { $0 == tag } }) {
                                            Image(systemName: "xmark.circle.fill").font(.caption)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(themeManager.currentTheme.color.opacity(0.2))
                                    .cornerRadius(15)
                                }
                            }
                        }
                    }
                }

                // ===================================
                // ADD BUTTON
                // ===================================
                Section {
                    Button("Add Item") {
                        Task { await addItemWithPhoto() }
                    }
                    .disabled(itemName.isEmpty || isUploading)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        scanComplete  = false
                        scanError     = false
                        // Auto-scan as soon as photo is picked
                        scanImage()
                    }
                }
            }
        }
    }

    // ===================================
    // AI SCAN FUNCTION
    // ===================================

    private func scanImage() {
        guard let image = selectedImage else { return }

        isScanning  = true
        scanError   = false
        scanComplete = false

        ClosetGeniusAPI.predict(image: image) { result in
            DispatchQueue.main.async {
                isScanning = false

                switch result {
                case .success(let prediction):
                    // Map category
                    selectedCategory = mapCategory(prediction.category)

                    // Map color
                    selectedColor = mapColor(prediction.color)

                    // Map season
                    selectedSeason = mapSeason(prediction.season)

                    // Map usage/style
                    selectedStyle    = mapStyle(prediction.usage)
                    selectedFormality = mapFormality(prediction.usage)

                    // Store confidence scores for display
                    confidenceScores = [
                        "category": prediction.categoryConfidence,
                        "color":    prediction.colorConfidence,
                        "season":   prediction.seasonConfidence,
                        "usage":    prediction.usageConfidence
                    ]
                    
                    // Only autofill if confidence is high enough
                    let MIN_CONFIDENCE = 50.0

                    if prediction.categoryConfidence >= MIN_CONFIDENCE {
                        selectedCategory = mapCategory(prediction.category)
                    }
                    if prediction.colorConfidence >= MIN_CONFIDENCE {
                        selectedColor = mapColor(prediction.color)
                    }
                    if prediction.seasonConfidence >= MIN_CONFIDENCE {
                        selectedSeason = mapSeason(prediction.season)
                    }
                    if prediction.usageConfidence >= MIN_CONFIDENCE {
                        selectedStyle    = mapStyle(prediction.usage)
                        selectedFormality = mapFormality(prediction.usage)
                    }

                    scanComplete = true

                case .failure(let error):
                    print("Scan failed: \(error)")
                    scanError = true
                }
            }
        }
    }

    // ===================================
    // MAPPING FUNCTIONS
    // (AlexNet labels → your app's enums)
    // ===================================

    private func mapCategory(_ predicted: String) -> ClothingItem.ClothingCategory {
        switch predicted.lowercased() {
        case "tshirts", "shirts", "tops", "kurtas":        return .tops
        case "jeans", "trousers", "shorts":                return .bottoms
        case "dresses":                                     return .dresses
        case "jackets", "sweaters":                         return .outerwear
        case "casual shoes", "formal shoes", "sandals":    return .shoes
        case "handbags", "watches":                         return .accessories
        default:                                            return .tops
        }
    }

    private func mapColor(_ predicted: String) -> ClothingItem.ClothingColor {
        switch predicted.lowercased() {
        case "red", "rust", "magenta":                        return .red
        case "blue", "turquoise blue":                        return .blue
        case "green", "sea green", "lime green", "olive":     return .green
        case "yellow", "mustard", "fluorescent green":        return .yellow
        case "orange", "peach":                               return .orange
        case "purple", "lavender", "mauve":                   return .purple
        case "pink":                                          return .pink
        case "brown", "coffee brown", "mushroom brown","tan": return .brown
        case "black", "charcoal":                             return .black
        case "white", "off white", "cream", "silver":        return .white
        case "grey", "grey melange", "steel":                 return .gray
        case "beige", "taupe", "khaki":                       return .beige
        case "navy blue":                                     return .navy
        case "burgundy", "maroon":                            return .burgundy
        case "teal":                                          return .teal
        case "gold", "bronze":                                return .yellow
        case "multi":                                         return .white  // fallback for multi
        default:                                              return .black
        }
    }

    private func mapSeason(_ predicted: String) -> ClothingItem.Season {
        switch predicted.lowercased() {
        case "spring": return .spring
        case "summer": return .summer
        case "fall":   return .fall
        case "winter": return .winter
        default:       return .allSeason
        }
    }

    private func mapStyle(_ predicted: String) -> ClothingItem.ClothingStyle {
        switch predicted.lowercased() {
        case "casual":       return .casual
        case "formal":       return .formal
        case "sports":       return .sporty
        case "ethnic":       return .bohemian
        case "smart casual": return .preppy
        case "party":        return .edgy
        default:             return .casual
        }
    }

    private func mapFormality(_ predicted: String) -> ClothingItem.Formality {
        switch predicted.lowercased() {
        case "formal":       return .formal
        case "sports":       return .athletic
        case "smart casual": return .smartCasual
        case "casual":       return .casual
        case "party":        return .business
        default:             return .casual
        }
    }

    // ===================================
    // UPLOAD & SAVE
    // ===================================

    private func addItemWithPhoto() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        var imageURL: String? = nil
        if let image = selectedImage {
            isUploading = true
            imageURL    = await uploadItemPhoto(image: image, userId: userId)
            isUploading = false
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
            imageURL: imageURL,
            wearCount: 0,
            dateAdded: Date(),
            customTags: customTags
        )

        viewModel.addItem(newItem)
        dismiss()
    }

    private func uploadItemPhoto(image: UIImage, userId: String) async -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else { return nil }

        let storage     = Storage.storage()
        let storageRef  = storage.reference()
        let itemId      = UUID().uuidString
        let itemRef     = storageRef.child("clothing_items/\(userId)/\(itemId).jpg")
        let metadata    = StorageMetadata()
        metadata.contentType = "image/jpeg"

        do {
            let uploadTask = itemRef.putData(imageData, metadata: metadata)
            uploadTask.observe(.progress) { snapshot in
                if let progress = snapshot.progress {
                    Task { @MainActor in
                        self.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    }
                }
            }
            _ = await uploadTask
            let downloadURL = try await itemRef.downloadURL()
            return downloadURL.absoluteString
        } catch {
            print("Upload error: \(error)")
            return nil
        }
    }

    private func getSwiftUIColor(for color: ClothingItem.ClothingColor) -> Color {
        switch color {
        case .red:      return .red
        case .blue:     return .blue
        case .green:    return .green
        case .yellow:   return .yellow
        case .orange:   return .orange
        case .purple:   return .purple
        case .pink:     return .pink
        case .brown:    return .brown
        case .black:    return .black
        case .white:    return .gray.opacity(0.3)
        case .gray:     return .gray
        case .beige:    return Color(red: 0.96, green: 0.96, blue: 0.86)
        case .navy:     return Color(red: 0, green: 0, blue: 0.5)
        case .burgundy: return Color(red: 0.5, green: 0, blue: 0.13)
        case .teal:     return .teal
        case .cream:    return Color(red: 1, green: 0.99, blue: 0.82)
        }
    }
}
