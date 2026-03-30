//
//  FlorenceClassificationResponse.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 3/30/26.
//


//
//  AIClassificationService.swift
//  ClosetGenius
//
//  Calls your local Florence-2 classification server (Python/FastAPI).
//  The server should be running at http://localhost:8000 on the same Mac.
//  It accepts a base64 image and returns structured clothing labels.
//

import Foundation
import UIKit

// MARK: - Response Models

struct FlorenceClassificationResponse: Codable {
    let category: String
    let color: String
    let season: String
    let usage: String          // maps to Formality
    let pattern: String?
    let confidence: Double?
    let rawDescription: String?  // Florence-2 caption if available
}

struct FlorenceErrorResponse: Codable {
    let error: String
}

// MARK: - Service

class AIClassificationService: ObservableObject {
    
    // Change this if your Flask/FastAPI server runs on a different port
    static let serverURL = "http://localhost:8000/classify"
    
    // MARK: - Classify Image
    
    /// Sends a UIImage to the Florence-2 server and returns structured labels.
    static func classify(image: UIImage) async throws -> FlorenceClassificationResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ClassificationError.imageConversionFailed
        }
        
        let base64String = imageData.base64EncodedString()
        
        guard let url = URL(string: serverURL) else {
            throw ClassificationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let body: [String: Any] = ["image": base64String]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClassificationError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(FlorenceErrorResponse.self, from: data) {
                throw ClassificationError.serverError(errorResponse.error)
            }
            throw ClassificationError.httpError(httpResponse.statusCode)
        }
        
        let result = try JSONDecoder().decode(FlorenceClassificationResponse.self, from: data)
        return result
    }
    
    // MARK: - Map to ClothingItem Enums
    
    static func mapCategory(_ raw: String) -> ClothingItem.ClothingCategory {
        let lower = raw.lowercased()
        switch lower {
        case "tops", "top", "shirt", "blouse", "t-shirt", "tshirt":
            return .tops
        case "bottoms", "bottom", "pants", "jeans", "skirt", "shorts":
            return .bottoms
        case "dresses", "dress", "jumpsuit", "romper":
            return .dresses
        case "outerwear", "jacket", "coat", "blazer", "hoodie":
            return .outerwear
        case "shoes", "footwear", "sneakers", "boots", "heels", "sandals":
            return .shoes
        case "accessories", "accessory", "bag", "hat", "scarf", "belt", "jewelry":
            return .accessories
        default:
            return .tops
        }
    }
    
    static func mapColor(_ raw: String) -> ClothingItem.ClothingColor {
        let lower = raw.lowercased()
        switch lower {
        case "red": return .red
        case "blue", "light blue", "sky blue": return .blue
        case "green", "olive", "khaki": return .green
        case "yellow", "gold": return .yellow
        case "orange": return .orange
        case "purple", "lavender", "violet": return .purple
        case "pink", "rose", "blush": return .pink
        case "brown", "tan", "camel": return .brown
        case "black": return .black
        case "white": return .white
        case "gray", "grey", "silver": return .gray
        case "beige", "nude": return .beige
        case "navy", "dark blue", "midnight blue": return .navy
        case "burgundy", "wine", "maroon": return .burgundy
        case "teal", "turquoise", "aqua": return .teal
        case "cream", "ivory", "off-white": return .cream
        default: return .black
        }
    }
    
    static func mapSeason(_ raw: String) -> ClothingItem.Season {
        let lower = raw.lowercased()
        switch lower {
        case "spring": return .spring
        case "summer": return .summer
        case "fall", "autumn": return .fall
        case "winter": return .winter
        default: return .allSeason
        }
    }
    
    static func mapFormality(_ raw: String) -> ClothingItem.Formality {
        let lower = raw.lowercased()
        switch lower {
        case "formal", "very formal": return .formal
        case "business", "work", "office": return .business
        case "smart casual", "smart": return .smartCasual
        case "athletic", "sport", "sporty", "gym": return .athletic
        default: return .casual
        }
    }
    
    static func mapPattern(_ raw: String?) -> ClothingItem.ClothingPattern {
        guard let raw = raw else { return .solid }
        let lower = raw.lowercased()
        switch lower {
        case "striped", "stripes": return .striped
        case "polka dot", "dots": return .polkaDot
        case "floral", "flowers": return .floral
        case "plaid", "tartan", "check": return .plaid
        case "geometric": return .geometric
        case "animal", "leopard", "zebra": return .animal
        case "abstract": return .abstract
        default: return .solid
        }
    }
}

// MARK: - Errors

enum ClassificationError: LocalizedError {
    case imageConversionFailed
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case serverUnreachable
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Could not convert image for upload."
        case .invalidURL:
            return "AI server URL is invalid."
        case .invalidResponse:
            return "Unexpected response from AI server."
        case .httpError(let code):
            return "Server returned error code \(code)."
        case .serverError(let msg):
            return "AI server error: \(msg)"
        case .serverUnreachable:
            return "AI server is not running. Make sure Florence-2 server is started."
        }
    }
}