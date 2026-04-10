//
//  OutfitsView.swift
//  ClosetGenius
//

import SwiftUI

struct OutfitsView: View {
    @StateObject private var viewModel = OutfitViewModel()
    @StateObject private var closetViewModel = ClosetViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab: OutfitTab = .outfits
    @State private var showingBuilderPicker = false
    @State private var navigateToSwipe = false
    @State private var navigateToFit = false

    enum OutfitTab: String, CaseIterable {
        case outfits = "My Outfits"
        case calendar = "Calendar"
        case collections = "Collections"

        var icon: String {
            switch self {
            case .outfits:     return "rectangle.3.group.fill"
            case .calendar:    return "calendar"
            case .collections: return "folder.fill"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab picker
                HStack(spacing: 0) {
                    ForEach(OutfitTab.allCases, id: \.self) { tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.caption)
                                Text(tab.rawValue)
                                    .font(.caption2)
                                    .fontWeight(selectedTab == tab ? .semibold : .regular)
                            }
                            .foregroundColor(selectedTab == tab ? themeManager.currentTheme.color : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .overlay(alignment: .bottom) {
                                if selectedTab == tab {
                                    Rectangle()
                                        .fill(themeManager.currentTheme.color)
                                        .frame(height: 2)
                                }
                            }
                        }
                    }
                }
                .background(Color(.systemBackground))

                Divider()

                // Tab content
                Group {
                    switch selectedTab {
                    case .outfits:
                        outfitsGrid
                    case .calendar:
                        OutfitCalendarView(viewModel: viewModel, closetItems: closetViewModel.items)
                    case .collections:
                        CollectionsView(viewModel: viewModel, closetItems: closetViewModel.items)
                    }
                }
            }
            .navigationTitle("Outfits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingBuilderPicker = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.currentTheme.color)
                            .font(.title3)
                    }
                }
            }
            .background(
                Group {
                    NavigationLink(destination: SwipeBuilderView(), isActive: $navigateToSwipe) { EmptyView() }
                    NavigationLink(destination: FitBuilderView(), isActive: $navigateToFit) { EmptyView() }
                }
            )
            .confirmationDialog("Create Outfit", isPresented: $showingBuilderPicker, titleVisibility: .visible) {
                Button("Mix & Match") { navigateToSwipe = true }
                Button("Fit Builder") { navigateToFit = true }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Choose how you want to build your outfit")
            }
            .onAppear {
                viewModel.loadOutfits()
                viewModel.loadCollections()
                closetViewModel.loadItems()
            }
        }
    }

    private var outfitsGrid: some View {
        Group {
            if viewModel.isLoading {
                CGLoadingView(message: "Loading your outfits...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.outfits.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach(viewModel.outfits) { outfit in
                            OutfitCard(outfit: outfit, viewModel: viewModel, closetItems: closetViewModel.items)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(themeManager.currentTheme.color.opacity(0.08))
                    .frame(width: 120, height: 120)
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 44))
                    .foregroundColor(themeManager.currentTheme.color.opacity(0.5))
            }
            VStack(spacing: 6) {
                Text("No outfits yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Create your first outfit two ways:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                NavigationLink(destination: SwipeBuilderView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "hand.draw.fill")
                            .font(.title3)
                            .foregroundColor(themeManager.currentTheme.color)
                            .frame(width: 44, height: 44)
                            .background(themeManager.currentTheme.color.opacity(0.1))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mix & Match")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Swipe rows to combine items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                }

                NavigationLink(destination: FitBuilderView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "figure.stand")
                            .font(.title3)
                            .foregroundColor(themeManager.currentTheme.color)
                            .frame(width: 44, height: 44)
                            .background(themeManager.currentTheme.color.opacity(0.1))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fit Builder")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Assign items to body zones")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

// MARK: - Outfit Card

struct OutfitCard: View {
    let outfit: Outfit
    @ObservedObject var viewModel: OutfitViewModel
    let closetItems: [ClothingItem]
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingDeleteConfirmation = false

    private var outfitPieces: [ClothingItem] {
        outfit.itemIDs.compactMap { id in closetItems.first { $0.id == id } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image grid
            let pieces = Array(outfitPieces.prefix(4))
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.lightBackground)
                    .frame(height: 160)

                if pieces.isEmpty {
                    Image(systemName: "rectangle.3.group.fill")
                        .font(.largeTitle)
                        .foregroundColor(themeManager.currentTheme.color.opacity(0.3))
                } else if pieces.count == 1 {
                    singleImage(pieces[0])
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                        ForEach(pieces) { item in
                            itemThumbnail(item, height: pieces.count <= 2 ? 158 : 76)
                        }
                    }
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .frame(height: 160)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(outfit.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                if !outfit.occasion.isEmpty {
                    Text(outfit.occasion)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(themeManager.currentTheme.color.opacity(0.1))
                        .cornerRadius(6)
                }

                HStack {
                    Label("\(outfit.wearCount)x", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        viewModel.incrementWearCount(for: outfit)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.currentTheme.color)
                    }
                }
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 3)
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Outfit?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { viewModel.deleteOutfit(outfit) }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    @ViewBuilder
    private func singleImage(_ item: ClothingItem) -> some View {
        if let urlString = item.imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                if case .success(let img) = phase {
                    img.resizable().scaledToFill()
                } else {
                    Color(themeManager.currentTheme.lightBackground)
                }
            }
            .frame(height: 160)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private func itemThumbnail(_ item: ClothingItem, height: CGFloat) -> some View {
        if let urlString = item.imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                if case .success(let img) = phase {
                    img.resizable().scaledToFill()
                } else {
                    Color(themeManager.currentTheme.lightBackground)
                }
            }
            .frame(height: height)
            .clipped()
        } else {
            Color(themeManager.currentTheme.lightBackground)
                .frame(height: height)
        }
    }
}
