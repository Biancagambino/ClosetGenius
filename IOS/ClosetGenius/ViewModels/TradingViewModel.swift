//
//  TradingViewModel.swift
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
class TradingViewModel: ObservableObject {
    @Published var tradeListings: [TradeListing] = []
    @Published var myListings: [TradeListing] = []
    @Published var wishlist: [String] = []
    @Published var isLoading = false
    
    func loadTradeListings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        let db = Firestore.firestore()
        
        // Load all active listings (including your own for testing)
        db.collection("tradeListings")
            .whereField("isActive", isEqualTo: true)
            .getDocuments { snapshot, error in
                Task { @MainActor in
                    self.isLoading = false
                    if let error = error {
                        print("Error loading listings: \(error)")
                    }
                    if let documents = snapshot?.documents {
                        self.tradeListings = documents.compactMap { doc in
                            try? doc.data(as: TradeListing.self)
                        }
                        print("Loaded \(self.tradeListings.count) listings")
                    }
                }
            }
    }
    
    func loadMyListings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("tradeListings")
            .whereField("ownerID", isEqualTo: userId)
            .getDocuments { snapshot, error in
                Task { @MainActor in
                    if let documents = snapshot?.documents {
                        self.myListings = documents.compactMap { doc in
                            try? doc.data(as: TradeListing.self)
                        }
                    }
                }
            }
    }
    
    func createListing(item: ClothingItem, condition: TradeListing.ItemCondition, tradeType: TradeListing.TradeType, description: String, price: Double?, size: String, brand: String, originalPrice: Double?) {
        guard let userId = Auth.auth().currentUser?.uid,
              let userName = Auth.auth().currentUser?.displayName else { return }
        
        let listing = TradeListing(
            id: UUID().uuidString,
            itemID: item.id,
            ownerID: userId,
            ownerName: userName,
            condition: condition,
            tradeType: tradeType,
            description: description,
            price: price,
            size: size,
            brand: brand,
            originalPrice: originalPrice,
            datePosted: Date(),
            isActive: true,
            viewCount: 0,
            category: item.category.rawValue
        )
        
        let db = Firestore.firestore()
        do {
            try db.collection("tradeListings").document(listing.id).setData(from: listing) { error in
                if let error = error {
                    print("Error creating listing: \(error)")
                } else {
                    Task { @MainActor in
                        self.myListings.append(listing)
                        self.tradeListings.append(listing)
                    }
                }
            }
        } catch {
            print("Error encoding listing: \(error)")
        }
    }
    
    func deleteListing(_ listing: TradeListing) {
        let db = Firestore.firestore()
        db.collection("tradeListings").document(listing.id).delete()
        
        myListings.removeAll { $0.id == listing.id }
        tradeListings.removeAll { $0.id == listing.id }
    }
    
    func toggleWishlist(listingId: String) {
        if wishlist.contains(listingId) {
            wishlist.removeAll { $0 == listingId }
        } else {
            wishlist.append(listingId)
        }
        
        // TODO: Save wishlist to Firebase
    }
}
