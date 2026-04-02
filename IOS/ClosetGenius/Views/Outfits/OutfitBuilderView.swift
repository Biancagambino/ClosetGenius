//
//  OutfitBuilderView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI

struct OutfitBuilderView: View {
    @StateObject private var closetViewModel = ClosetViewModel()
    @StateObject private var outfitViewModel = OutfitViewModel()
    @State private var selectedItems: [ClothingItem] = []
    @State private var outfitName = ""
    @State private var outfitOccasion = ""
    @State private var showingSaveAlert = false
    @State private var showingFilters = false
    
    // Smart filters
    @State private var filterColor: ClothingItem.ClothingColor? = nil
    @State private var filterCategory: ClothingItem.ClothingCategory? = nil
    @State private var filterFormality: ClothingItem.Formality? = nil
    @State private var filterStyle: ClothingItem.ClothingStyle? = nil
    @State private var filterSeason: ClothingItem.Season? = nil
    @State private var filterCustomTag: String? = nil
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var allCustomTags: [String] {
        Array(Set(closetViewModel.items.flatMap { $0.customTags })).sorted()
    }
    
    private var selectedItemPlaceholder: some View {
        Rectangle()
            .fill(themeManager.currentTheme.lightBackground)
            .overlay(
                Image(systemName: "tshirt.fill")
                    .foregroundColor(themeManager.currentTheme.color.opacity(0.4))
            )
    }

    var filteredItems: [ClothingItem] {
        var items = closetViewModel.items
        
        if let color = filterColor {
            items = items.filter { $0.color == color }
        }
        if let category = filterCategory {
            items = items.filter { $0.category == category }
        }
        if let formality = filterFormality {
            items = items.filter { $0.formality == formality }
        }
        if let style = filterStyle {
            items = items.filter { $0.style == style }
        }
        if let season = filterSeason {
            items = items.filter { $0.season == season }
        }
        if let tag = filterCustomTag {
            items = items.filter { $0.customTags.contains(tag) }
        }
        
        return items
    }
    
    var activeFiltersCount: Int {
        var count = 0
        if filterColor != nil { count += 1 }
        if filterCategory != nil { count += 1 }
        if filterFormality != nil { count += 1 }
        if filterStyle != nil { count += 1 }
        if filterSeason != nil { count += 1 }
        if filterCustomTag != nil { count += 1 }
        return count
    }
    
