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
    case blue = "Blue"
    case green = "Green"
    case pink = "Pink"
    case orange = "Orange"
    case red = "Red"
    case teal = "Teal"
    case indigo = "Indigo"
    
    var color: Color {
        switch self {
        case .purple: return .purple
        case .blue: return .blue
        case .green: return .green
        case .pink: return .pink
        case .orange: return .orange
        case .red: return .red
        case .teal: return .teal
        case .indigo: return .indigo
        }
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
