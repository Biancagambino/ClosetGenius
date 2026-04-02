//
//  AppTheme.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Codable {
    case purple = "Purple"
    case blue   = "Blue"
    case green  = "Green"
    case pink   = "Pink"
    case orange = "Orange"
    case red    = "Red"
    case teal   = "Teal"
    case indigo = "Indigo"

    var color: Color {
        switch self {
        case .purple: return Color(red: 0.54, green: 0.17, blue: 0.89)
        case .blue:   return Color(red: 0.13, green: 0.45, blue: 0.95)
        case .green:  return Color(red: 0.10, green: 0.72, blue: 0.42)
        case .pink:   return Color(red: 0.98, green: 0.27, blue: 0.58)
        case .orange: return Color(red: 1.00, green: 0.50, blue: 0.08)
        case .red:    return Color(red: 0.93, green: 0.15, blue: 0.22)
        case .teal:   return Color(red: 0.06, green: 0.70, blue: 0.65)
        case .indigo: return Color(red: 0.32, green: 0.28, blue: 0.88)
        }
    }

    /// Soft background tint for cards and section fills
    var lightBackground: Color { color.opacity(0.10) }

    /// Ready-to-use gradient for banners and buttons
    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.68)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
        }
    }

    init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .purple
        }
    }
}
