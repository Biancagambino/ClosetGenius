//
//  LoginView.swift
//  ClosetGenius
//
//  Created by Bianca Gambino on 1/14/26.
//


import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Login Credentials")) {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $password)
            }
            
            Section {
                Button("Log In") {
                    authViewModel.signIn(email: email, password: password)
                }
                .frame(maxWidth: .infinity)
                .disabled(email.isEmpty || password.isEmpty)
            }
            
            if !authViewModel.errorMessage.isEmpty {
                Section {
                    Text(authViewModel.errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Log In")
    }
}