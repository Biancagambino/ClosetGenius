//
//  OllamaService.swift
//  ClosetGenius
//
//  Calls a local Ollama instance running Llama 3 to generate
//  a natural-language description of a clothing item from its labels.
//
//  Prerequisites:
//    1. Install Ollama: https://ollama.ai
//    2. Run: ollama pull llama3
//    3. Ollama runs at http://localhost:11434 by default
//

import Foundation

// MARK: - Ollama Request / Response

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
    static let model = "llama3"
    
    // MARK: - Generate Description
    
    /// Generates a concise, fashionable description of a clothing item.
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
        
        let tagString = customTags.isEmpty ? "" : ", Tags: \(customTags.joined(separator: ", "))"
        
        let prompt = """
        You are a fashion expert writing brief, stylish descriptions for a digital closet app.
        
        Write a 2-3 sentence description for this clothing item. Be specific, fashionable, and helpful for outfit planning. Do not repeat the item name. Do not use filler phrases like "This item is...".
        
        Item details:
        - Name: \(name)
        - Category: \(category.rawValue)
        - Color: \(color.displayName)
        - Pattern: \(pattern.displayName)
        - Season: \(season.displayName)
        - Style: \(style.displayName)
        - Formality: \(formality.displayName)\(tagString)
        
        Description:
        """
        
        guard let url = URL(string: baseURL) else {
            throw OllamaError.invalidURL
        }
        
        let requestBody = OllamaRequest(
            model: model,
            prompt: prompt,
            stream: false,
            options: OllamaOptions(temperature: 0.7, numPredict: 120)
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OllamaError.serverError
        }
        
        let ollamaResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return ollamaResponse.response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Outfit Suggestion (bonus — used in DashboardView later)
    
    /// Given a list of item names, suggests an outfit combination.
    static func suggestOutfit(
        items: [ClothingItem],
        weather: String = "",
        occasion: String = "casual"
    ) async throws -> String {
        
        let itemList = items.prefix(20).map { "- \($0.name) (\($0.category.rawValue), \($0.color.displayName))" }.joined(separator: "\n")
        let weatherContext = weather.isEmpty ? "" : "Current weather: \(weather). "
        
        let prompt = """
        You are a personal stylist. \(weatherContext)Suggest a complete outfit for a \(occasion) occasion from the items below. Name the specific items and explain why they work together in 3-4 sentences.
        
        Available items:
        \(itemList)
        
        Outfit suggestion:
        """
        
        guard let url = URL(string: baseURL) else {
            throw OllamaError.invalidURL
        }
        
        let requestBody = OllamaRequest(
            model: model,
            prompt: prompt,
            stream: false,
            options: OllamaOptions(temperature: 0.8, numPredict: 200)
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OllamaError.serverError
        }
        
        let ollamaResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return ollamaResponse.response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Errors

enum OllamaError: LocalizedError {
    case invalidURL
    case serverError
    case serverUnreachable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ollama server URL is invalid."
        case .serverError:
            return "Ollama server returned an error."
        case .serverUnreachable:
            return "Ollama is not running. Start it with: ollama serve"
        }
    }
}