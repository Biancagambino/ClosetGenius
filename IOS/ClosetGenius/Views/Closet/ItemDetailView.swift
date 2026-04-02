//
//  ItemDetailView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI

struct ItemDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: ClosetViewModel

    let item: ClothingItem

    @State private var name: String
    @State private var category: ClothingItem.ClothingCategory
    @State private var color: ClothingItem.ClothingColor
    @State private var pattern: ClothingItem.ClothingPattern
    @State private var season: ClothingItem.Season
    @State private var style: ClothingItem.ClothingStyle
    @State private var formality: ClothingItem.Formality
    @State private var description: String
    @State private var notes: String
    @State private var showDeleteAlert = false

    init(item: ClothingItem, viewModel: ClosetViewModel) {
        self.item = item
        self.viewModel = viewModel
        _name        = State(initialValue: item.name)
        _category    = State(initialValue: item.category)
        _color       = State(initialValue: item.color)
        _pattern     = State(initialValue: item.pattern)
        _season      = State(initialValue: item.season)
        _style       = State(initialValue: item.style)
        _formality   = State(initialValue: item.formality)
        _description = State(initialValue: item.description)
        _notes       = State(initialValue: item.notes ?? "")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Image header
                    if let imageURL = item.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 280)
                                    .clipped()
                            default:
                                imagePlaceholder
                            }
                        }
                    } else {
                        imagePlaceholder
                    }

                    // Form fields
                    VStack(spacing: 0) {
                        formSection("Basic Info") {
                            labeledField("Name") {
                                TextField("Item name", text: $name)
                            }
                            Divider().padding(.leading)
                            labeledPicker("Category", selection: $category, options: ClothingItem.ClothingCategory.allCases) { $0.rawValue.capitalized }
                            Divider().padding(.leading)
                            labeledPicker("Season", selection: $season, options: ClothingItem.Season.allCases) { $0.displayName }
                        }

                        formSection("Appearance") {
                            labeledPicker("Color", selection: $color, options: ClothingItem.ClothingColor.allCases) { $0.displayName }
                            Divider().padding(.leading)
                            labeledPicker("Pattern", selection: $pattern, options: ClothingItem.ClothingPattern.allCases) { $0.displayName }
                        }

                        formSection("Style") {
                            labeledPicker("Style", selection: $style, options: ClothingItem.ClothingStyle.allCases) { $0.displayName }
                            Divider().padding(.leading)
                            labeledPicker("Formality", selection: $formality, options: ClothingItem.Formality.allCases) { $0.displayName }
                        }

                        formSection("Details") {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("AI Description")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                    .padding(.top, 12)
                                TextEditor(text: $description)
                                    .frame(minHeight: 80)
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)
                            }
                            Divider().padding(.leading)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                    .padding(.top, 12)
                                TextEditor(text: $notes)
                                    .frame(minHeight: 60)
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)
                            }
                        }

                        // Stats
                        formSection("Stats") {
                            HStack {
                                Label("Worn \(item.wearCount) time\(item.wearCount == 1 ? "" : "s")", systemImage: "repeat")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Added \(item.dateAdded.formatted(.dateTime.month().day().year()))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }

                        // Delete button
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Delete Item", systemImage: "trash")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.08))
                                .cornerRadius(12)
                        }
                        .padding()
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationTitle(name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.color)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Delete Item", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    viewModel.deleteItem(item)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to remove \"\(item.name)\" from your closet? This can't be undone.")
            }
        }
    }

    // MARK: - Helpers

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(themeManager.currentTheme.color.opacity(0.08))
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .overlay(
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 60))
                    .foregroundColor(themeManager.currentTheme.color.opacity(0.25))
            )
    }

    private func formSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                content()
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private func labeledField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(width: 90, alignment: .leading)
            content()
                .font(.subheadline)
        }
        .padding()
    }

    private func labeledPicker<T: Hashable>(
        _ label: String,
        selection: Binding<T>,
        options: [T],
        displayName: @escaping (T) -> String
    ) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(width: 90, alignment: .leading)
            Spacer()
            Picker(label, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(displayName(option)).tag(option)
                }
            }
            .pickerStyle(.menu)
            .accentColor(themeManager.currentTheme.color)
        }
        .padding()
    }

    private func saveChanges() {
        var updated = item
        updated.name        = name.trimmingCharacters(in: .whitespaces)
        updated.category    = category
        updated.color       = color
        updated.pattern     = pattern
        updated.season      = season
        updated.style       = style
        updated.formality   = formality
        updated.description = description
        updated.notes       = notes.isEmpty ? nil : notes
        viewModel.updateItem(updated)
    }
}
