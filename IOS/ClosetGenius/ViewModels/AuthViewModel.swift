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
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage = ""
    
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
    
    func signUp(email: String, password: String, displayName: String) {
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
                        closetItemCount: 0,
                        sustainabilityScore: 0,
                        friendIDs: [],
                        customSubcategories: [],
                        newItemsPurchased: 0,
                        itemsReworn: 0,
                        tradesMade: 0
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
    
    func refreshUserData() {
        loadUserData()
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
                        closetItemCount: data["closetItemCount"] as? Int ?? 0,
                        sustainabilityScore: data["sustainabilityScore"] as? Int ?? 0,
                        friendIDs: data["friendIDs"] as? [String] ?? [],
                        customSubcategories: data["customSubcategories"] as? [String] ?? [],
                        newItemsPurchased: data["newItemsPurchased"] as? Int ?? 0,
                        itemsReworn: data["itemsReworn"] as? Int ?? 0,
                        tradesMade: data["tradesMade"] as? Int ?? 0
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
            "closetItemCount": user.closetItemCount,
            "sustainabilityScore": user.sustainabilityScore,
            "friendIDs": user.friendIDs,
            "customSubcategories": user.customSubcategories,
            "newItemsPurchased": user.newItemsPurchased,
            "itemsReworn": user.itemsReworn,
            "tradesMade": user.tradesMade
        ]
        db.collection("users").document(user.id).setData(userData)
    }
    
    func updateProfileImage(url: String) {
        guard var user = currentUser else { return }
        user.profileImageURL = url
        currentUser = user
        saveUserData(user: user)
    }
}
