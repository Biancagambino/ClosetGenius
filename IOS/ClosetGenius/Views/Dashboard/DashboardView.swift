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
    @State private var showingDailyPrompt = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Personalized welcome with profile picture
                    HStack(spacing: 12) {
                        ProfilePictureView(
                            imageURL: authViewModel.currentUser?.profileImageURL,
                            displayName: authViewModel.currentUser?.displayName ?? "User",
                            size: 50
                        )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Welcome to ClosetGenius")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(authViewModel.currentUser?.displayName ?? "User")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Weather widget
                    if let weather = weatherManager.currentWeather {
                        WeatherWidget(weather: weather, weatherManager: weatherManager)
                            .padding(.horizontal)
                    } else if weatherManager.isLoading {
                        HStack {
                            ProgressView()
                            Text("Loading weather...")
                                .foregroundColor(.gray)
                        }
                        .padding()
                    }
                    
                    // Daily Outfit Prompt
                    Button(action: { showingDailyPrompt = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.white)
                                    Text("Daily Outfit")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                Text("Share what you're wearing today!")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [themeManager.currentTheme.color, themeManager.currentTheme.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(radius: 3)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 15) {
                        NavigationLink(destination: ClosetView()) {
                            QuickActionCard(title: "Scan New Item", icon: "camera.fill", color: .blue)
                        }
                        NavigationLink(destination: OutfitBuilderView()) {
                            QuickActionCard(title: "Create Outfit", icon: "sparkles", color: themeManager.currentTheme.color)
                        }
                        NavigationLink(destination: TradingMarketplaceView()) {
                            QuickActionCard(title: "Browse Trades", icon: "arrow.triangle.2.circlepath", color: .green)
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Today's Outfit Suggestion")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 200)
                            .overlay(
                                Text("Outfit suggestions coming soon!")
                                    .foregroundColor(.gray)
                            )
                            .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sustainability Impact")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 20) {
                            SustainabilityCard(value: "\(authViewModel.currentUser?.itemsReworn ?? 0)", label: "Items Reworn")
                            SustainabilityCard(value: "\(authViewModel.currentUser?.tradesMade ?? 0)", label: "Trades Made")
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showingDailyPrompt) {
                DailyOutfitPromptView(isPresented: $showingDailyPrompt)
            }
            .onAppear {
                weatherManager.fetchWeather()
            }
        }
    }
}

struct WeatherWidget: View {
    let weather: WeatherData
    @ObservedObject var weatherManager: WeatherManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: weatherManager.weatherIcon())
                    .font(.system(size: 40))
                    .foregroundColor(themeManager.currentTheme.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(weather.main.temp))°F")
                        .font(.system(size: 36, weight: .bold))
                    Text(weather.weather.first?.description.capitalized ?? "")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(weather.name)
                        .font(.headline)
                    Text("Feels like \(Int(weather.main.feelsLike))°")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Weather-based suggestions
            if let season = weatherManager.suggestSeason() {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("Perfect weather for \(season.displayName.lowercased()) outfits")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
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
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct SustainabilityCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.green)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
