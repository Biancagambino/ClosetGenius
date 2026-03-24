//
//  DailyOutfitPromptView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//


import SwiftUI

struct DailyOutfitPromptView: View {
    @Binding var isPresented: Bool
    @State private var selectedOutfit: Outfit? = nil
    @State private var caption = ""
    @State private var showingOutfitPicker = false
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Fun prompt header
                VStack(spacing: 10) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 60))
                        .foregroundColor(themeManager.currentTheme.color)
                        .symbolEffect(.bounce, options: .repeat(3))
                    
                    Text("Time to share your outfit! ✨")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Show your friends what you're wearing today")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Time remaining
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(themeManager.currentTheme.color)
                    Text(timeRemaining())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                // Selected outfit preview
                if let outfit = selectedOutfit {
                    VStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.green)
                                    Text(outfit.name)
                                        .font(.headline)
                                }
                            )
                        
                        TextField("Add a caption...", text: $caption)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }
                } else {
                    Button(action: { showingOutfitPicker = true }) {
                        VStack(spacing: 15) {
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                                .fill(themeManager.currentTheme.color.opacity(0.3))
                                .frame(height: 200)
                                .overlay(
                                    VStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(themeManager.currentTheme.color)
                                        Text("Select Today's Outfit")
                                            .font(.headline)
                                            .foregroundColor(themeManager.currentTheme.color)
                                    }
                                )
                        }
                    }
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: 15) {
                    if selectedOutfit != nil {
                        Button(action: {
                            postOutfit()
                        }) {
                            Text("Post to Feed")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeManager.currentTheme.color)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Maybe Later")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Daily Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showingOutfitPicker) {
                SavedOutfitsPickerView(selectedOutfit: $selectedOutfit)
            }
        }
    }
    
    private func timeRemaining() -> String {
        let calendar = Calendar.current
        let now = Date()
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
        let timeInterval = endOfDay.timeIntervalSince(now)
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        return "Post in the next \(hours)h \(minutes)m to appear in today's feed"
    }
    
    private func postOutfit() {
        // TODO: Post to Firebase
        isPresented = false
    }
}

struct SavedOutfitsPickerView: View {
    @Binding var selectedOutfit: Outfit?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    // Mock saved outfits
    let savedOutfits = [
        Outfit(id: "1", name: "Work Casual", itemIDs: [], occasion: "Work", dateCreated: Date(), wearCount: 3, imageURL: nil, isShared: false, likes: 0),
        Outfit(id: "2", name: "Date Night", itemIDs: [], occasion: "Dinner", dateCreated: Date(), wearCount: 1, imageURL: nil, isShared: false, likes: 0),
        Outfit(id: "3", name: "Gym Fit", itemIDs: [], occasion: "Exercise", dateCreated: Date(), wearCount: 5, imageURL: nil, isShared: false, likes: 0)
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Your Saved Outfits")) {
                    ForEach(savedOutfits) { outfit in
                        Button(action: {
                            selectedOutfit = outfit
                            dismiss()
                        }) {
                            HStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "rectangle.3.group.fill")
                                            .foregroundColor(.gray)
                                    )
                                
                                VStack(alignment: .leading) {
                                    Text(outfit.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(outfit.occasion)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                if selectedOutfit?.id == outfit.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(themeManager.currentTheme.color)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    NavigationLink(destination: OutfitBuilderView()) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(themeManager.currentTheme.color)
                            Text("Create New Outfit")
                                .foregroundColor(themeManager.currentTheme.color)
                        }
                    }
                }
            }
            .navigationTitle("Select Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}