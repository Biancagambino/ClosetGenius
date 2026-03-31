//
//  ClosetViewModel.swift
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
class ClosetViewModel: ObservableObject {
    @Published var items: [ClothingItem] = []
    @Published var isLoading = false
    
    func loadItems() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("closet")
            .getDocuments { snapshot, error in
                Task { @MainActor in
                    self.isLoading = false
                    if let documents = snapshot?.documents {
                        self.items = documents.compactMap { doc in
                            try? doc.data(as: ClothingItem.self)
                        }
                        db.collection("users").document(userId).updateData([
                            "closetItemCount": self.items.count
                        ])
                    }
                }
            }
    }
    
    func addItem(_ item: ClothingItem) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        try? db.collection("users").document(userId).collection("closet")
            .document(item.id).setData(from: item)
        
        items.append(item)
        
        db.collection("users").document(userId).updateData([
            "closetItemCount": items.count
        ])
    }
    
    func deleteItem(_ item: ClothingItem) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("closet")
            .document(item.id).delete()
        
        items.removeAll { $0.id == item.id }
        
        db.collection("users").document(userId).updateData([
            "closetItemCount": items.count
        ])
    }
    
    func incrementWearCount(for item: ClothingItem) {
        guard let userId = Auth.auth().currentUser?.uid,
              let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        
        items[index].wearCount += 1
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("closet")
            .document(item.id).updateData([
                "wearCount": items[index].wearCount
            ]) { error in
                if error == nil {
                    db.collection("users").document(userId).updateData([
                        "itemsReworn": FieldValue.increment(Int64(1))
                    ])
                }
            }
    }
    
    /// Update an item's description in Firestore (e.g., after user edits)
    func updateDescription(for item: ClothingItem, description: String) {
        guard let userId = Auth.auth().currentUser?.uid,
              let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        
        items[index].description = description
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("closet")
            .document(item.id).updateData(["description": description])
    }
}
