//
//  SignUpView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//


import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Account Information")) {
                TextField("Display Name", text: $displayName)
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $password)
            }
            
            Section {
                Button("Create Account") {
                    authViewModel.signUp(email: email, password: password, displayName: displayName)
                }
                .frame(maxWidth: .infinity)
                .disabled(email.isEmpty || password.isEmpty || displayName.isEmpty)
            }
            
            if !authViewModel.errorMessage.isEmpty {
                Section {
                    Text(authViewModel.errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Sign Up")
    }
}