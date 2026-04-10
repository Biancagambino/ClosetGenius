//
//  FitBuilderView.swift
//  ClosetGenius
//

import SwiftUI

// MARK: - Body Zone

enum BodyZone: String, CaseIterable, Identifiable {
    case hat    = "Hat / Headwear"
    case outer  = "Jacket / Outer"
    case top    = "Top"
    case bottom = "Bottom"
    case shoes  = "Shoes"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .hat:    return "crown.fill"
        case .outer:  return "wind"
        case .top:    return "tshirt.fill"
        case .bottom: return "rectangle.fill"
        case .shoes:  return "shoe.fill"
        }
    }

    var shortLabel: String {
        switch self {
        case .hat:    return "Hat"
        case .outer:  return "Outer"
        case .top:    return "Top"
        case .bottom: return "Bottom"
        case .shoes:  return "Shoes"
        }
    }

    var compatibleCategories: [ClothingItem.ClothingCategory] {
        switch self {
        case .hat:    return [.accessories]
        case .outer:  return [.outerwear]
        case .top:    return [.tops, .dresses]
        case .bottom: return [.bottoms, .dresses]
        case .shoes:  return [.shoes]
        }
    }
}

// MARK: - Fit Builder View

struct FitBuilderView: View {
    @StateObject private var closetVM = ClosetViewModel()
    @StateObject private var outfitVM = OutfitViewModel()
    @State private var assignedItems: [BodyZone: ClothingItem] = [:]
    @State private var selectedZone: BodyZone = .top
    @State private var outfitName = ""
    @State private var showingSaveAlert = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    var zoneItems: [ClothingItem] {
        closetVM.items.filter { selectedZone.compatibleCategories.contains($0.category) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Body canvas ──────────────────────────────────────────────
            HStack(alignment: .top, spacing: 0) {
                bodyZoneStack
                    .frame(maxWidth: .infinity)

                bodyFigure
                    .padding(.trailing, 12)
            }
            .padding(.top, 12)
            .frame(height: 420)
            .background(Color(.systemGroupedBackground))

            // ── Zone picker tabs ─────────────────────────────────────────
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BodyZone.allCases) { zone in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedZone = zone }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: zone.icon)
                                    .font(.caption2)
                                Text(zone.shortLabel)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                if assignedItems[zone] != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption2)
                                }
                            }
                            .foregroundColor(selectedZone == zone ? .white : themeManager.currentTheme.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                selectedZone == zone
                                ? themeManager.currentTheme.color
                                : themeManager.currentTheme.color.opacity(0.1)
                            )
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            Divider()

            // ── Item picker ──────────────────────────────────────────────
            if closetVM.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if zoneItems.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: selectedZone.icon)
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No \(selectedZone.shortLabel.lowercased()) items in your closet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 10
                    ) {
                        ForEach(zoneItems) { item in
                            PickerItemCard(
                                item: item,
                                isAssigned: assignedItems[selectedZone]?.id == item.id
                            ) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    if assignedItems[selectedZone]?.id == item.id {
                                        assignedItems.removeValue(forKey: selectedZone)
                                    } else {
                                        assignedItems[selectedZone] = item
                                    }
                                }
                            }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .navigationTitle("Fit Builder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Clear") {
                    withAnimation { assignedItems.removeAll() }
                }
                .foregroundColor(.secondary)
                .disabled(assignedItems.isEmpty)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { showingSaveAlert = true }
                    .fontWeight(.semibold)
                    .foregroundColor(assignedItems.isEmpty ? .secondary : themeManager.currentTheme.color)
                    .disabled(assignedItems.isEmpty)
            }
        }
        .alert("Name Your Outfit", isPresented: $showingSaveAlert) {
            TextField("e.g. Summer brunch look", text: $outfitName)
            Button("Cancel", role: .cancel) { }
            Button("Save") { saveOutfit() }
        }
        .onAppear { closetVM.loadItems() }
    }

    // MARK: - Body zone stack (left side)

    private var bodyZoneStack: some View {
        VStack(spacing: 6) {
            // Hat
            BodyZoneSlotView(
                zone: .hat, item: assignedItems[.hat],
                isSelected: selectedZone == .hat,
                width: 110, height: 52
            ) { selectedZone = .hat }

            // Outer (wider, sits behind top)
            ZStack {
                BodyZoneSlotView(
                    zone: .outer, item: assignedItems[.outer],
                    isSelected: selectedZone == .outer,
                    width: 200, height: 100
                ) { selectedZone = .outer }

                // Top overlaid inside outer
                BodyZoneSlotView(
                    zone: .top, item: assignedItems[.top],
                    isSelected: selectedZone == .top,
                    width: 155, height: 88
                ) { selectedZone = .top }
                .padding(.top, 6)
            }
            .frame(height: 100)

            // Bottom
            BodyZoneSlotView(
                zone: .bottom, item: assignedItems[.bottom],
                isSelected: selectedZone == .bottom,
                width: 155, height: 110
            ) { selectedZone = .bottom }

            // Shoes side by side
            HStack(spacing: 16) {
                ShoeSlotView(
                    item: assignedItems[.shoes],
                    isSelected: selectedZone == .shoes
                ) { selectedZone = .shoes }
                ShoeSlotView(
                    item: assignedItems[.shoes],
                    isSelected: selectedZone == .shoes
                ) { selectedZone = .shoes }
            }
        }
        .padding(.leading, 20)
    }

    // MARK: - Decorative body figure (right side)

    private var bodyFigure: some View {
        VStack(spacing: 0) {
            // Head
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 36)
            // Neck
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(width: 10, height: 8)
            // Torso
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray4))
                .frame(width: 48, height: 90)
            // Hips
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray4))
                .frame(width: 44, height: 10)
            // Legs
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray4))
                    .frame(width: 20, height: 110)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray4))
                    .frame(width: 20, height: 110)
            }
            // Feet
            HStack(spacing: 4) {
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 26, height: 12)
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 26, height: 12)
            }
        }
        .opacity(0.5)
    }

    // MARK: - Save

    private func saveOutfit() {
        let outfit = Outfit(
            id: UUID().uuidString,
            name: outfitName.isEmpty ? "My Outfit" : outfitName,
            itemIDs: assignedItems.values.map { $0.id },
            occasion: "",
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

// MARK: - Body Zone Slot

struct BodyZoneSlotView: View {
    let zone: BodyZone
    let item: ClothingItem?
    let isSelected: Bool
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected
                          ? themeManager.currentTheme.color.opacity(0.12)
                          : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? themeManager.currentTheme.color : Color(.systemGray4),
                                style: StrokeStyle(lineWidth: isSelected ? 2 : 1.5, dash: item == nil ? [6, 3] : [])
                            )
                    )

                if let item = item, let urlString = item.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .scaledToFill()
                                .frame(width: width, height: height)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        default:
                            zonePlaceholder
                        }
                    }
                } else {
                    zonePlaceholder
                }

                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "pencil.circle.fill")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.color)
                                .background(Color(.systemBackground).clipShape(Circle()))
                                .padding(5)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: width, height: height)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var zonePlaceholder: some View {
        VStack(spacing: 4) {
            Image(systemName: zone.icon)
                .font(.system(size: height > 80 ? 20 : 14))
                .foregroundColor(isSelected ? themeManager.currentTheme.color : Color(.systemGray3))
            Text(zone.shortLabel)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isSelected ? themeManager.currentTheme.color : Color(.systemGray3))
        }
    }
}

