//
//  OutfitViewModel.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/15/26.
//


import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class OutfitViewModel: ObservableObject {
    @Published var outfits: [Outfit] = []
    @Published var isLoading = false
    
    func loadOutfits() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("outfits")
            .getDocuments { snapshot, error in
                Task { @MainActor in
                    self.isLoading = false
                    if let documents = snapshot?.documents {
                        self.outfits = documents.compactMap { doc in
                            try? doc.data(as: Outfit.self)
                        }
                    }
                }
            }
    }
    
    func saveOutfit(_ outfit: Outfit) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        try? db.collection("users").document(userId).collection("outfits")
            .document(outfit.id).setData(from: outfit)
        
        outfits.append(outfit)
    }
    
    func deleteOutfit(_ outfit: Outfit) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("outfits")
            .document(outfit.id).delete()
        
        outfits.removeAll { $0.id == outfit.id }
    }
    
    func incrementWearCount(for outfit: Outfit) {
        guard let userId = Auth.auth().currentUser?.uid,
              let index = outfits.firstIndex(where: { $0.id == outfit.id }) else { return }
        
        outfits[index].wearCount += 1
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("outfits")
            .document(outfit.id).updateData(["wearCount": outfits[index].wearCount])
    }
}