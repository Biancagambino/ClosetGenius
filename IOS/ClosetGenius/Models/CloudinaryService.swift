//
//  CloudinaryService.swift
//  ClosetGenius
//

import Foundation
import UIKit

struct CloudinaryService {
    private static let cloudName   = "duogssptl"
    private static let uploadPreset = "originals"
    private static let uploadURL   = "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload"

    /// Uploads a UIImage to Cloudinary and returns the secure URL.
    static func upload(image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw CloudinaryError.imageConversionFailed
        }
        guard let url = URL(string: uploadURL) else {
            throw CloudinaryError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        var body = Data()

        // upload_preset field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(uploadPreset)\r\n".data(using: .utf8)!)

        // file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"item.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw CloudinaryError.uploadFailed
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let secureURL = json["secure_url"] as? String else {
            throw CloudinaryError.uploadFailed
        }

        return secureURL
    }
}

enum CloudinaryError: LocalizedError {
    case imageConversionFailed, invalidURL, uploadFailed

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "Could not prepare image for upload."
        case .invalidURL:            return "Invalid Cloudinary URL."
        case .uploadFailed:          return "Image upload failed."
        }
    }
}
