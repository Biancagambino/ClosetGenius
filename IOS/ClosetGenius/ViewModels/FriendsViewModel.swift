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

    init() {
        loadAll()
    }

    func loadAll() {
        loadFriends()
        loadFriendRequests()
        loadFeed()
    }

    // MARK: - Load Friends

    func loadFriends() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, _ in
            guard let self else { return }
            let friendIDs = snapshot?.data()?["friendIDs"] as? [String] ?? []
            guard !friendIDs.isEmpty else { return }
            Task { @MainActor in
                for fid in friendIDs {
                    db.collection("users").document(fid).getDocument { snap, _ in
                        Task { @MainActor in
                            guard let data = snap?.data() else { return }
                            let friend = self.userFrom(id: fid, data: data)
                            if !self.friends.contains(where: { $0.id == fid }) {
                                self.friends.append(friend)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Load Friend Requests

    func loadFriendRequests() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("friendRequests")
            .whereField("to", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, _ in
                guard let self else { return }
                let fromIDs = snapshot?.documents.compactMap { $0.data()["from"] as? String } ?? []
                Task { @MainActor in
                    for fid in fromIDs {
                        db.collection("users").document(fid).getDocument { snap, _ in
                            Task { @MainActor in
                                guard let data = snap?.data() else { return }
                                let requester = self.userFrom(id: fid, data: data)
                                if !self.friendRequests.contains(where: { $0.id == fid }) {
                                    self.friendRequests.append(requester)
                                }
                            }
                        }
                    }
                }
            }
    }

    // MARK: - Load Feed

    func loadFeed() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, _ in
            guard let self else { return }
            var feedIDs = snapshot?.data()?["friendIDs"] as? [String] ?? []
            feedIDs.append(userId)
            guard !feedIDs.isEmpty else { return }

            // Firestore "in" queries support up to 30 values; chunk by 10 to be safe
            let chunks = feedIDs.chunked(into: 10)
            Task { @MainActor in
                for chunk in chunks {
                    db.collection("outfitPosts")
                        .whereField("userID", in: chunk)
                        .order(by: "datePosted", descending: true)
                        .limit(to: 20)
                        .getDocuments { snap, _ in
                            Task { @MainActor in
                                let posts = snap?.documents.compactMap { try? $0.data(as: OutfitPost.self) } ?? []
                                for post in posts where !self.outfitFeed.contains(where: { $0.id == post.id }) {
                                    self.outfitFeed.append(post)
                                }
                                self.outfitFeed.sort { $0.datePosted > $1.datePosted }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Search

    func searchUsers(query: String) {
        guard query.count >= 2 else { searchResults = []; return }
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let lower = query.lowercased()
        let upper = lower + "\u{f8ff}"

        db.collection("users")
            .whereField("displayName", isGreaterThanOrEqualTo: lower)
            .whereField("displayName", isLessThanOrEqualTo: upper)
            .limit(to: 15)
            .getDocuments { [weak self] snapshot, _ in
                guard let self else { return }
                Task { @MainActor in
                    self.searchResults = snapshot?.documents.compactMap { doc -> User? in
                        guard doc.documentID != currentUserId else { return nil }
                        return self.userFrom(id: doc.documentID, data: doc.data())
                    } ?? []
                }
            }
    }

    // MARK: - Friend Requests

    func sendFriendRequest(to user: User) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let requestId = "\(currentUserId)_\(user.id)"
        db.collection("friendRequests").document(requestId).setData([
            "from": currentUserId,
            "to": user.id,
            "timestamp": FieldValue.serverTimestamp()
        ])
    }

    func acceptFriendRequest(from user: User) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let requestId = "\(user.id)_\(currentUserId)"

        db.collection("users").document(currentUserId).updateData([
            "friendIDs": FieldValue.arrayUnion([user.id])
        ])
        db.collection("users").document(user.id).updateData([
            "friendIDs": FieldValue.arrayUnion([currentUserId])
        ])
        db.collection("friendRequests").document(requestId).delete()

        if !friends.contains(where: { $0.id == user.id }) {
            friends.append(user)
        }
        friendRequests.removeAll { $0.id == user.id }
    }

    // MARK: - Social Actions

    func toggleLike(post: OutfitPost) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let index = outfitFeed.firstIndex(where: { $0.id == post.id }) else { return }
        let db = Firestore.firestore()
        if outfitFeed[index].likes.contains(currentUserId) {
            outfitFeed[index].likes.removeAll { $0 == currentUserId }
            db.collection("outfitPosts").document(post.id).updateData([
                "likes": FieldValue.arrayRemove([currentUserId])
            ])
        } else {
            outfitFeed[index].likes.append(currentUserId)
            db.collection("outfitPosts").document(post.id).updateData([
                "likes": FieldValue.arrayUnion([currentUserId])
            ])
        }
    }

    func addComment(to post: OutfitPost, text: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let index = outfitFeed.firstIndex(where: { $0.id == post.id }) else { return }

        let comment = OutfitPost.Comment(
            id: UUID().uuidString,
            userID: currentUserId,
            userName: Auth.auth().currentUser?.displayName ?? "You",
            text: text,
            datePosted: Date()
        )
        outfitFeed[index].comments.append(comment)

        let commentDict: [String: Any] = [
            "id": comment.id,
            "userID": comment.userID,
            "userName": comment.userName,
            "text": comment.text,
            "datePosted": Timestamp(date: comment.datePosted)
        ]
        Firestore.firestore().collection("outfitPosts").document(post.id).updateData([
            "comments": FieldValue.arrayUnion([commentDict])
        ])
    }

    // MARK: - Helpers

    private func userFrom(id: String, data: [String: Any]) -> User {
        User(
            id: id,
            email: data["email"] as? String ?? "",
            displayName: data["displayName"] as? String ?? "",
            profileImageURL: data["profileImageURL"] as? String,
            phone: data["phone"] as? String,
            closetItemCount: data["closetItemCount"] as? Int ?? 0,
            sustainabilityScore: data["sustainabilityScore"] as? Int ?? 0,
            friendIDs: data["friendIDs"] as? [String] ?? [],
            blockedUserIDs: data["blockedUserIDs"] as? [String] ?? [],
            customSubcategories: data["customSubcategories"] as? [String] ?? [],
            newItemsPurchased: data["newItemsPurchased"] as? Int ?? 0,
            itemsReworn: data["itemsReworn"] as? Int ?? 0,
            tradesMade: data["tradesMade"] as? Int ?? 0,
            closetVisibility: data["closetVisibility"] as? String ?? "public"
        )
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
