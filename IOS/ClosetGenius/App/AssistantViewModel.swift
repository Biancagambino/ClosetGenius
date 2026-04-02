//
//  AssistantViewModel.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Message Types

enum MessageRole: String, Codable {
    case user
    case assistant
}

struct AIMessage: Identifiable {
    let id: UUID
    let role: MessageRole
    let text: String
    let timestamp: Date

    init(role: MessageRole, text: String) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.timestamp = Date()
    }
}

// MARK: - API Codable Types

struct ClothingItemPayload: Codable {
    let name: String
    let category: String
    let color: String
    let style: String
    let formality: String
    let notes: String?
    let customTags: [String]

    enum CodingKeys: String, CodingKey {
        case name, category, color, style, formality, notes
        case customTags = "custom_tags"
    }

    init(from item: ClothingItem) {
        self.name = item.name
        self.category = item.category.rawValue
        self.color = item.color.rawValue
        self.style = item.style.rawValue
        self.formality = item.formality.rawValue
        self.notes = item.notes
        self.customTags = item.customTags
    }
}

struct ChatHistoryEntry: Codable {
    let role: String
    let content: String
}

struct ChatRequest: Codable {
    let message: String
    let history: [ChatHistoryEntry]
    let closet: [ClothingItemPayload]
}

struct ChatResponse: Codable {
    let reply: String?
    let error: String?
}

// MARK: - AssistantViewModel

@MainActor
class AssistantViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func sendMessage(text: String, closetItems: [ClothingItem]) {
        let userMessage = AIMessage(role: .user, text: text)
        messages.append(userMessage)
        errorMessage = nil
        isLoading = true

        let history = buildHistory()

        Task {
            do {
                let reply = try await AIClassificationService.chat(
                    message: text,
                    closetItems: closetItems,
                    history: history
                )
                messages.append(AIMessage(role: .assistant, text: reply))
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func clearConversation() {
        messages.removeAll()
        errorMessage = nil
    }

    // Build history from all messages except the last user message (already passed separately)
    private func buildHistory() -> [ChatHistoryEntry] {
        // Exclude the last message (the user message just appended)
        let historyMessages = messages.dropLast()
        return historyMessages.map { ChatHistoryEntry(role: $0.role.rawValue, content: $0.text) }
    }
}
