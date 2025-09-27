//
//  LoginView.swift
//  DataCheck
//
//  Created by socksprox on 26.09.25.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authService: AuthenticationService
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
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
                
                VStack(spacing: 40) {
                    // Logo/Header with animation
                    VStack(spacing: 20) {
                        ZStack {
                            // Background circle with subtle shadow
                            Circle()
                                .fill(Color.white)
                                .frame(width: 120, height: 120)
                                .shadow(color: .blue.opacity(0.2), radius: 20, x: 0, y: 10)
                            
                            // Icon with gradient
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
                        
                        VStack(spacing: 8) {
                            Text("DataCheck")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("Monitor your 50plusmobiel usage")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 60)
                
                // Login Form
                VStack(spacing: 24) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Email")
                                .font(.system(.headline, design: .rounded, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        TextField("Enter your email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.purple)
                                .frame(width: 20)
                            Text("Password")
                                .font(.system(.headline, design: .rounded, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            if showPassword {
                                TextField("Enter your password", text: $password)
                            } else {
                                SecureField("Enter your password", text: $password)
                            }
                            
                            Button(action: {
                                showPassword.toggle()
                            }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Error Message
                    if let errorMessage = authService.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.system(.caption, design: .rounded))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                        .multilineTextAlignment(.center)
                    }
                    
                    // Login Button
                    Button(action: {
                        Task {
                            await authService.login(username: email, password: password)
                        }
                    }) {
                        HStack(spacing: 12) {
                            if authService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.9)
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 18))
                            }
                            
                            Text(authService.isLoading ? "Signing in..." : "Sign In")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        .scaleEffect(authService.isLoading || email.isEmpty || password.isEmpty ? 0.98 : 1.0)
                    }
                    .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                    .animation(.easeInOut(duration: 0.2), value: authService.isLoading)
                    .animation(.easeInOut(duration: 0.2), value: email.isEmpty || password.isEmpty)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                }
                .navigationBarHidden(true)
            }
        }
    }
}

#Preview {
    LoginView(authService: AuthenticationService())
}
