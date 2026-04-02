//
//  WelcomeView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showLogin = false
    @State private var animateLogo = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        themeManager.currentTheme.color,
                        themeManager.currentTheme.color.opacity(0.75),
                        themeManager.currentTheme.color.opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Logo & branding
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.15))
                                .frame(width: 130, height: 130)
                            Circle()
                                .fill(.white.opacity(0.1))
                                .frame(width: 110, height: 110)
                            Image(systemName: "tshirt.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .scaleEffect(animateLogo ? 1.0 : 0.85)
                                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateLogo)
                        }

                        Text("ClosetGenius")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Organize your wardrobe.\nBuild confidence.\nShop sustainably.")
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.88))
                            .lineSpacing(4)
                    }

                    Spacer()

                    // Feature pills
                    HStack(spacing: 12) {
                        FeaturePill(icon: "sparkles", text: "AI Scanning")
                        FeaturePill(icon: "arrow.triangle.2.circlepath", text: "Trade")
                        FeaturePill(icon: "leaf.fill", text: "Sustainable")
                    }
                    .padding(.bottom, 36)

                    // CTA buttons
                    VStack(spacing: 14) {
                        NavigationLink(destination: SignUpView()) {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.color)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(14)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }

                        NavigationLink(destination: LoginView()) {
                            Text("Already have an account? **Log In**")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 50)
                }
            }
            .onAppear { animateLogo = true }
        }
    }
}

struct FeaturePill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.white.opacity(0.2))
        .cornerRadius(20)
    }
}
