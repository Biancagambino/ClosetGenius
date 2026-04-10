//
//  CGLoadingView.swift
//  ClosetGenius
//
//  Drop-in replacement for ProgressView throughout the app.
//  Shows the ClosetGenius logo with a gentle pulse + shimmer.
//

import SwiftUI

struct CGLoadingView: View {
    var message: String? = nil
    @State private var pulse = false
    @State private var shimmer = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                // Glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.4), Color.teal.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 88, height: 88)
                    .scaleEffect(pulse ? 1.15 : 1.0)
                    .opacity(pulse ? 0.0 : 0.8)
                    .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: pulse)

                Image("CGLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 68, height: 68)
                    .scaleEffect(pulse ? 1.04 : 0.97)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
            }

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear { pulse = true }
    }
}

/// Full-screen loading overlay
struct CGLoadingOverlay: View {
    var message: String? = nil
    var body: some View {
        ZStack {
            Color(.systemBackground).opacity(0.85).ignoresSafeArea()
            CGLoadingView(message: message)
        }
    }
}

/// Inline loading (replaces ProgressView in lists/cards)
struct CGLoadingInline: View {
    @State private var pulse = false
    var body: some View {
        Image("CGLogo")
            .resizable().scaledToFit()
            .frame(width: 28, height: 28)
            .scaleEffect(pulse ? 1.1 : 0.9)
            .opacity(pulse ? 1.0 : 0.5)
            .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: pulse)
            .onAppear { pulse = true }
    }
}
