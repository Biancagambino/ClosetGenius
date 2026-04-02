//
//  MainTabView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingGenie = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView {
                DashboardView()
                    .tabItem { Label("Home", systemImage: "house.fill") }

                ClosetView()
                    .tabItem { Label("Closet", systemImage: "tshirt.fill") }

                OutfitsView()
                    .tabItem { Label("Outfits", systemImage: "rectangle.3.group.fill") }

                FriendsView()
                    .tabItem { Label("Friends", systemImage: "person.2.fill") }

                ProfileView()
                    .tabItem { Label("Profile", systemImage: "person.circle.fill") }
            }
            .accentColor(themeManager.currentTheme.color)

            // Floating Genie button
            Button {
                showingGenie = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [themeManager.currentTheme.color, themeManager.currentTheme.color.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                        .shadow(color: themeManager.currentTheme.color.opacity(0.4), radius: 8, x: 0, y: 4)

                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 82)
            .sheet(isPresented: $showingGenie) {
                AssistantView()
                    .environmentObject(themeManager)
            }
        }
    }
}
