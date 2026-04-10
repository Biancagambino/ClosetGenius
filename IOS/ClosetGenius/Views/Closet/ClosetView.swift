//
//  ClosetView.swift
//  ClosetGenius
//

import SwiftUI

struct ClosetView: View {
    @StateObject private var viewModel = ClosetViewModel()
    @State private var showingScanner = false
    @State private var selectedFilter: ClothingItem.ClothingCategory? = nil
    @State private var searchText = ""
    @State private var selectedItem: ClothingItem? = nil
    @State private var viewStyle: ViewStyle = .grid
    @EnvironmentObject var themeManager: ThemeManager

    enum ViewStyle { case grid, rail }

    var filteredItems: [ClothingItem] {
        var result = viewModel.items
        if let filter = selectedFilter {
            result = result.filter { $0.category == filter }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.color.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                // ── Search bar ───────────────────────────────────────────
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search your closet...", text: $searchText).autocorrectionDisabled()
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 6)

                // ── Category tab rail ────────────────────────────────────
                if !viewModel.items.isEmpty {
                    categoryRail
                    Divider()
                }

                // ── Content ──────────────────────────────────────────────
                if viewModel.isLoading {
                    Spacer()
                    CGLoadingView(message: "Loading your closet...")
                    Spacer()
                } else if viewModel.items.isEmpty {
                    emptyState
                } else if filteredItems.isEmpty {
                    noResultsState
                } else {
                    // Hanging rod decoration
                    hangingRod

                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 12
                        ) {
                            ForEach(filteredItems) { item in
                                ClosetItemCard(item: item, viewModel: viewModel)
                                    .onTapGesture { selectedItem = item }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.deleteItem(item)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("My Closet")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingScanner = true }) {
                        Label("Scan", systemImage: "camera.fill")
                            .foregroundColor(themeManager.currentTheme.color)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.items.isEmpty {
                        Text("\(filteredItems.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                ScannerView(viewModel: viewModel)
            }
            .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item, viewModel: viewModel)
                    .environmentObject(themeManager)
            }
            .onAppear { viewModel.loadItems() }
        }
    }

    // MARK: - Hanging rod

    private var hangingRod: some View {
        ZStack(alignment: .top) {
            // Rod bar
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(.systemGray3), Color(.systemGray4), Color(.systemGray3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 6)
                .cornerRadius(3)
                .padding(.horizontal, 8)
                .padding(.top, 6)

            // Hangers
            HStack(spacing: 0) {
                ForEach(0..<min(filteredItems.count, 9), id: \.self) { i in
                    Spacer()
                    HangerShape()
                        .stroke(Color(.systemGray3), lineWidth: 1.5)
                        .frame(width: 18, height: 20)
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 0)
        }
        .frame(height: 30)
        .padding(.bottom, 2)
    }

    // MARK: - Category rail

    private var categoryRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                CategoryTab(title: "All", emoji: "✨", isSelected: selectedFilter == nil) {
                    withAnimation { selectedFilter = nil }
                }
                ForEach(ClothingItem.ClothingCategory.allCases, id: \.self) { cat in
                    CategoryTab(
                        title: cat.rawValue.capitalized,
                        emoji: categoryEmoji(cat),
                        isSelected: selectedFilter == cat
                    ) {
                        withAnimation { selectedFilter = cat }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func categoryEmoji(_ cat: ClothingItem.ClothingCategory) -> String {
        switch cat {
        case .tops:       return "👕"
        case .bottoms:    return "👖"
        case .outerwear:  return "🧥"
        case .dresses:    return "👗"
        case .shoes:      return "👟"
        case .accessories: return "👜"
        }
    }

    // MARK: - Empty / no results

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeManager.currentTheme.color.opacity(0.07))
                    .frame(width: 130, height: 130)
                Image(systemName: "tshirt")
                    .font(.system(size: 52))
                    .foregroundColor(themeManager.currentTheme.color.opacity(0.5))
            }
            Text("Your closet is empty")
                .font(.title3).fontWeight(.semibold)
            Text("Scan your first item to get started")
                .font(.subheadline).foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Button {
                showingScanner = true
            } label: {
                Label("Scan Item", systemImage: "camera.fill")
                    .font(.headline).foregroundColor(.white)
                    .padding(.horizontal, 28).padding(.vertical, 14)
                    .background(themeManager.currentTheme.gradient)
                    .cornerRadius(14)
            }
            Spacer()
        }
        .padding()
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40)).foregroundColor(.secondary)
            Text("No matches").font(.headline)
            Text("Try adjusting your search or filter")
                .font(.subheadline).foregroundColor(.secondary)
            Spacer()
        }
    }
}

