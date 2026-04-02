//
//  OllamaService.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 3/30/26.
//

import Foundation

// MARK: - Private request/response types (only defined here)

private struct OllamaRequest: Codable {
    let model: String
    let prompt: String
    let stream: Bool
    let options: OllamaOptions?
}

private struct OllamaOptions: Codable {
    let temperature: Double
    let numPredict: Int
    enum CodingKeys: String, CodingKey {
        case temperature
        case numPredict = "num_predict"
    }
}

private struct OllamaResponse: Codable {
    let response: String
    let done: Bool
}

// MARK: - Service

class OllamaService {

    static let baseURL = "http://localhost:11434/api/generate"
    static let model   = "llama3"

    /// Generates a 2-3 sentence fashion description for a clothing item.
    static func generateDescription(
        name: String,
        category: ClothingItem.ClothingCategory,
        color: ClothingItem.ClothingColor,
        pattern: ClothingItem.ClothingPattern,
        season: ClothingItem.Season,
        style: ClothingItem.ClothingStyle,
        formality: ClothingItem.Formality,
        customTags: [String] = []
    ) async throws -> String {

        let tags = customTags.isEmpty ? "" : ", Tags: \(customTags.joined(separator: ", "))"
        let prompt = """
        You are a fashion expert writing brief, stylish descriptions for a digital closet app.
        Write 2-3 sentences describing this item. Be specific and helpful for outfit planning.
        Do not repeat the item name. Do not start with "This item is".

        - Name: \(name)
        - Category: \(category.rawValue)
        - Color: \(color.displayName)
        - Pattern: \(pattern.displayName)
        - Season: \(season.displayName)
        - Style: \(style.displayName)
        - Formality: \(formality.displayName)\(tags)

        Description:
        """

        return try await callOllama(prompt: prompt, maxTokens: 120, temperature: 0.7)
    }

    /// Suggests a complete outfit from the user's closet items.
    static func suggestOutfit(
        items: [ClothingItem],
        weather: String = "",
        occasion: String = "casual"
    ) async throws -> String {

        let list = items.prefix(20)
            .map { "- \($0.name) (\($0.category.rawValue), \($0.color.displayName))" }
            .joined(separator: "\n")
        let ctx = weather.isEmpty ? "" : "Current weather: \(weather). "

        let prompt = """
        You are a personal stylist. \(ctx)Suggest a complete outfit for a \(occasion) occasion from these items. Name the specific pieces and explain why they work together in 3-4 sentences.

        Available items:
        \(list)

        Outfit suggestion:
        """

        return try await callOllama(prompt: prompt, maxTokens: 200, temperature: 0.8)
    }

    static func chat(prompt: String) async throws -> String {
        return try await callOllama(prompt: prompt, maxTokens: 300, temperature: 0.8)
    }

    // MARK: - Internal

    private static func callOllama(prompt: String, maxTokens: Int, temperature: Double) async throws -> String {
        guard let url = URL(string: baseURL) else { throw OllamaError.invalidURL }

        let body = OllamaRequest(
            model: model,
            prompt: prompt,
            stream: false,
            options: OllamaOptions(temperature: temperature, numPredict: maxTokens)
        )

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 60
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OllamaError.serverError
        }

        let decoded = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return decoded.response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - ClosetGenius Chat API

enum ClosetGeniusAPI {
    static func chat(message: String, history: [ChatHistoryEntry], closet: [ClothingItemPayload]) async throws -> String {
        let closetSummary = closet.prefix(20)
            .map { "- \($0.name) (\($0.category), \($0.color))" }
            .joined(separator: "\n")

        let historyText = history.suffix(6)
            .map { "\($0.role): \($0.content)" }
            .joined(separator: "\n")

        let prompt = """
        You are ClosetGenius, a personal style assistant. Answer the user's fashion question using their closet items below.

        Closet:
        \(closetSummary.isEmpty ? "No items yet." : closetSummary)

        \(historyText.isEmpty ? "" : "Conversation so far:\n\(historyText)\n")
        User: \(message)
        Assistant:
        """

        return try await OllamaService.chat(prompt: prompt)
    }
}

// MARK: - Errors

enum OllamaError: LocalizedError {
    case invalidURL, serverError, serverUnreachable

    var errorDescription: String? {
        switch self {
        case .invalidURL:        return "Ollama URL is invalid."
        case .serverError:       return "Ollama returned an error."
        case .serverUnreachable: return "Ollama not running — run: ollama serve"
        }
    }
}
