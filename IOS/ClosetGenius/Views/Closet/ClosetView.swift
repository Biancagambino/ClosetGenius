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
    @State private var showingAllItems = false
    @EnvironmentObject var themeManager: ThemeManager
    
    var filteredItems: [ClothingItem] {
        if let filter = selectedFilter {
            return viewModel.items.filter { $0.category == filter }
        }
        return viewModel.items
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter buttons
                if !viewModel.items.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
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
                    }
                    .padding(.vertical, 8)
                }
                
                if viewModel.items.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tshirt")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Your closet is empty")
                            .font(.headline)
                        Text("Scan your first item to get started!")
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(filteredItems) { item in
                                ClosetItemCard(item: item, viewModel: viewModel)
                            }
                        }
                        .padding()
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
            }
            .sheet(isPresented: $showingScanner) {
                ScannerView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadItems()
            }
        }
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
        VStack(alignment: .leading) {
            // Show actual photo or placeholder
            if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 150)
                            .overlay(
                                ProgressView()
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    case .failure:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 150)
                            .overlay(
                                Image(systemName: "tshirt.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 150)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "tshirt.fill")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }
            
            Text(item.name)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(item.category.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                Text("Worn \(item.wearCount) times")
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.color)
                
                Spacer()
                
                Button(action: {
                    viewModel.incrementWearCount(for: item)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.color)
                }
            }
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
