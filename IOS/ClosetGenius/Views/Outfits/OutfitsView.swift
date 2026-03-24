//
//  OutfitsView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI

struct OutfitsView: View {
    @StateObject private var viewModel = OutfitViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.outfits.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "rectangle.3.group")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No outfits yet")
                            .font(.headline)
                        Text("Create your first outfit from your closet items!")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        NavigationLink(destination: OutfitBuilderView()) {
                            Text("Create Outfit")
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(themeManager.currentTheme.color)
                                .cornerRadius(20)
                        }
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(viewModel.outfits) { outfit in
                                OutfitCard(outfit: outfit, viewModel: viewModel)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Outfits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: OutfitBuilderView()) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.currentTheme.color)
                    }
                }
            }
            .onAppear {
                viewModel.loadOutfits()
            }
        }
    }
}

struct OutfitCard: View {
    let outfit: Outfit
    @ObservedObject var viewModel: OutfitViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 150)
                .overlay(
                    Image(systemName: "rectangle.3.group.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(outfit.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                if !outfit.occasion.isEmpty {
                    Text(outfit.occasion)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Worn \(outfit.wearCount)x")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.color)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.incrementWearCount(for: outfit)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.color)
                    }
                }
            }
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Outfit?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteOutfit(outfit)
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
