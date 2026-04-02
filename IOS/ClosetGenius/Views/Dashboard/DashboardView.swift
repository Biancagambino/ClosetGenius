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
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome header
                    HStack(spacing: 14) {
                        ProfilePictureView(
                            imageURL: authViewModel.currentUser?.profileImageURL,
                            displayName: authViewModel.currentUser?.displayName ?? "User",
                            size: 52
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Good \(timeOfDayGreeting()),")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(authViewModel.currentUser?.displayName ?? "User")
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        Image(systemName: "bell")
                            .font(.title3)
                            .foregroundColor(themeManager.currentTheme.color)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Weather widget
                    if let weather = weatherManager.currentWeather {
                        WeatherWidget(weather: weather, weatherManager: weatherManager)
                            .padding(.horizontal)
                    } else if weatherManager.isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Loading weather...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }

                    // Daily outfit prompt banner
                    Button(action: { showingDailyPrompt = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "bell.badge.fill")
                                        .foregroundColor(.white)
                                    Text("Daily Outfit")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                Text("Share what you're wearing today!")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.88))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .background(themeManager.currentTheme.gradient)
                        .cornerRadius(16)
                        .shadow(color: themeManager.currentTheme.color.opacity(0.40), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)

                    // Quick actions
                    VStack(spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            NavigationLink(destination: ClosetView()) {
                                QuickActionTile(icon: "camera.fill", label: "Scan Item", color: .blue)
                            }
                            NavigationLink(destination: OutfitBuilderView()) {
                                QuickActionTile(icon: "sparkles", label: "Outfits", color: themeManager.currentTheme.color)
                            }
                            NavigationLink(destination: TradingMarketplaceView()) {
                                QuickActionTile(icon: "arrow.triangle.2.circlepath", label: "Trades", color: .green)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Outfit suggestion
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Today's Outfit Suggestion")
                                .font(.headline)
                            Spacer()
                            if !isLoadingSuggestion && !closetVM.items.isEmpty {
                                Button {
                                    fetchOutfitSuggestion()
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption)
                                        .foregroundColor(themeManager.currentTheme.color)
                                }
                            }
                        }
                        .padding(.horizontal)

                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            themeManager.currentTheme.color.opacity(0.08),
                                            themeManager.currentTheme.color.opacity(0.03)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            if isLoadingSuggestion {
                                VStack(spacing: 10) {
                                    ProgressView()
                                        .tint(themeManager.currentTheme.color)
                                    Text("Styling your outfit...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            } else if outfitSuggestion.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 28))
                                        .foregroundColor(themeManager.currentTheme.color.opacity(0.5))
                                    Text(closetVM.items.isEmpty ? "Add items to your closet first!" : "Tap refresh for a suggestion")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                            .font(.caption)
                                            .foregroundColor(themeManager.currentTheme.color)
                                        Text("AI Stylist")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(themeManager.currentTheme.color)
                                    }
                                    Text(outfitSuggestion)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding()
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Sustainability stats
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sustainability Impact")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            SustainabilityCard(
                                value: "\(authViewModel.currentUser?.itemsReworn ?? 0)",
                                label: "Items Reworn",
                                icon: "arrow.clockwise",
                                color: .green
                            )
                            SustainabilityCard(
                                value: "\(authViewModel.currentUser?.tradesMade ?? 0)",
                                label: "Trades Made",
                                icon: "arrow.triangle.2.circlepath",
                                color: .blue
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Dashboard")
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
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.07))
        .cornerRadius(14)
    }
}
