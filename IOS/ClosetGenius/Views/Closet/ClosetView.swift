//
//  ClosetView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI

struct ClosetView: View {
    @StateObject private var viewModel = ClosetViewModel()
    @State private var showingScanner = false
    @State private var selectedFilter: ClothingItem.ClothingCategory? = nil
    @State private var searchText = ""
    @State private var selectedItem: ClothingItem? = nil
    @EnvironmentObject var themeManager: ThemeManager

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
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search your closet...", text: $searchText)
                        .autocorrectionDisabled()
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

                // Filter bar
                if !viewModel.items.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterButton(title: "All", isSelected: selectedFilter == nil) {
                                selectedFilter = nil
                            }
                            ForEach(ClothingItem.ClothingCategory.allCases, id: \.self) { category in
                                FilterButton(
                                    title: category.rawValue.capitalized,
                                    isSelected: selectedFilter == category
                                ) {
                                    selectedFilter = category
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    Divider()
                }

                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading your closet...")
                        .foregroundColor(.secondary)
                    Spacer()
                } else if viewModel.items.isEmpty {
                    emptyState
                } else if filteredItems.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No items match \"\(searchText)\"")
                            .font(.headline)
                        Text("Try a different search or filter")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 14
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
                        .padding(14)
                    }
                }
            }
            .navigationTitle("My Closet")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingScanner = true }) {
                        Image(systemName: "camera.fill")
                            .foregroundColor(themeManager.currentTheme.color)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.items.isEmpty {
                        Text("\(viewModel.items.count) items")
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
            .onAppear {
                viewModel.loadItems()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(themeManager.currentTheme.color.opacity(0.1))
                    .frame(width: 110, height: 110)
                Image(systemName: "tshirt")
                    .font(.system(size: 48))
                    .foregroundColor(themeManager.currentTheme.color.opacity(0.6))
            }
            Text("Your closet is empty")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Tap the camera to scan your first item")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button {
                showingScanner = true
            } label: {
                Label("Scan Item", systemImage: "camera.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(themeManager.currentTheme.color)
                    .cornerRadius(14)
            }
            .padding(.top, 8)
            Spacer()
        }
        .padding()
    }
}

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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? themeManager.currentTheme.color : Color.gray.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

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
                            imagePlaceholder.overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 160)
                                .clipped()
                        default:
                            imagePlaceholder
                        }
                    }
                    .frame(height: 160)
                } else {
                    imagePlaceholder
                }

                Circle()
                    .fill(colorSwatch(for: item.color))
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(item.category.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text("Worn \(item.wearCount)×")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.color)
                        .fontWeight(.medium)
                    Spacer()
                    Button {
                        viewModel.incrementWearCount(for: item)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.currentTheme.color)
                            .font(.system(size: 18))
                    }
                }
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 3)
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(themeManager.currentTheme.color.opacity(0.08))
            .frame(height: 160)
            .overlay(
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 36))
                    .foregroundColor(themeManager.currentTheme.color.opacity(0.3))
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
