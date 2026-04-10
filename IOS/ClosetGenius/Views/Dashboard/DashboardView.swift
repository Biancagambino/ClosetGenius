//
//  DashboardView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var weatherManager = WeatherManager()
    @StateObject private var closetVM = ClosetViewModel()
    @State private var showingDailyPrompt = false
    @State private var outfitSuggestion: String = ""
    @State private var isLoadingSuggestion = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Hero header ──────────────────────────────────────
                    heroHeader
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                        .padding(.bottom, 20)

                    // ── Weather + daily prompt (side by side) ────────────
                    HStack(spacing: 12) {
                        if let weather = weatherManager.currentWeather {
                            WeatherWidget(weather: weather, weatherManager: weatherManager)
                                .frame(maxWidth: .infinity)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                                .frame(height: 80)
                                .overlay(
                                    HStack(spacing: 8) {
                                        CGLoadingInline()
                                        Text("Weather…").font(.caption).foregroundColor(.secondary)
                                    }
                                )
                                .frame(maxWidth: .infinity)
                        }

                        dailyPromptCard
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 20)

                    // ── Quick actions ────────────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Quick Actions")
                            .padding(.horizontal, 18)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                NavigationLink(destination: ClosetView()) {
                                    QuickActionTile(icon: "camera.viewfinder", label: "Scan", color: .blue)
                                }
                                NavigationLink(destination: SwipeBuilderView()) {
                                    QuickActionTile(icon: "hand.draw.fill", label: "Mix & Match", color: themeManager.currentTheme.color)
                                }
                                NavigationLink(destination: FitBuilderView()) {
                                    QuickActionTile(icon: "figure.stand", label: "Fit Builder", color: .orange)
                                }
                                NavigationLink(destination: TradingMarketplaceView()) {
                                    QuickActionTile(icon: "arrow.triangle.2.circlepath", label: "Trade", color: .green)
                                }
                            }
                            .padding(.horizontal, 18)
                        }
                    }
                    .padding(.bottom, 20)

                    // ── AI Outfit suggestion ─────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            SectionHeader(title: "Today's Suggestion")
                            Spacer()
                            if !isLoadingSuggestion && !closetVM.items.isEmpty {
                                Button { fetchOutfitSuggestion() } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.currentTheme.color)
                                }
                            }
                        }
                        .padding(.horizontal, 18)

                        suggestionCard
                            .padding(.horizontal, 18)
                    }
                    .padding(.bottom, 20)

                    // ── Sustainability stats ─────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Your Impact")
                            .padding(.horizontal, 18)

                        HStack(spacing: 12) {
                            SustainabilityCard(
                                value: "\(authViewModel.currentUser?.itemsReworn ?? 0)",
                                label: "Items Reworn",
                                icon: "arrow.clockwise",
                                color: .green
                            )
                            SustainabilityCard(
                                value: "\(closetVM.items.count)",
                                label: "Items Owned",
                                icon: "tshirt.fill",
                                color: themeManager.currentTheme.color
                            )
                            SustainabilityCard(
                                value: "\(authViewModel.currentUser?.tradesMade ?? 0)",
                                label: "Trades",
                                icon: "arrow.triangle.2.circlepath",
                                color: .blue
                            )
                        }
                        .padding(.horizontal, 18)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingDailyPrompt) {
                DailyOutfitPromptView(isPresented: $showingDailyPrompt)
            }
            .onAppear {
                weatherManager.fetchWeather()
                closetVM.loadItems()
            }
            .onChange(of: closetVM.items.count) { _, count in
                if count > 0 && outfitSuggestion.isEmpty && !isLoadingSuggestion {
                    fetchOutfitSuggestion()
                }
            }
        }
    }

    // MARK: - Hero header

    private var heroHeader: some View {
        HStack(spacing: 14) {
            ProfilePictureView(
                imageURL: authViewModel.currentUser?.profileImageURL,
                displayName: authViewModel.currentUser?.displayName ?? "User",
                size: 48
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("Good \(timeOfDayGreeting()) ✨")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(authViewModel.currentUser?.displayName ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(themeManager.currentTheme.color.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "bell.fill")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.color)
            }
        }
    }

    // MARK: - Daily prompt card

    private var dailyPromptCard: some View {
        Button(action: { showingDailyPrompt = true }) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "camera.on.rectangle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                Text("Post Today's Fit")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text("Share your look")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(themeManager.currentTheme.gradient)
            .cornerRadius(16)
            .shadow(color: themeManager.currentTheme.color.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .frame(height: 80)
    }

    // MARK: - Suggestion card

    private var suggestionCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [themeManager.currentTheme.color.opacity(0.10), themeManager.currentTheme.color.opacity(0.04)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(themeManager.currentTheme.color.opacity(0.15), lineWidth: 1)
                )

            if isLoadingSuggestion {
                HStack(spacing: 10) {
                    CGLoadingInline()
                    Text("Styling your outfit…")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding()
            } else if outfitSuggestion.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 30))
                        .foregroundColor(themeManager.currentTheme.color.opacity(0.4))
                    Text(closetVM.items.isEmpty ? "Add items to your closet first!" : "Tap ↻ to get a suggestion")
                        .font(.subheadline).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption).foregroundColor(themeManager.currentTheme.color)
                        Text("Nova's Pick")
                            .font(.caption).fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.color)
                    }
                    Text(outfitSuggestion)
                        .font(.subheadline).foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
            }
        }
    }

    private func fetchOutfitSuggestion() {
        guard !closetVM.items.isEmpty else { return }
        isLoadingSuggestion = true
        outfitSuggestion = ""
        let weatherDesc = weatherManager.currentWeather.map {
            "\(Int($0.main.temp))°F, \($0.weather.first?.description ?? "")"
        } ?? ""
        let prompt = weatherDesc.isEmpty
            ? "Suggest a stylish outfit from my closet for today."
            : "The weather is \(weatherDesc). Suggest a stylish outfit from my closet."
        Task {
            do {
                let reply = try await AIClassificationService.chat(
                    message: prompt,
                    closetItems: closetVM.items
                )
                await MainActor.run {
                    outfitSuggestion = reply
                    isLoadingSuggestion = false
                }
            } catch {
                await MainActor.run {
                    isLoadingSuggestion = false
                }
            }
        }
    }

    private func timeOfDayGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
    }
}

struct WeatherWidget: View {
    let weather: WeatherData
    @ObservedObject var weatherManager: WeatherManager
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: weatherManager.weatherIcon())
                .font(.system(size: 44))
                .foregroundColor(themeManager.currentTheme.color)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(weather.main.temp))°F")
                    .font(.system(size: 34, weight: .bold))
                Text(weather.weather.first?.description.capitalized ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(weather.name)
                    .font(.headline)
                Text("Feels \(Int(weather.main.feelsLike))°")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let season = weatherManager.suggestSeason() {
                    Label(season.displayName, systemImage: "lightbulb.fill")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.color)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

struct QuickActionTile: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50)

            Text(title)
                .font(.headline)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

struct SustainabilityCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(color.opacity(0.07))
        .cornerRadius(14)
    }
}
