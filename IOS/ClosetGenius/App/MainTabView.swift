//
//  MainTabView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            ClosetView()
                .tabItem {
                    Label("Closet", systemImage: "tshirt.fill")
                }
            
            OutfitsView()
                .tabItem {
                    Label("Outfits", systemImage: "rectangle.3.group.fill")
                }
            
            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
            
            AssistantView()
                .tabItem {
                    Label("Assistant", systemImage: "sparkles")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
        }
        .accentColor(themeManager.currentTheme.color)
    }
}
