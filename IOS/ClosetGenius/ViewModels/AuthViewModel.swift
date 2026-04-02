//
//  AuthViewModel.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
@preconcurrency import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage = ""
    @Published var resetPasswordMessage = ""

    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            Task { @MainActor in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.isAuthenticated = true
                self.loadUserData()
            }
        }
    }

    func signUp(email: String, password: String, displayName: String, phone: String = "") {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            Task { @MainActor in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                if let userId = result?.user.uid {
                    let newUser = User(
                        id: userId,
                        email: email,
                        displayName: displayName,
                        profileImageURL: nil,
                        phone: phone.isEmpty ? nil : phone,
                        closetItemCount: 0,
                        sustainabilityScore: 0,
                        friendIDs: [],
                        blockedUserIDs: [],
                        customSubcategories: [],
                        newItemsPurchased: 0,
                        itemsReworn: 0,
                        tradesMade: 0,
                        closetVisibility: "public"
                    )
                    self.saveUserData(user: newUser)
                    self.currentUser = newUser
                    self.isAuthenticated = true
                }
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        isAuthenticated = false
        currentUser = nil
    }

    func resetPassword(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            Task { @MainActor in
                if let error = error {
                    self.resetPasswordMessage = error.localizedDescription
                } else {
                    self.resetPasswordMessage = "Password reset email sent! Check your inbox."
                }
            }
        }
    }

    func refreshUserData() {
        loadUserData()
    }

    func updateDisplayName(_ name: String) {
        guard var user = currentUser else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        user.displayName = trimmed
        currentUser = user
        let db = Firestore.firestore()
        db.collection("users").document(user.id).updateData(["displayName": trimmed])
    }

    func updateProfileImage(url: String) {
        guard var user = currentUser else { return }
        user.profileImageURL = url
        currentUser = user
        saveUserData(user: user)
    }

    func updateClosetVisibility(_ visibility: String) {
        guard var user = currentUser else { return }
        user.closetVisibility = visibility
        currentUser = user
        let db = Firestore.firestore()
        db.collection("users").document(user.id).updateData(["closetVisibility": visibility])
    }

    func blockUser(id: String) {
        guard var user = currentUser else { return }
        guard !user.blockedUserIDs.contains(id) else { return }
        user.blockedUserIDs.append(id)
        // Also remove from friends
        user.friendIDs.removeAll { $0 == id }
        currentUser = user
        let db = Firestore.firestore()
        db.collection("users").document(user.id).updateData([
            "blockedUserIDs": user.blockedUserIDs,
            "friendIDs": user.friendIDs
        ])
    }

    func unblockUser(id: String) {
        guard var user = currentUser else { return }
        user.blockedUserIDs.removeAll { $0 == id }
        currentUser = user
        let db = Firestore.firestore()
        db.collection("users").document(user.id).updateData([
            "blockedUserIDs": user.blockedUserIDs
        ])
    }

    private func loadUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            Task { @MainActor in
                if let data = snapshot?.data() {
                    self.currentUser = User(
                        id: userId,
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
        }
    }

    private func saveUserData(user: User) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "email": user.email,
            "displayName": user.displayName,
            "profileImageURL": user.profileImageURL as Any,
            "phone": user.phone as Any,
            "closetItemCount": user.closetItemCount,
            "sustainabilityScore": user.sustainabilityScore,
            "friendIDs": user.friendIDs,
            "blockedUserIDs": user.blockedUserIDs,
            "customSubcategories": user.customSubcategories,
            "newItemsPurchased": user.newItemsPurchased,
            "itemsReworn": user.itemsReworn,
            "tradesMade": user.tradesMade,
            "closetVisibility": user.closetVisibility
        ]
        db.collection("users").document(user.id).setData(userData)
    }
}
