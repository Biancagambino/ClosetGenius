//
//  ClosetGeniusApp.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/13/26.
//

import SwiftUI
import FirebaseCore

@main
struct ClosetGeniusApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
        }
    }
}
