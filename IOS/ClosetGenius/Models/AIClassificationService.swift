//
//  AIClassificationService.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 3/30/26.
//

import Foundation
import UIKit

// UPDATE THIS every time you restart Colab:
private let COLAB_SERVER_URL = "https://YOUR-NGROK-URL.ngrok-free.app/predict"

// MARK: - Response Model (matches your Flask /predict JSON output)

struct FlorenceClassificationResponse: Codable {
    let category: String
    let color: String
    let season: String
    let usage: String
    let pattern: String?
    let confidence: Double?
    let rawDescription: String?

    enum CodingKeys: String, CodingKey {
        case category, color, season, usage, pattern, confidence
        case rawDescription = "raw_description"
    }
}

// MARK: - Service

class AIClassificationService {

    /// Sends image to your Colab Flask server via multipart upload.
    /// Matches Flask's: request.files['image']
    static func classify(image: UIImage) async throws -> FlorenceClassificationResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ClassificationError.imageConversionFailed
        }
        guard let url = URL(string: COLAB_SERVER_URL) else {
            throw ClassificationError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"item.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ClassificationError.invalidResponse
        }
        guard http.statusCode == 200 else {
            throw ClassificationError.httpError(http.statusCode)
        }

        return try JSONDecoder().decode(FlorenceClassificationResponse.self, from: data)
    }

    // MARK: - Map server strings → ClothingItem enums

    static func mapCategory(_ raw: String) -> ClothingItem.ClothingCategory {
        let s = raw.lowercased()
        if ["dress","gown","romper","jumpsuit","frock"].contains(where: s.contains) { return .dresses }
        if ["jacket","coat","blazer","cardigan","parka","outerwear"].contains(where: s.contains) { return .outerwear }
        if ["shoe","boot","sandal","sneaker","heel","loafer","flat","footwear"].contains(where: s.contains) { return .shoes }
        if ["bag","hat","scarf","belt","wallet","watch","purse","backpack","sunglasses","handbag"].contains(where: s.contains) { return .accessories }
        if ["jean","pant","trouser","short","skirt","legging","chino"].contains(where: s.contains) { return .bottoms }
        return .tops
    }

    static func mapColor(_ raw: String) -> ClothingItem.ClothingColor {
        let s = raw.lowercased()
        let pairs: [(String, ClothingItem.ClothingColor)] = [
            ("navy",.navy),("black",.black),("white",.white),
            ("grey",.gray),("gray",.gray),("charcoal",.gray),
            ("burgundy",.burgundy),("wine",.burgundy),("maroon",.burgundy),
            ("teal",.teal),("turquoise",.teal),
            ("cream",.cream),("ivory",.cream),
            ("beige",.beige),("nude",.beige),
            ("pink",.pink),("rose",.pink),("blush",.pink),("coral",.pink),
            ("purple",.purple),("lavender",.purple),("violet",.purple),
            ("brown",.brown),("tan",.brown),("camel",.brown),
            ("yellow",.yellow),("mustard",.yellow),("gold",.yellow),
            ("orange",.orange),("rust",.orange),
            ("green",.green),("olive",.green),("sage",.green),
            ("red",.red),("scarlet",.red),("crimson",.red),
            ("blue",.blue),("cobalt",.blue),
        ]
        for (kw, color) in pairs { if s.contains(kw) { return color } }
        return .black
    }

    static func mapSeason(_ raw: String) -> ClothingItem.Season {
        switch raw.lowercased() {
        case "summer": return .summer
        case "winter": return .winter
        case "spring": return .spring
        case "fall","autumn": return .fall
        default: return .allSeason
        }
    }

    static func mapFormality(_ raw: String) -> ClothingItem.Formality {
        let s = raw.lowercased()
        if s.contains("sport") || s.contains("gym") || s.contains("athletic") { return .athletic }
        if s.contains("formal") || s.contains("ethnic") { return .formal }
        if s.contains("business") || s.contains("office") { return .business }
        if s.contains("smart") { return .smartCasual }
        return .casual
    }

    static func mapPattern(_ raw: String?) -> ClothingItem.ClothingPattern {
        guard let s = raw?.lowercased() else { return .solid }
        if s.contains("strip") { return .striped }
        if s.contains("floral") { return .floral }
        if s.contains("plaid") || s.contains("tartan") || s.contains("check") { return .plaid }
        if s.contains("polka") || s.contains("dot") { return .polkaDot }
        if s.contains("geometric") { return .geometric }
        if s.contains("animal") || s.contains("leopard") || s.contains("zebra") { return .animal }
        return .solid
    }
}

// MARK: - Errors

enum ClassificationError: LocalizedError {
    case imageConversionFailed, invalidURL, invalidResponse
    case httpError(Int), serverError(String), serverUnreachable

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "Could not prepare image for upload."
        case .invalidURL: return "Update COLAB_SERVER_URL in AIClassificationService.swift."
        case .invalidResponse: return "Unexpected response from server."
        case .httpError(let c): return "Server error \(c) — is Colab still running?"
        case .serverError(let m): return "Server error: \(m)"
        case .serverUnreachable: return "AI server unreachable."
        }
    }
}

// Helper
private extension Array where Element == String {
    func contains(where predicate: (String) -> Bool) -> Bool {
        self.contains { predicate($0) }
    }
}
