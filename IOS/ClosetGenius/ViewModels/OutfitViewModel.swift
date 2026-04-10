//
//  OutfitViewModel.swift
//  ClosetGenius
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class OutfitViewModel: ObservableObject {
    @Published var outfits: [Outfit] = []
    @Published var collections: [OutfitCollection] = []
    @Published var isLoading = false

    // MARK: - Outfits

    func loadOutfits() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("outfits")
            .getDocuments { snapshot, _ in
                Task { @MainActor in
                    self.isLoading = false
                    if let documents = snapshot?.documents {
                        self.outfits = documents.compactMap { try? $0.data(as: Outfit.self) }
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

    // MARK: - Calendar

    /// Returns all outfits planned for a specific date (by day, ignoring time).
    func outfits(for date: Date) -> [Outfit] {
        let cal = Calendar.current
        return outfits.filter {
            guard let planned = $0.plannedDate else { return false }
            return cal.isDate(planned, inSameDayAs: date)
        }
    }

    /// Returns true if there is at least one outfit planned for the given date.
    func hasOutfit(on date: Date) -> Bool {
        !outfits(for: date).isEmpty
    }

    /// Assigns or re-assigns a planned date to an existing outfit.
    func setPlan(outfit: Outfit, date: Date) {
        guard let userId = Auth.auth().currentUser?.uid,
              let index = outfits.firstIndex(where: { $0.id == outfit.id }) else { return }
        outfits[index].plannedDate = date
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("outfits")
            .document(outfit.id).updateData(["plannedDate": Timestamp(date: date)])
    }

    func removePlan(outfit: Outfit) {
        guard let userId = Auth.auth().currentUser?.uid,
              let index = outfits.firstIndex(where: { $0.id == outfit.id }) else { return }
        outfits[index].plannedDate = nil
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("outfits")
            .document(outfit.id).updateData(["plannedDate": FieldValue.delete()])
    }

    // MARK: - Collections

    func loadCollections() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("outfitCollections")
            .getDocuments { snapshot, _ in
                Task { @MainActor in
                    if let documents = snapshot?.documents {
                        self.collections = documents.compactMap { try? $0.data(as: OutfitCollection.self) }
                    }
                }
            }
    }

    func createCollection(name: String, emoji: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let col = OutfitCollection(
            id: UUID().uuidString,
            name: name,
            emoji: emoji,
            outfitIDs: [],
            dateCreated: Date()
        )
        let db = Firestore.firestore()
        try? db.collection("users").document(userId).collection("outfitCollections")
            .document(col.id).setData(from: col)
        collections.append(col)
    }

    func deleteCollection(_ collection: OutfitCollection) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("outfitCollections")
            .document(collection.id).delete()
        collections.removeAll { $0.id == collection.id }
    }

    func addOutfit(_ outfit: Outfit, to collection: OutfitCollection) {
        guard let userId = Auth.auth().currentUser?.uid,
              let colIdx = collections.firstIndex(where: { $0.id == collection.id }),
              !collections[colIdx].outfitIDs.contains(outfit.id) else { return }
        collections[colIdx].outfitIDs.append(outfit.id)
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("outfitCollections")
            .document(collection.id)
            .updateData(["outfitIDs": FieldValue.arrayUnion([outfit.id])])
        // Also update the outfit's collectionIDs
        if let outIdx = outfits.firstIndex(where: { $0.id == outfit.id }) {
            outfits[outIdx].collectionIDs.append(collection.id)
            db.collection("users").document(userId).collection("outfits")
                .document(outfit.id)
                .updateData(["collectionIDs": FieldValue.arrayUnion([collection.id])])
        }
    }

    func removeOutfit(_ outfit: Outfit, from collection: OutfitCollection) {
        guard let userId = Auth.auth().currentUser?.uid,
              let colIdx = collections.firstIndex(where: { $0.id == collection.id }) else { return }
        collections[colIdx].outfitIDs.removeAll { $0 == outfit.id }
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("outfitCollections")
            .document(collection.id)
            .updateData(["outfitIDs": FieldValue.arrayRemove([outfit.id])])
    }

    func outfits(in collection: OutfitCollection) -> [Outfit] {
        outfits.filter { collection.outfitIDs.contains($0.id) }
    }
}
