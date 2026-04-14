//
//  CollectionsView.swift
//  ClosetGenius
//
//  Outfit collections — like playlists for your looks.
//

import SwiftUI

struct CollectionsView: View {
    @ObservedObject var viewModel: OutfitViewModel
    let closetItems: [ClothingItem]
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showingCreateSheet = false
    @State private var selectedCollection: OutfitCollection? = nil

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.collections.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(viewModel.collections) { collection in
                            CollectionCard(
                                collection: collection,
                                outfits: viewModel.outfits(in: collection),
                                closetItems: closetItems
                            ) {
                                selectedCollection = collection
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.deleteCollection(collection)
                                } label: {
                                    Label("Delete Collection", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showingCreateSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(themeManager.currentTheme.gradient)
                    .clipShape(Circle())
                    .shadow(color: themeManager.currentTheme.color.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(20)
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateCollectionSheet(viewModel: viewModel)
                .environmentObject(themeManager)
        }
        .sheet(item: $selectedCollection) { collection in
            CollectionDetailView(
                collection: collection,
                viewModel: viewModel,
                closetItems: closetItems
            )
            .environmentObject(themeManager)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.currentTheme.color.opacity(0.08))
                    .frame(width: 110, height: 110)
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 44))
                    .foregroundColor(themeManager.currentTheme.color.opacity(0.5))
            }
            Text("No collections yet")
                .font(.title3).fontWeight(.semibold)
            Text("Group your outfits by vibe — Work, Weekend, Date Night…")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            Button { showingCreateSheet = true } label: {
                Label("Create Collection", systemImage: "plus.circle.fill")
                    .font(.headline).foregroundColor(.white)
                    .padding(.horizontal, 28).padding(.vertical, 14)
                    .background(themeManager.currentTheme.gradient)
                    .cornerRadius(14)
            }
            Spacer()
        }
    }
}

// MARK: - Collection Card

struct CollectionCard: View {
    let collection: OutfitCollection
    let outfits: [Outfit]
    let closetItems: [ClothingItem]
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    private var previewItems: [ClothingItem] {
        outfits.prefix(4).compactMap { outfit in
            outfit.itemIDs.compactMap { id in closetItems.first { $0.id == id } }.first
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Preview mosaic
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.currentTheme.lightBackground)
                        .frame(height: 130)

                    if previewItems.isEmpty {
                        Text(collection.emoji)
                            .font(.system(size: 48))
                    } else if previewItems.count == 1 {
                        singlePreview(previewItems[0])
                    } else {
                        mosaicPreview
                    }
                }
                .frame(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(collection.emoji).font(.subheadline)
                        Text(collection.name)
                            .font(.subheadline).fontWeight(.semibold).lineLimit(1)
                    }
                    Text("\(outfits.count) outfit\(outfits.count == 1 ? "" : "s")")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func singlePreview(_ item: ClothingItem) -> some View {
        if let urlString = item.imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                if case .success(let img) = phase {
                    img.resizable().scaledToFill()
                } else { Color(themeManager.currentTheme.lightBackground) }
            }
            .frame(height: 130).clipped()
        }
    }

    private var mosaicPreview: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
            ForEach(Array(previewItems.prefix(4))) { item in
                if let urlString = item.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else { Color(themeManager.currentTheme.lightBackground) }
                    }
                    .frame(height: previewItems.count <= 2 ? 128 : 62)
                    .clipped()
                } else {
                    Color(themeManager.currentTheme.lightBackground)
                        .frame(height: previewItems.count <= 2 ? 128 : 62)
                }
            }
        }
    }
}

// MARK: - Create Collection Sheet

struct CreateCollectionSheet: View {
    @ObservedObject var viewModel: OutfitViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var name = ""
    @State private var selectedEmoji = "👗"

