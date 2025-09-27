//
//  RootView.swift
//  DataCheck
//
//  Created by socksprox on 26.09.25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var authService = AuthenticationService()
    
    var body: some View {
        Group {
            if authService.isCheckingAuth {
                // Show loading screen while checking authentication
                SplashView()
            } else if authService.isAuthenticated {
                // Show main app if authenticated
                MainTabView(authService: authService)
            } else {
                // Show login screen if not authenticated
                LoginView(authService: authService)
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            // Background gradient matching login screen
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.05),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo matching login screen
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                        .shadow(color: .blue.opacity(0.2), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 12) {
                    Text("DataCheck")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.blue)
                }
            }
        }
    }
}

#Preview {
    RootView()
}
