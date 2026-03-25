//
//  AssistantView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI

// MARK: - AssistantView

struct AssistantView: View {
    @StateObject private var viewModel = AssistantViewModel()
    @StateObject private var closetViewModel = ClosetViewModel()
    @EnvironmentObject var themeManager: ThemeManager

    @State private var inputText = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: Message List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Welcome message
                            WelcomeBubble()
                                .padding(.top, 16)

                            // Conversation messages
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message, themeColor: themeManager.currentTheme.color)
                                    .id(message.id)
                            }

                            // Typing indicator
                            if viewModel.isLoading {
                                TypingIndicator()
                                    .id("typing")
                            }

                            // Error banner
                            if let error = viewModel.errorMessage {
                                ErrorBanner(message: error) {
                                    viewModel.errorMessage = nil
                                }
                                .id("error")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            if let last = viewModel.messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isLoading) { loading in
                        if loading {
                            withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                        }
                    }
                }

                Divider()

                // MARK: Input Bar
                HStack(alignment: .bottom, spacing: 8) {
                    TextField("Ask about your outfits...", text: $inputText, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .focused($inputFocused)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(
                                inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? Color(.systemGray4)
                                    : themeManager.currentTheme.color
                            )
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            }
            .navigationTitle("Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.clearConversation) {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(themeManager.currentTheme.color)
                    }
                }
            }
            .onAppear {
                closetViewModel.loadItems()
            }
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        viewModel.sendMessage(text: text, closetItems: closetViewModel.items)
    }
}

// MARK: - Welcome Bubble

private struct WelcomeBubble: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.purple.gradient)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("ClosetGenius Assistant")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Text("Hi! I'm your personal stylist. Ask me anything about your closet — like \"What should I wear to a dinner date?\" or \"Put together a cozy weekend look.\"")
                    .font(.callout)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedCornerShape(radius: 16, corners: [.topRight, .bottomLeft, .bottomRight]))
            }

            Spacer(minLength: 48)
        }
    }
}

// MARK: - MessageBubble

private struct MessageBubble: View {
    let message: AIMessage
    let themeColor: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 48)
                Text(message.text)
                    .font(.callout)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(themeColor)
                    .clipShape(RoundedCornerShape(radius: 16, corners: [.topLeft, .topRight, .bottomLeft]))
            } else {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.purple.gradient)
                        .clipShape(Circle())

                    Text(message.text)
                        .font(.callout)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedCornerShape(radius: 16, corners: [.topRight, .bottomLeft, .bottomRight]))
                }
                Spacer(minLength: 48)
            }
        }
    }
}

// MARK: - TypingIndicator

private struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.purple.gradient)
                .clipShape(Circle())

            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color(.systemGray3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(phase == i ? 1.3 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.4)
                                .repeatForever()
                                .delay(Double(i) * 0.15),
                            value: phase
                        )
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedCornerShape(radius: 16, corners: [.topRight, .bottomLeft, .bottomRight]))

            Spacer(minLength: 48)
        }
        .onAppear {
            phase = 1
        }
    }
}

// MARK: - ErrorBanner

private struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(.orange)
                .lineLimit(3)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(10)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(10)
    }
}

// MARK: - RoundedCornerShape

struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
