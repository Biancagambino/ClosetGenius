//
//  FriendsViewModel.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [User] = []
    @Published var friendRequests: [User] = []
    @Published var searchResults: [User] = []
    @Published var outfitFeed: [OutfitPost] = []
    @Published var isLoading = false
    
    // Mock data for development
    init() {
        loadMockData()
    }
    
    func loadMockData() {
        // Mock friends
        friends = [
            User(id: "friend1", email: "sarah@example.com", displayName: "Sarah", profileImageURL: nil, closetItemCount: 45, sustainabilityScore: 120, friendIDs: [], customSubcategories: [], newItemsPurchased: 5, itemsReworn: 30, tradesMade: 8),
            User(id: "friend2", email: "mike@example.com", displayName: "Mike", profileImageURL: nil, closetItemCount: 32, sustainabilityScore: 85, friendIDs: [], customSubcategories: [], newItemsPurchased: 8, itemsReworn: 20, tradesMade: 4),
            User(id: "friend3", email: "emma@example.com", displayName: "Emma", profileImageURL: nil, closetItemCount: 67, sustainabilityScore: 200, friendIDs: [], customSubcategories: [], newItemsPurchased: 3, itemsReworn: 50, tradesMade: 12)
        ]
        
        // Mock outfit feed
        outfitFeed = [
            OutfitPost(
                id: "post1",
                userID: "friend1",
                userName: "Sarah",
                outfitID: "outfit1",
                caption: "Ready for brunch! 🥐☕️",
                imageURL: nil,
                datePosted: Date().addingTimeInterval(-3600),
                likes: ["currentUser", "friend2"],
                comments: [
                    OutfitPost.Comment(id: "c1", userID: "friend2", userName: "Mike", text: "Love this look!", datePosted: Date().addingTimeInterval(-1800))
                ]
            ),
            OutfitPost(
                id: "post2",
                userID: "friend3",
                userName: "Emma",
                outfitID: "outfit2",
                caption: "Office vibes 💼",
                imageURL: nil,
                datePosted: Date().addingTimeInterval(-7200),
                likes: ["currentUser", "friend1", "friend2"],
                comments: []
            ),
            OutfitPost(
                id: "post3",
                userID: "friend2",
                userName: "Mike",
                outfitID: "outfit3",
                caption: "Weekend casual 😎",
                imageURL: nil,
                datePosted: Date().addingTimeInterval(-14400),
                likes: ["friend1"],
                comments: []
            )
        ]
    }
    
    func searchUsers(query: String) {
        // TODO: Implement Firebase search
        searchResults = []
    }
    
    func sendFriendRequest(to user: User) {
        // TODO: Implement Firebase friend request
    }
    
    func acceptFriendRequest(from user: User) {
        // TODO: Implement Firebase accept friend request
        friends.append(user)
        friendRequests.removeAll { $0.id == user.id }
    }
    
    func toggleLike(post: OutfitPost) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        if let index = outfitFeed.firstIndex(where: { $0.id == post.id }) {
            if outfitFeed[index].likes.contains(currentUserId) {
                outfitFeed[index].likes.removeAll { $0 == currentUserId }
            } else {
                outfitFeed[index].likes.append(currentUserId)
            }
        }
    }
    
    func addComment(to post: OutfitPost, text: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        if let index = outfitFeed.firstIndex(where: { $0.id == post.id }) {
            let comment = OutfitPost.Comment(
                id: UUID().uuidString,
                userID: currentUserId,
                userName: "You",
                text: text,
                datePosted: Date()
            )
            outfitFeed[index].comments.append(comment)
        }
    }
}