// MARK: - Shoe Slot

struct ShoeSlotView: View {
    let item: ClothingItem?
    let isSelected: Bool
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected
                          ? themeManager.currentTheme.color.opacity(0.12)
                          : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                isSelected ? themeManager.currentTheme.color : Color(.systemGray4),
                                style: StrokeStyle(lineWidth: isSelected ? 2 : 1.5, dash: item == nil ? [5, 3] : [])
                            )
                    )

                if let item = item, let urlString = item.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                                .frame(width: 64, height: 48).clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            shoePlaceholder
                        }
                    }
                } else {
                    shoePlaceholder
                }
            }
            .frame(width: 64, height: 48)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var shoePlaceholder: some View {
        Image(systemName: "shoe.fill")
            .font(.system(size: 16))
            .foregroundColor(isSelected ? themeManager.currentTheme.color : Color(.systemGray3))
    }
}

// MARK: - Picker Item Card

struct PickerItemCard: View {
    let item: ClothingItem
    let isAssigned: Bool
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                if let urlString = item.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
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

                if isAssigned {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.currentTheme.color)
                        .background(Color.white.clipShape(Circle()))
                        .padding(5)
                }
            }
            .frame(height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isAssigned ? themeManager.currentTheme.color : Color.clear, lineWidth: 2.5)
            )
            .scaleEffect(isAssigned ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
