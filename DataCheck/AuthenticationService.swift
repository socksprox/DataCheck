//
//  AuthenticationService.swift
//  DataCheck
//
//  Created by socksprox on 26.09.25.
//

import Foundation
import Combine

@MainActor
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var isCheckingAuth = true
    @Published var errorMessage: String?
    
    private var accessToken: String?
    private var refreshToken: String?
    private let baseURL = "https://mijn.50plusmobiel.nl"
    private let keychain = KeychainService.shared
    
    init() {
        checkExistingAuth()
    }
    
    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Step 1: Verify login
            let verifySuccess = try await verifyLogin(username: username, password: password)
            
            if verifySuccess {
                // Step 2: Get token
                let tokenResponse = try await getToken(username: username, password: password)
                
                // Save tokens to keychain
                self.accessToken = tokenResponse.accessToken
                self.refreshToken = tokenResponse.refreshToken
                
                _ = keychain.save(key: KeychainService.Keys.accessToken, string: tokenResponse.accessToken)
                _ = keychain.save(key: KeychainService.Keys.refreshToken, string: tokenResponse.refreshToken)
                _ = keychain.save(key: KeychainService.Keys.userEmail, string: username)
                
                // Save expiry time (current time + expires_in seconds)
                let expiryTime = Date().timeIntervalSince1970 + Double(tokenResponse.expiresIn)
                _ = keychain.save(key: KeychainService.Keys.tokenExpiry, string: String(expiryTime))
                
                self.isAuthenticated = true
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func verifyLogin(username: String, password: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/verifyLogin") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application-json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://mijn.50plusmobiel.nl/", forHTTPHeaderField: "Referer")
        request.setValue("https://mijn.50plusmobiel.nl", forHTTPHeaderField: "Origin")
        
        let loginRequest = LoginRequest(
            username: username,
            phoneNumber: nil,
            password: password,
            step: "password",
            response: ""
        )
        
        request.httpBody = try JSONEncoder().encode(loginRequest)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(LoginResponse.self, from: data)
        
        if response.step == "login" {
            return true
        } else {
            throw AuthError.invalidCredentials(response.message ?? "Invalid credentials")
        }
    }
    
    private func getToken(username: String, password: String) async throws -> TokenResponse {
        guard let url = URL(string: "\(baseURL)/token/login") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("https://mijn.50plusmobiel.nl/", forHTTPHeaderField: "Referer")
        request.setValue("https://mijn.50plusmobiel.nl", forHTTPHeaderField: "Origin")
        
        let tokenRequest = TokenRequest(username: username, password: password)
        request.httpBody = try JSONEncoder().encode(tokenRequest)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }
    
    func logout() {
        isAuthenticated = false
        accessToken = nil
        refreshToken = nil
        errorMessage = nil
        
        // Clear keychain
        _ = keychain.clearAll()
    }
    
    func getAccessToken() -> String? {
        return accessToken
    }
    
    private func checkExistingAuth() {
        // Check if we have valid tokens in keychain
        guard let storedAccessToken = keychain.loadString(key: KeychainService.Keys.accessToken),
              let storedRefreshToken = keychain.loadString(key: KeychainService.Keys.refreshToken),
              let expiryString = keychain.loadString(key: KeychainService.Keys.tokenExpiry),
              let expiryTime = Double(expiryString) else {
            self.isCheckingAuth = false
            return
        }
        
        // Check if token is still valid (not expired)
        let currentTime = Date().timeIntervalSince1970
        if currentTime < expiryTime {
            // Token is still valid
            self.accessToken = storedAccessToken
            self.refreshToken = storedRefreshToken
            self.isAuthenticated = true
        } else {
            // Token expired, clear keychain
            _ = keychain.clearAll()
        }
        
        self.isCheckingAuth = false
    }
    
    func isTokenValid() -> Bool {
        guard let expiryString = keychain.loadString(key: KeychainService.Keys.tokenExpiry),
              let expiryTime = Double(expiryString) else {
            return false
        }
        
        let currentTime = Date().timeIntervalSince1970
        return currentTime < expiryTime
    }
}

enum AuthError: LocalizedError {
    case invalidURL
    case invalidCredentials(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidCredentials(let message):
            return message
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
