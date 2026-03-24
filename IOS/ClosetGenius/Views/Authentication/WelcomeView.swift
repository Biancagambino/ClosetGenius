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
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(themeManager.currentTheme.color).opacity(0.1).ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 80))
                        .foregroundColor(themeManager.currentTheme.color)
                    
                    Text("ClosetGenius")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.color)
                    
                    Text("Organize your wardrobe.\nBuild confidence.\nShop sustainably.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    NavigationLink(destination: SignUpView()) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.currentTheme.color)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    NavigationLink(destination: LoginView()) {
                        Text("Already have an account? Log In")
                            .foregroundColor(themeManager.currentTheme.color)
                    }
                    .padding(.bottom, 30)
                }
            }
        }
    }
}