    let emojiOptions = ["👗","👔","👟","🧥","👜","🌿","🌙","☀️","🎉","💼","🏖️","❄️","🌸","🔥","✨","💪"]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Emoji picker
                VStack(spacing: 12) {
                    Text(selectedEmoji).font(.system(size: 56))
                    Text("Pick an emoji").font(.caption).foregroundColor(.secondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                            } label: {
                                Text(emoji).font(.title3)
                                    .frame(width: 36, height: 36)
                                    .background(selectedEmoji == emoji
                                        ? themeManager.currentTheme.color.opacity(0.2)
                                        : Color.clear)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Collection Name").font(.subheadline).fontWeight(.semibold)
                    TextField("e.g. Weekend Vibes", text: $name)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)

                Spacer()

                Button {
                    guard !name.isEmpty else { return }
                    viewModel.createCollection(name: name, emoji: selectedEmoji)
                    dismiss()
                } label: {
                    Text("Create Collection")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(themeManager.currentTheme.gradient)
                        .opacity(name.isEmpty ? 0.5 : 1.0)
                        .cornerRadius(14)
                }
                .disabled(name.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .padding(.top, 20)
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Collection Detail View

struct CollectionDetailView: View {
    let collection: OutfitCollection
    @ObservedObject var viewModel: OutfitViewModel
    let closetItems: [ClothingItem]
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingAddSheet = false

    private var collectionOutfits: [Outfit] { viewModel.outfits(in: collection) }
    private var outfitsNotInCollection: [Outfit] {
        viewModel.outfits.filter { !collection.outfitIDs.contains($0.id) }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                if collectionOutfits.isEmpty {
                    VStack(spacing: 16) {
                        Spacer(minLength: 60)
                        Text(collection.emoji).font(.system(size: 52))
                        Text("This collection is empty")
                            .font(.headline)
                        Text("Tap + to add your saved outfits")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(collectionOutfits) { outfit in
                            OutfitCard(outfit: outfit, viewModel: viewModel, closetItems: closetItems)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.removeOutfit(outfit, from: collection)
                                    } label: {
                                        Label("Remove from Collection", systemImage: "minus.circle")
                                    }
                                }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("\(collection.emoji) \(collection.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }.foregroundColor(themeManager.currentTheme.color)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.currentTheme.color)
                    }
                    .disabled(outfitsNotInCollection.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddOutfitsToCollectionSheet(
                    collection: collection,
                    outfits: outfitsNotInCollection,
                    closetItems: closetItems,
                    viewModel: viewModel
                )
                .environmentObject(themeManager)
            }
        }
    }
}

// MARK: - Add Outfits to Collection Sheet

struct AddOutfitsToCollectionSheet: View {
    let collection: OutfitCollection
    let outfits: [Outfit]
    let closetItems: [ClothingItem]
    @ObservedObject var viewModel: OutfitViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selected: Set<String> = []

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(outfits) { outfit in
                        let isSelected = selected.contains(outfit.id)
                        PickerItemCard(
                            item: outfit.itemIDs
                                .compactMap { id in closetItems.first { $0.id == id } }
                                .first ?? ClothingItem(
                                    id: "", name: outfit.name, category: .tops, color: .black,
                                    pattern: .solid, season: .allSeason, style: .casual,
                                    formality: .casual, description: "", imageURL: nil,
                                    wearCount: 0, dateAdded: Date(), notes: nil, customTags: []
                                ),
                            isAssigned: isSelected
                        ) {
                            if isSelected { selected.remove(outfit.id) }
                            else { selected.insert(outfit.id) }
                        }
                    }
                }
                .padding(12)
            }
            .navigationTitle("Add to \(collection.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add \(selected.count > 0 ? "(\(selected.count))" : "")") {
                        for outfitID in selected {
                            if let outfit = outfits.first(where: { $0.id == outfitID }) {
                                viewModel.addOutfit(outfit, to: collection)
                            }
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(selected.isEmpty ? .secondary : themeManager.currentTheme.color)
                    .disabled(selected.isEmpty)
                }
            }
        }
    }
}