// MARK: - Hanger Shape

struct HangerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let midX = rect.midX
        // Hook top
        p.move(to: CGPoint(x: midX, y: 0))
        p.addLine(to: CGPoint(x: midX, y: rect.height * 0.35))
        // Shoulders
        p.move(to: CGPoint(x: midX, y: rect.height * 0.35))
        p.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control1: CGPoint(x: midX + rect.width * 0.1, y: rect.height * 0.35),
            control2: CGPoint(x: rect.maxX, y: rect.height * 0.6)
        )
        p.move(to: CGPoint(x: midX, y: rect.height * 0.35))
        p.addCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control1: CGPoint(x: midX - rect.width * 0.1, y: rect.height * 0.35),
            control2: CGPoint(x: rect.minX, y: rect.height * 0.6)
        )
        // Bar
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return p
    }
}

// MARK: - Category Tab

struct CategoryTab: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji).font(.title3)
                Text(title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? themeManager.currentTheme.color : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected
                ? themeManager.currentTheme.color.opacity(0.1)
                : Color.clear
            )
            .cornerRadius(10)
            .overlay(
                isSelected
                ? RoundedRectangle(cornerRadius: 10)
                    .stroke(themeManager.currentTheme.color.opacity(0.3), lineWidth: 1)
                : nil
            )
        }
    }
}

// MARK: - Closet Item Card

struct ClosetItemCard: View {
    let item: ClothingItem
    @ObservedObject var viewModel: ClosetViewModel
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            imagePlaceholder.overlay(ProgressView().scaleEffect(0.7))
                        case .success(let image):
                            image.resizable().scaledToFill()
                                .frame(height: 120).clipped()
                        default:
                            imagePlaceholder
                        }
                    }
                    .frame(height: 120)
                } else {
                    imagePlaceholder
                }

                // Color dot
                Circle()
                    .fill(colorSwatch(for: item.color))
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    .padding(6)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                HStack {
                    Text(item.category.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        viewModel.incrementWearCount(for: item)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.currentTheme.color)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(themeManager.currentTheme.color.opacity(0.07))
            .frame(height: 120)
            .overlay(
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 28))
                    .foregroundColor(themeManager.currentTheme.color.opacity(0.25))
            )
    }

    private func colorSwatch(for color: ClothingItem.ClothingColor) -> Color {
        switch color {
        case .black:    return .black
        case .white:    return Color(white: 0.92)
        case .gray:     return .gray
        case .red:      return .red
        case .blue:     return .blue
        case .navy:     return Color(red: 0.0, green: 0.0, blue: 0.5)
        case .green:    return .green
        case .yellow:   return .yellow
        case .orange:   return .orange
        case .pink:     return .pink
        case .purple:   return .purple
        case .brown:    return .brown
        case .beige:    return Color(red: 0.96, green: 0.90, blue: 0.78)
        case .cream:    return Color(red: 1.0, green: 0.96, blue: 0.87)
        case .burgundy: return Color(red: 0.5, green: 0.0, blue: 0.13)
        case .teal:     return .teal
        }
    }
}

// MARK: - FilterButton (kept for backward compat)

struct FilterButton: View {
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
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(isSelected ? themeManager.currentTheme.color : Color.gray.opacity(0.1))
                .cornerRadius(20)
        }
    }
}
