//
//  AIClassificationService.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 3/30/26.
//

import Foundation
import UIKit

// MARK: - Service URL (configurable from Settings)

// MARK: - Response Model (matches Flask /scan JSON output)

struct FlorenceClassificationResponse: Codable {
    let category: String
    let color: String
    let season: String
    let usage: String
    let pattern: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case category, color, season, usage, pattern, description
    }
}

// MARK: - Service

class AIClassificationService {

    static var baseURL: String {
        get { UserDefaults.standard.string(forKey: "colabBaseURL") ?? "https://closetgenius-api-22315601029.us-central1.run.app" }
        set { UserDefaults.standard.set(newValue, forKey: "colabBaseURL") }
    }
    private static var serverURL: String { baseURL + "/scan" }
    private static var chatURL: String { baseURL + "/chat" }

    /// Quick reachability check — resolves true if the Colab server responds.
    static func ping() async -> Bool {
        guard let url = URL(string: baseURL + "/health") else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 5
        return (try? await URLSession.shared.data(for: req)) != nil
    }

    /// Sends image to your Colab Flask server via multipart upload.
    /// Matches Flask's POST /scan — field name must be 'image'
    static func classify(image: UIImage) async throws -> FlorenceClassificationResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ClassificationError.imageConversionFailed
        }
        guard let url = URL(string: serverURL) else {
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
        if ["dress","gown","romper","jumpsuit","frock","saree","sari"].contains(where: { s.contains($0) }) { return .dresses }
        if ["jacket","coat","blazer","cardigan","parka","outerwear","tracksuit"].contains(where: { s.contains($0) }) { return .outerwear }
        if ["shoe","boot","sandal","sneaker","heel","loafer","flat","footwear","flip flop"].contains(where: { s.contains($0) }) { return .shoes }
        if ["bag","hat","scarf","belt","wallet","watch","purse","backpack","sunglasses","handbag","cap","tie","earring","necklace","chain","sock","brief","underwear"].contains(where: { s.contains($0) }) { return .accessories }
        if ["jean","pant","trouser","short","skirt","legging","chino","churidar","salwar"].contains(where: { s.contains($0) }) { return .bottoms }
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
            ("silver",.gray),("khaki",.beige),
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
        if s.contains("smart") || s.contains("party") { return .smartCasual }
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

// MARK: - Flask Chat

extension AIClassificationService {
    /// Sends a message + closet context to the Flask /chat endpoint and returns the reply.
    static func chat(message: String, closetItems: [ClothingItem], history: [ChatHistoryEntry] = []) async throws -> String {
        guard let url = URL(string: chatURL) else {
            throw ClassificationError.invalidURL
        }

        let closetPayload = closetItems.prefix(25).map { item in
            ["name": item.name, "category": item.category.rawValue, "color": item.color.rawValue]
        }

        let historyPayload = history.map { ["role": $0.role, "content": $0.content] }

        let body: [String: Any] = [
            "message": message,
            "closet": closetPayload,
            "history": historyPayload
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ClassificationError.invalidResponse
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let reply = json["reply"] as? String {
            return reply
        }
        throw ClassificationError.invalidResponse
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

