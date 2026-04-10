//
//  OutfitCalendarView.swift
//  ClosetGenius
//
//  Monthly calendar to plan future outfits and review past ones.
//  Tap a date → pick or create an outfit for that day.
//

import SwiftUI

struct OutfitCalendarView: View {
    @ObservedObject var viewModel: OutfitViewModel
    let closetItems: [ClothingItem]

    @State private var displayedMonth = Date()
    @State private var selectedDate: Date? = nil
    @State private var showingDaySheet = false
    @State private var showingBuilderPicker = false
    @State private var navigateToSwipe = false
    @State private var navigateToFit = false

    @EnvironmentObject var themeManager: ThemeManager

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let dayLabels = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    var body: some View {
        VStack(spacing: 0) {

            // ── Month nav ─────────────────────────────────────────────
            HStack {
                Button { shiftMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(themeManager.currentTheme.color)
                        .padding(8)
                }
                Spacer()
                Text(monthTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button { shiftMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(themeManager.currentTheme.color)
                        .padding(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 6)

            // ── Day-of-week headers ───────────────────────────────────
            HStack(spacing: 0) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)

            Divider()

            // ── Calendar grid ─────────────────────────────────────────
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(daysInGrid, id: \.self) { date in
                    if let date {
                        CalendarDayCell(
                            date: date,
                            isToday: calendar.isDateInToday(date),
                            isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                            isPast: date < calendar.startOfDay(for: Date()),
                            outfits: viewModel.outfits(for: date),
                            closetItems: closetItems
                        ) {
                            selectedDate = date
                            showingDaySheet = true
                        }
                    } else {
                        Color.clear.frame(height: 70)
                    }
                }
            }
            .padding(.horizontal, 4)

            Divider().padding(.top, 4)

            // ── Upcoming planned outfits ──────────────────────────────
            upcomingSection
        }
        .sheet(isPresented: $showingDaySheet) {
            if let date = selectedDate {
                DayOutfitSheet(
                    date: date,
                    viewModel: viewModel,
                    closetItems: closetItems
                )
                .environmentObject(themeManager)
            }
        }
    }

    // MARK: - Upcoming

    private var upcomingSection: some View {
        let upcoming = viewModel.outfits
            .filter {
                guard let pd = $0.plannedDate else { return false }
                return pd >= calendar.startOfDay(for: Date())
            }
            .sorted { ($0.plannedDate ?? Date()) < ($1.plannedDate ?? Date()) }
            .prefix(5)

        return VStack(alignment: .leading, spacing: 10) {
            Text("Upcoming")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            if upcoming.isEmpty {
                Text("No planned outfits — tap a future date to plan one")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(upcoming)) { outfit in
                            UpcomingOutfitCard(outfit: outfit, closetItems: closetItems)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
    }

    // MARK: - Helpers

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func shiftMonth(_ delta: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.2)) { displayedMonth = newMonth }
        }
    }

    /// Returns 42 optional Dates (6 weeks × 7 days) for the grid.
    private var daysInGrid: [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }

        let firstWeekday = calendar.component(.weekday, from: monthStart) - 1
        let totalDays = range.count
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in 1...totalDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let isPast: Bool
    let outfits: [Outfit]
    let closetItems: [ClothingItem]
    let onTap: () -> Void

    @EnvironmentObject var themeManager: ThemeManager
    private let calendar = Calendar.current

    var dayNumber: String {
        "\(calendar.component(.day, from: date))"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                // Day number
                ZStack {
                    if isToday {
                        Circle()
                            .fill(themeManager.currentTheme.color)
                            .frame(width: 28, height: 28)
                    } else if isSelected {
                        Circle()
                            .stroke(themeManager.currentTheme.color, lineWidth: 1.5)
                            .frame(width: 28, height: 28)
                    }
                    Text(dayNumber)
                        .font(.system(size: 13, weight: isToday ? .bold : .regular))
                        .foregroundColor(isToday ? .white : isPast ? .secondary : .primary)
                }

                // Outfit thumbnail or dot
                if let outfit = outfits.first {
                    outfitThumbnail(outfit)
                } else {
                    Color.clear.frame(height: 32)
                }
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func outfitThumbnail(_ outfit: Outfit) -> some View {
        let item = outfit.itemIDs.compactMap { id in closetItems.first { $0.id == id } }.first
        if let item, let urlString = item.imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                if case .success(let img) = phase {
                    img.resizable().scaledToFill()
                } else {
                    Color(themeManager.currentTheme.lightBackground)
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(themeManager.currentTheme.color.opacity(0.4), lineWidth: 1))
        } else {
            Circle()
                .fill(themeManager.currentTheme.color.opacity(0.6))
                .frame(width: 6, height: 6)
        }
    }
}

// MARK: - Upcoming Outfit Card

