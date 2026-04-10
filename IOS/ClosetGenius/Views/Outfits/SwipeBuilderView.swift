//
//  SwipeBuilderView.swift
//  ClosetGenius
//
//  Outfit builder with swipeable category rows — swipe each row
//  independently to find the perfect combination.
//

import SwiftUI

struct SwipeBuilderView: View {
    @StateObject private var closetVM = ClosetViewModel()
    @StateObject private var outfitVM = OutfitViewModel()
    @State private var selectedIndices: [SwipeRow: Int] = [:]
    @State private var outfitName = ""
    @State private var outfitMood = ""
    @State private var showingSaveAlert = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    enum SwipeRow: String, CaseIterable, Identifiable {
        case outer  = "Jackets"
        case tops   = "Tops"
        case bottoms = "Bottoms"
        case shoes  = "Shoes"
        case accessories = "Accessories"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .outer:       return "wind"
            case .tops:        return "tshirt.fill"
            case .bottoms:     return "rectangle.fill"
            case .shoes:       return "shoe.fill"
            case .accessories: return "bag.fill"
            }
        }

        var categories: [ClothingItem.ClothingCategory] {
            switch self {
            case .outer:       return [.outerwear]
            case .tops:        return [.tops, .dresses]
            case .bottoms:     return [.bottoms]
            case .shoes:       return [.shoes]
            case .accessories: return [.accessories]
            }
        }
    }

    private func items(for row: SwipeRow) -> [ClothingItem] {
        closetVM.items.filter { row.categories.contains($0.category) }
    }

    private var selectedItems: [ClothingItem] {
        SwipeRow.allCases.compactMap { row in
            let rowItems = items(for: row)
            guard !rowItems.isEmpty else { return nil }
            let idx = selectedIndices[row] ?? 0
            return rowItems[safe: idx]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if closetVM.isLoading {
                ProgressView("Loading your closet...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Outfit preview strip
                        outfitPreviewStrip
                            .padding(.vertical, 16)
                            .background(Color(.systemGroupedBackground))

                        Divider()

                        // Swipe rows
                        VStack(spacing: 0) {
                            ForEach(SwipeRow.allCases) { row in
                                let rowItems = items(for: row)
                                if !rowItems.isEmpty {
                                    SwipeRowView(
                                        label: row.rawValue,
                                        icon: row.icon,
                                        items: rowItems,
                                        selectedIndex: Binding(
                                            get: { selectedIndices[row] ?? 0 },
                                            set: { selectedIndices[row] = $0 }
                                        )
                                    )
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                }

                // Save button
                Button {
                    showingSaveAlert = true
                } label: {
                    Text("Save This Outfit")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            selectedItems.isEmpty
                            ? Color.gray
                            : themeManager.currentTheme.gradient
                        )
                        .cornerRadius(16)
                }
                .disabled(selectedItems.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle("Mix & Match")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Save Outfit", isPresented: $showingSaveAlert) {
            TextField("Name (e.g. Sunday brunch)", text: $outfitName)
            TextField("Vibe (e.g. casual, chic, cozy)", text: $outfitMood)
            Button("Cancel", role: .cancel) { }
            Button("Save") { saveOutfit() }
        }
        .onAppear { closetVM.loadItems() }
    }

    // MARK: - Outfit preview strip

    private var outfitPreviewStrip: some View {
        VStack(spacing: 8) {
            Text("Your Combination")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(selectedItems) { item in
                        if let urlString = item.imageURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().scaledToFill()
                                } else {
                                    Color(themeManager.currentTheme.lightBackground)
                                }
                            }
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                        }
                    }

                    if selectedItems.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.draw.fill")
                                .foregroundColor(.secondary)
                            Text("Swipe rows below to build your outfit")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Save

    private func saveOutfit() {
        let outfit = Outfit(
            id: UUID().uuidString,
            name: outfitName.isEmpty ? "My Outfit" : outfitName,
            itemIDs: selectedItems.map { $0.id },
            occasion: outfitMood,
            dateCreated: Date(),
            wearCount: 0,
            imageURL: nil,
            isShared: false,
            likes: 0
        )
        outfitVM.saveOutfit(outfit)
        dismiss()
    }
}

// MARK: - Swipe Row

struct SwipeRowView: View {
    let label: String
    let icon: String
    let items: [ClothingItem]
    @Binding var selectedIndex: Int
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.color)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(selectedIndex + 1) / \(items.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            SwipeRowItemCard(
                                item: item,
                                isSelected: selectedIndex == index
                            ) {
                                withAnimation(.spring(response: 0.25)) {
                                    selectedIndex = index
                                }
                            }
                            .id(item.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .onChange(of: selectedIndex) { _, newIndex in
                    if let item = items[safe: newIndex] {
                        withAnimation {
                            proxy.scrollTo(item.id, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Swipe Row Item Card

struct SwipeRowItemCard: View {
    let item: ClothingItem
    let isSelected: Bool
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 5) {
                ZStack {
                    if let urlString = item.imageURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().scaledToFill()
                            } else {
                                Color(themeManager.currentTheme.lightBackground)
                                    .overlay(Image(systemName: "tshirt.fill")
                                        .foregroundColor(themeManager.currentTheme.color.opacity(0.3)))
                            }
                        }
                    } else {
                        Color(themeManager.currentTheme.lightBackground)
                            .overlay(Image(systemName: "tshirt.fill")
                                .foregroundColor(themeManager.currentTheme.color.opacity(0.3)))
                    }
                }
                .frame(width: isSelected ? 110 : 90, height: isSelected ? 110 : 90)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? themeManager.currentTheme.color : Color.clear, lineWidth: 2.5)
                )
                .shadow(color: isSelected ? themeManager.currentTheme.color.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                .animation(.spring(response: 0.25), value: isSelected)

                if isSelected {
                    Text(item.name)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                        .frame(width: 110)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
