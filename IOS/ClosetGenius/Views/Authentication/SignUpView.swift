//
//  SignUpView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var phone = ""
    @State private var showPassword = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    themeManager.currentTheme.color,
                    themeManager.currentTheme.color.opacity(0.6),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 52))
                            .foregroundColor(.white)
                            .padding(.top, 50)

                        Text("Create Account")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)

                        Text("Your smart closet starts here")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.bottom, 36)

                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Name", systemImage: "person")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)

                            TextField("Your name", text: $displayName)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Label("Email", systemImage: "envelope")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)

                            TextField("you@example.com", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Label("Phone (optional)", systemImage: "phone")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)

                            TextField("+1 (555) 000-0000", text: $phone)
                                .keyboardType(.phonePad)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Label("Password", systemImage: "lock")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)

                            HStack {
                                if showPassword {
                                    TextField("Min. 6 characters", text: $password)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                } else {
                                    SecureField("Min. 6 characters", text: $password)
                                }
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }

                        if !authViewModel.errorMessage.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(authViewModel.errorMessage)
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                            .padding(12)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(10)
                        }

                        Button {
                            authViewModel.signUp(email: email, password: password, displayName: displayName, phone: phone)
                        } label: {
                            Text("Create Account")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    email.isEmpty || password.isEmpty || displayName.isEmpty
                                        ? Color.gray.opacity(0.35)
                                        : themeManager.currentTheme.color
                                )
                                .cornerRadius(14)
                        }
                        .disabled(email.isEmpty || password.isEmpty || displayName.isEmpty)

                        Text("By signing up you agree to our Terms & Privacy Policy")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