struct UpcomingOutfitCard: View {
    let outfit: Outfit
    let closetItems: [ClothingItem]
    @EnvironmentObject var themeManager: ThemeManager

    private var firstItem: ClothingItem? {
        outfit.itemIDs.compactMap { id in closetItems.first { $0.id == id } }.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let item = firstItem, let urlString = item.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFill()
                    } else {
                        Color(themeManager.currentTheme.lightBackground)
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.currentTheme.lightBackground)
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "tshirt.fill")
                        .foregroundColor(themeManager.currentTheme.color.opacity(0.3)))
            }

            Text(outfit.name)
                .font(.caption2).fontWeight(.semibold).lineLimit(1)
                .frame(width: 80)

            if let pd = outfit.plannedDate {
                Text(pd, style: .date)
                    .font(.caption2).foregroundColor(themeManager.currentTheme.color)
                    .frame(width: 80)
            }
        }
    }
}

// MARK: - Day Outfit Sheet

struct DayOutfitSheet: View {
    let date: Date
    @ObservedObject var viewModel: OutfitViewModel
    let closetItems: [ClothingItem]
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingBuilderPicker = false
    @State private var navigateToSwipe = false
    @State private var navigateToFit = false

    private let calendar = Calendar.current
    private var plannedOutfits: [Outfit] { viewModel.outfits(for: date) }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                // Date header
                VStack(spacing: 4) {
                    Text(date, style: .date)
                        .font(.title2).fontWeight(.bold)
                    if calendar.isDateInToday(date) {
                        Text("Today")
                            .font(.caption).foregroundColor(themeManager.currentTheme.color)
                    } else if date < Date() {
                        Text("Past")
                            .font(.caption).foregroundColor(.secondary)
                    } else {
                        Text("Planned")
                            .font(.caption).foregroundColor(.green)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 16)

                Divider()

                if plannedOutfits.isEmpty {
                    // Empty state — offer to create
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(themeManager.currentTheme.color.opacity(0.4))
                        Text("No outfit planned")
                            .font(.headline)
                        Text("Create one now or pick from your saved outfits")
                            .font(.subheadline).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)

                        Button {
                            showingBuilderPicker = true
                        } label: {
                            Label("Create Outfit", systemImage: "plus.circle.fill")
                                .font(.headline).foregroundColor(.white)
                                .padding(.horizontal, 28).padding(.vertical, 14)
                                .background(themeManager.currentTheme.gradient)
                                .cornerRadius(14)
                        }

                        // Pick from saved outfits
                        let unplanned = viewModel.outfits.filter { $0.plannedDate == nil }
                        if !unplanned.isEmpty {
                            Text("Or pick a saved outfit:")
                                .font(.subheadline).foregroundColor(.secondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(unplanned) { outfit in
                                        Button {
                                            viewModel.setPlan(outfit: outfit, date: date)
                                            dismiss()
                                        } label: {
                                            savedOutfitPill(outfit)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        Spacer()
                    }
                } else {
                    // Show planned outfits
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(plannedOutfits) { outfit in
                                PlannedOutfitRow(outfit: outfit, closetItems: closetItems) {
                                    viewModel.removePlan(outfit: outfit)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.currentTheme.color)
                }
            }
            .background(
                NavigationLink(destination: SwipeBuilderView(), isActive: $navigateToSwipe) { EmptyView() }
            )
            .confirmationDialog("Create Outfit", isPresented: $showingBuilderPicker, titleVisibility: .visible) {
                Button("Mix & Match") { navigateToSwipe = true }
                Button("Fit Builder") { navigateToFit = true }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func savedOutfitPill(_ outfit: Outfit) -> some View {
        let item = outfit.itemIDs.compactMap { id in closetItems.first { $0.id == id } }.first
        return VStack(spacing: 4) {
            if let item, let urlString = item.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFill()
                    } else { Color(themeManager.currentTheme.lightBackground) }
                }
                .frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.currentTheme.lightBackground)
                    .frame(width: 64, height: 64)
            }
            Text(outfit.name).font(.caption2).lineLimit(1).frame(width: 64)
        }
    }
}

// MARK: - Planned Outfit Row

struct PlannedOutfitRow: View {
    let outfit: Outfit
    let closetItems: [ClothingItem]
    let onRemove: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    private var pieces: [ClothingItem] {
        outfit.itemIDs.compactMap { id in closetItems.first { $0.id == id } }.prefix(3).map { $0 }
    }

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 2) {
                ForEach(pieces) { item in
                    if let urlString = item.imageURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().scaledToFill()
                            } else { Color(themeManager.currentTheme.lightBackground) }
                        }
                        .frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(outfit.name).font(.subheadline).fontWeight(.semibold)
                if !outfit.occasion.isEmpty {
                    Text(outfit.occasion).font(.caption).foregroundColor(themeManager.currentTheme.color)
                }
            }

            Spacer()

            Button {
                withAnimation { onRemove() }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