    var body: some View {
        VStack {
            // Selected items preview
            if !selectedItems.isEmpty {
                VStack(alignment: .leading) {
                    Text("Your Outfit (\(selectedItems.count) items)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(selectedItems) { item in
                                VStack(spacing: 4) {
                                    ZStack(alignment: .topTrailing) {
                                        Group {
                                            if let urlString = item.imageURL, let url = URL(string: urlString) {
                                                AsyncImage(url: url) { phase in
                                                    switch phase {
                                                    case .success(let img):
                                                        img.resizable().scaledToFill()
                                                    default:
                                                        selectedItemPlaceholder
                                                    }
                                                }
                                            } else {
                                                selectedItemPlaceholder
                                            }
                                        }
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                        Button(action: {
                                            selectedItems.removeAll { $0.id == item.id }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Color.white.opacity(0.8).clipShape(Circle()))
                                        }
                                        .padding(4)
                                    }
                                    Text(item.name)
                                        .font(.caption2)
                                        .lineLimit(1)
                                        .frame(width: 80)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 110)
                }
                .padding(.vertical)
            }
            
            // Filter section
            HStack {
                Text("Smart Filters")
                    .font(.headline)
                
                if activeFiltersCount > 0 {
                    Text("(\(activeFiltersCount) active)")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.color)
                }
                
                Spacer()
                
                Button(action: {
                    filterColor = nil
                    filterCategory = nil
                    filterFormality = nil
                    filterStyle = nil
                    filterSeason = nil
                    filterCustomTag = nil
                }) {
                    Text("Clear All")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.color)
                }
                .opacity(activeFiltersCount > 0 ? 1 : 0)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Menu {
                        Button("Clear") { filterColor = nil }
                        Divider()
                        ForEach(ClothingItem.ClothingColor.allCases, id: \.self) { color in
                            Button(color.displayName) { filterColor = color }
                        }
                    } label: {
                        FilterPill(
                            icon: "paintpalette.fill",
                            text: filterColor?.displayName ?? "Color",
                            isActive: filterColor != nil
                        )
                    }
                    
                    Menu {
                        Button("Clear") { filterCategory = nil }
                        Divider()
                        ForEach(ClothingItem.ClothingCategory.allCases, id: \.self) { category in
                            Button(category.rawValue.capitalized) { filterCategory = category }
                        }
                    } label: {
                        FilterPill(
                            icon: "tshirt.fill",
                            text: filterCategory?.rawValue.capitalized ?? "Category",
                            isActive: filterCategory != nil
                        )
                    }
                    
                    Menu {
                        Button("Clear") { filterFormality = nil }
                        Divider()
                        ForEach(ClothingItem.Formality.allCases, id: \.self) { formality in
                            Button(formality.displayName) { filterFormality = formality }
                        }
                    } label: {
                        FilterPill(
                            icon: "person.fill",
                            text: filterFormality?.displayName ?? "Formality",
                            isActive: filterFormality != nil
                        )
                    }
                    
                    Menu {
                        Button("Clear") { filterStyle = nil }
                        Divider()
                        ForEach(ClothingItem.ClothingStyle.allCases, id: \.self) { style in
                            Button(style.displayName) { filterStyle = style }
                        }
                    } label: {
                        FilterPill(
                            icon: "star.fill",
                            text: filterStyle?.displayName ?? "Style",
                            isActive: filterStyle != nil
                        )
                    }
                    
                    Menu {
                        Button("Clear") { filterSeason = nil }
                        Divider()
                        ForEach(ClothingItem.Season.allCases, id: \.self) { season in
                            Button(season.displayName) { filterSeason = season }
                        }
                    } label: {
                        FilterPill(
                            icon: "sun.max.fill",
                            text: filterSeason?.displayName ?? "Season",
                            isActive: filterSeason != nil
                        )
                    }
                    
                    // Custom tags filter
                    if !allCustomTags.isEmpty {
                        Menu {
                            Button("Clear") { filterCustomTag = nil }
                            Divider()
                            ForEach(allCustomTags, id: \.self) { tag in
                                Button(tag) { filterCustomTag = tag }
                            }
                        } label: {
                            FilterPill(
                                icon: "tag.fill",
                                text: filterCustomTag ?? "Tags",
                                isActive: filterCustomTag != nil
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            Divider()
            
            // Auto-generate button
            if activeFiltersCount >= 2 {
                Button(action: {
                    autoGenerateOutfit()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Auto-Generate Outfit")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.currentTheme.color)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            
            // Closet items to select
            Text("Select from Your Closet (\(filteredItems.count) items)")
                .font(.headline)
                .padding()
            
            if closetViewModel.isLoading {
                Spacer()
                ProgressView("Loading your closet...")
                    .tint(themeManager.currentTheme.color)
                Spacer()
            } else if closetViewModel.items.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "tshirt")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Your closet is empty")
                        .font(.headline)
                    Text("Add items to your closet first!")
                        .foregroundColor(.gray)
                }
                .padding()
            } else if filteredItems.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No items match filters")
                        .font(.headline)
                    Text("Try adjusting your filters")
                        .foregroundColor(.gray)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach(filteredItems) { item in
                            SelectableItemCard(
                                item: item,
                                isSelected: selectedItems.contains(where: { $0.id == item.id })
                            ) {
                                if selectedItems.contains(where: { $0.id == item.id }) {
                                    selectedItems.removeAll { $0.id == item.id }
                                } else {
                                    selectedItems.append(item)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Create Outfit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    showingSaveAlert = true
                }
                .disabled(selectedItems.isEmpty)
                .foregroundColor(themeManager.currentTheme.color)
            }
        }
        .alert("Save Outfit", isPresented: $showingSaveAlert) {
            TextField("Outfit Name", text: $outfitName)
            TextField("Occasion (optional)", text: $outfitOccasion)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                let newOutfit = Outfit(
                    id: UUID().uuidString,
                    name: outfitName.isEmpty ? "Untitled Outfit" : outfitName,
                    itemIDs: selectedItems.map { $0.id },
                    occasion: outfitOccasion,
                    dateCreated: Date(),
                    wearCount: 0,
                    imageURL: nil,
                    isShared: false,
                    likes: 0
                )
                outfitViewModel.saveOutfit(newOutfit)
                dismiss()
            }
        } message: {
            Text("Give your outfit a name")
        }
        .onAppear {
            if closetViewModel.items.isEmpty {
                closetViewModel.loadItems()
            }
        }
    }
    
    private func autoGenerateOutfit() {
        selectedItems.removeAll()
        
        // Try to get one item from each major category that matches filters
        let categories: [ClothingItem.ClothingCategory] = [.tops, .bottoms, .outerwear, .shoes, .accessories]
        
        for category in categories {
            if let item = filteredItems.first(where: { closetItem in
                closetItem.category == category && !selectedItems.contains(where: { $0.id == closetItem.id })
            }) {
                selectedItems.append(item)
            }
        }
    }
}

struct FilterPill: View {
    let icon: String
    let text: String
    let isActive: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.subheadline)
        }
        .foregroundColor(isActive ? .white : themeManager.currentTheme.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isActive ? themeManager.currentTheme.color : Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
}

struct SelectableItemCard: View {
    let item: ClothingItem
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    if let urlString = item.imageURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable()
                                    .scaledToFill()
                                    .frame(height: 100)
                                    .clipped()
                            default:
                                cardPlaceholder
                            }
                        }
                        .frame(height: 100)
                        .cornerRadius(8)
                    } else {
                        cardPlaceholder
                    }

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(themeManager.currentTheme.color)
                            .font(.title2)
                            .background(Color.white.opacity(0.85).clipShape(Circle()))
                            .padding(6)
                    }
                }

                Text(item.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                Text(item.formality.displayName)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var cardPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(themeManager.currentTheme.lightBackground)
            .frame(height: 100)
            .overlay(
                Image(systemName: "tshirt.fill")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.color.opacity(0.4))
            )
    }
}
