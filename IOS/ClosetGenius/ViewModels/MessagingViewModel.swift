//
//  MessagingViewModel.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/18/26.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class MessagingViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var messages: [String: [Message]] = [:] // conversationID: [messages]
    @Published var isLoading = false
    
    private var listeners: [ListenerRegistration] = []
    
    func loadConversations() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        let db = Firestore.firestore()
        
        // Real-time listener for conversations
        let listener = db.collection("conversations")
            .whereField("participantIDs", arrayContains: userId)
            .order(by: "lastMessageTime", descending: true)
            .addSnapshotListener { snapshot, error in
                Task { @MainActor in
                    self.isLoading = false
                    if let documents = snapshot?.documents {
                        self.conversations = documents.compactMap { doc in
                            try? doc.data(as: Conversation.self)
                        }
                    }
                }
            }
        
        listeners.append(listener)
    }
    
    func loadMessages(for conversationID: String) {
        let db = Firestore.firestore()
        
        // Real-time listener for messages
        let listener = db.collection("conversations")
            .document(conversationID)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                Task { @MainActor in
                    if let documents = snapshot?.documents {
                        let msgs = documents.compactMap { doc in
                            try? doc.data(as: Message.self)
                        }
                        self.messages[conversationID] = msgs
                    }
                }
            }
        
        listeners.append(listener)
    }
    
    func sendMessage(to recipientID: String, recipientName: String, text: String, listingID: String? = nil) {
        guard let userId = Auth.auth().currentUser?.uid,
              let userName = Auth.auth().currentUser?.displayName else { return }
        
        let db = Firestore.firestore()
        
        // Create or get conversation
        let conversationID = createConversationID(user1: userId, user2: recipientID)
        
        let message = Message(
            id: UUID().uuidString,
            senderID: userId,
            senderName: userName,
            recipientID: recipientID,
            text: text,
            timestamp: Date(),
            isRead: false,
            relatedListingID: listingID
        )
        
        // Save message
        try? db.collection("conversations")
            .document(conversationID)
            .collection("messages")
            .document(message.id)
            .setData(from: message)
        
        // Update or create conversation
        let conversation = Conversation(
            id: conversationID,
            participantIDs: [userId, recipientID],
            participantNames: [userId: userName, recipientID: recipientName],
            lastMessage: text,
            lastMessageTime: Date(),
            unreadCount: 1,
            relatedListingID: listingID
        )
        
        try? db.collection("conversations")
            .document(conversationID)
            .setData(from: conversation)
    }
    
    func markAsRead(conversationID: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Mark all messages in conversation as read
        if let msgs = messages[conversationID] {
            for message in msgs where message.recipientID == userId && !message.isRead {
                db.collection("conversations")
                    .document(conversationID)
                    .collection("messages")
                    .document(message.id)
                    .updateData(["isRead": true])
            }
        }
    }
    
    private func createConversationID(user1: String, user2: String) -> String {
        // Always create same ID regardless of who initiates
        return [user1, user2].sorted().joined(separator: "_")
    }
    
    func cleanup() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    nonisolated deinit {
        let currentListeners = listeners
        Task {
            currentListeners.forEach { $0.remove() }
        }
    }
}
