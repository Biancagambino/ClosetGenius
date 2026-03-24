//
//  TradeMarketplaceView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI

struct TradingMarketplaceView: View {
    @StateObject private var viewModel = TradingViewModel()
    @StateObject private var closetViewModel = ClosetViewModel()
    @State private var showingFriendsOnly = false
    @State private var selectedFilter: String? = nil
    @State private var showingMyListings = false
    @State private var showingCreateListing = false
    @EnvironmentObject var themeManager: ThemeManager
    
    var filteredListings: [TradeListing] {
        var listings = viewModel.tradeListings
        
        if let filter = selectedFilter {
            // TODO: Filter by category when we have clothing item details
        }
        
        if showingFriendsOnly {
            // TODO: Filter by friends when friends system is fully integrated
        }
        
        return listings
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top action buttons
            HStack {
                Button(action: { showingFriendsOnly.toggle() }) {
                    HStack {
                        Image(systemName: showingFriendsOnly ? "person.2.fill" : "person.2")
                        Text(showingFriendsOnly ? "Friends Only" : "Everyone")
                            .font(.subheadline)
                    }
                    .foregroundColor(showingFriendsOnly ? themeManager.currentTheme.color : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(showingFriendsOnly ? themeManager.currentTheme.color.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(20)
                }
                
                Spacer()
                
                Button(action: { showingMyListings = true }) {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                        Text("My Listings")
                            .font(.subheadline)
                    }
                    .foregroundColor(themeManager.currentTheme.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(themeManager.currentTheme.color.opacity(0.1))
                    .cornerRadius(20)
                }
            }
            .padding()
            
            // Category filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    CategoryFilterButton(title: "All", isSelected: selectedFilter == nil) {
                        selectedFilter = nil
                    }
                    CategoryFilterButton(title: "Tops", isSelected: selectedFilter == "Tops") {
                        selectedFilter = "Tops"
                    }
                    CategoryFilterButton(title: "Bottoms", isSelected: selectedFilter == "Bottoms") {
                        selectedFilter = "Bottoms"
                    }
                    CategoryFilterButton(title: "Dresses", isSelected: selectedFilter == "Dresses") {
                        selectedFilter = "Dresses"
                    }
                    CategoryFilterButton(title: "Outerwear", isSelected: selectedFilter == "Outerwear") {
                        selectedFilter = "Outerwear"
                    }
                    CategoryFilterButton(title: "Shoes", isSelected: selectedFilter == "Shoes") {
                        selectedFilter = "Shoes"
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
            
            // Trade items grid
            if filteredListings.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No items available")
                        .font(.headline)
                    Text("Be the first to list an item for trade!")
                        .foregroundColor(.gray)
                    
                    Button(action: { showingCreateListing = true }) {
                        Text("Create Listing")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(themeManager.currentTheme.color)
                            .cornerRadius(20)
                    }
                }
                .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach(filteredListings) { listing in
                            TradeListingCard(
                                listing: listing,
                                isWishlisted: viewModel.wishlist.contains(listing.id)
                            ) {
                                viewModel.toggleWishlist(listingId: listing.id)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Trading Marketplace")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreateListing = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(themeManager.currentTheme.color)
                }
            }
        }
        .sheet(isPresented: $showingMyListings) {
            MyListingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingCreateListing) {
            CreateListingView(closetViewModel: closetViewModel, tradingViewModel: viewModel)
        }
        .onChange(of: showingCreateListing) { _, isShowing in
            if !isShowing {
                // Reload listings when sheet is dismissed
                viewModel.loadTradeListings()
                viewModel.loadMyListings()
            }
        }
        .onAppear {
            viewModel.loadTradeListings()
            viewModel.loadMyListings()
            closetViewModel.loadItems()
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : themeManager.currentTheme.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? themeManager.currentTheme.color : Color.gray.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

struct TradeListingCard: View {
    let listing: TradeListing
    let isWishlisted: Bool
    let toggleWishlist: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 150)
                .overlay(
                    Image(systemName: "tshirt.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                )
                .overlay(
                    Button(action: toggleWishlist) {
                        Image(systemName: isWishlisted ? "heart.fill" : "heart")
                            .foregroundColor(isWishlisted ? .red : .white)
                            .padding(8)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(8),
                    alignment: .topTrailing
                )
            
            VStack(alignment: .leading, spacing: 4) {
                // Brand & Description
                if !listing.brand.isEmpty {
                    Text(listing.brand)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.color)
                        .fontWeight(.semibold)
                }
                
                Text(listing.description)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                // Size
                if !listing.size.isEmpty {
                    Text("Size: \(listing.size)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text(listing.condition.displayName)
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.color)
                    
                    Spacer()
                    
                    // Price
                    if let price = listing.price {
                        Text("$\(String(format: "%.0f", price))")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
                
                // Trade type badge
                HStack {
                    Text(listing.tradeType.displayName)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeManager.currentTheme.color)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    // Original price (if different from asking)
                    if let originalPrice = listing.originalPrice, originalPrice != listing.price {
                        Text("Orig: $\(String(format: "%.0f", originalPrice))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .strikethrough()
                    }
                }
            }
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct MyListingsView: View {
    @ObservedObject var viewModel: TradingViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.myListings.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No listings yet")
                            .font(.headline)
                        Text("Create your first trade listing!")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.myListings) { listing in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Image(systemName: "tshirt.fill")
                                                .foregroundColor(.gray)
                                        )
                                    
                                    VStack(alignment: .leading) {
                                        Text(listing.description)
                                            .font(.headline)
                                            .lineLimit(1)
                                        Text(listing.condition.displayName)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(listing.tradeType.displayName)
                                            .font(.caption)
                                            .foregroundColor(themeManager.currentTheme.color)
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                let listing = viewModel.myListings[index]
                                viewModel.deleteListing(listing)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Listings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.loadMyListings()
            }
        }
    }
}

struct CreateListingView: View {
    @ObservedObject var closetViewModel: ClosetViewModel
    @ObservedObject var tradingViewModel: TradingViewModel
    @State private var selectedItem: ClothingItem? = nil
    @State private var selectedCondition = TradeListing.ItemCondition.good
    @State private var selectedTradeType = TradeListing.TradeType.tradeOnly
    @State private var description = ""
    @State private var price = ""
    @State private var size = ""
    @State private var brand = ""
    @State private var originalPrice = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Item from Closet")) {
                    if let item = selectedItem {
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "tshirt.fill")
                                        .foregroundColor(.gray)
                                )
                            
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.headline)
                                Text(item.category.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button("Change") {
                                selectedItem = nil
                            }
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.color)
                        }
                    } else {
                        if closetViewModel.items.isEmpty {
                            Text("Add items to your closet first")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(closetViewModel.items.prefix(5)) { item in
                                Button(action: { selectedItem = item }) {
                                    HStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        
                                        Text(item.name)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Item Details")) {
                    TextField("Brand (e.g., Nike, Zara)", text: $brand)
                    TextField("Size (e.g., M, 32x30)", text: $size)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Condition & Pricing")) {
                    Picker("Condition", selection: $selectedCondition) {
                        ForEach(TradeListing.ItemCondition.allCases, id: \.self) { condition in
                            Text(condition.displayName).tag(condition)
                        }
                    }
                    
                    Picker("Trade Type", selection: $selectedTradeType) {
                        ForEach(TradeListing.TradeType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    if selectedTradeType != .tradeOnly {
                        HStack {
                            Text("$")
                            TextField("Asking Price", text: $price)
                                .keyboardType(.decimalPad)
                        }
                    }
                    
                    HStack {
                        Text("$")
                        TextField("Original Price (optional)", text: $originalPrice)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section(footer: Text("Your contact info won't be shared until you accept a trade request")) {
                    Button("Create Listing") {
                        if let item = selectedItem {
                            let priceValue = Double(price)
                            let originalPriceValue = Double(originalPrice)
                            
                            tradingViewModel.createListing(
                                item: item,
                                condition: selectedCondition,
                                tradeType: selectedTradeType,
                                description: description.isEmpty ? item.name : description,
                                price: priceValue,
                                size: size,
                                brand: brand,
                                originalPrice: originalPriceValue
                            )
                            dismiss()
                        }
                    }
                    .disabled(selectedItem == nil || size.isEmpty || brand.isEmpty)
                }
            }
            .navigationTitle("Create Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
