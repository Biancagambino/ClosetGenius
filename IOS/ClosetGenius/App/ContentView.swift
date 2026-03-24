//
//  ContentView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//


import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        if authViewModel.isAuthenticated {
            MainTabView()
                .environmentObject(authViewModel)
        } else {
            WelcomeView()
                .environmentObject(authViewModel)
        }
    }
}