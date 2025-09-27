//
//  ChangePasswordView.swift
//  DataCheck
//
//  Created by socksprox on 27.09.25.
//

import SwiftUI

struct ChangePasswordView: View {
    @ObservedObject var authService: AuthenticationService
    @ObservedObject var dataService: DataService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var passwordChangeSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text(NSLocalizedString("password_requirements", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Password Form
                VStack(spacing: 20) {
                    // New Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("new_password", comment: ""))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField(NSLocalizedString("new_password", comment: ""), text: $newPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.newPassword)
                    }
                    
                    // Confirm Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("confirm_password", comment: ""))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField(NSLocalizedString("confirm_password", comment: ""), text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.newPassword)
                    }
                }
                .padding(.horizontal, 20)
                
                // Save Button
                Button(action: changePassword) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? NSLocalizedString("changing_password", comment: "") : NSLocalizedString("save_password", comment: ""))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid && !isLoading ? Color.orange : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || isLoading)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .navigationTitle(NSLocalizedString("change_password_title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text(NSLocalizedString("ok", comment: ""))) {
                    if passwordChangeSuccess {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }
    
    private var isFormValid: Bool {
        return !newPassword.isEmpty &&
               !confirmPassword.isEmpty &&
               newPassword.count >= 8 &&
               newPassword == confirmPassword
    }
    
    private func changePassword() {
        guard validateForm() else { return }
        
        isLoading = true
        
        Task {
            await performPasswordChange()
        }
    }
    
    private func validateForm() -> Bool {
        if newPassword.isEmpty {
            showAlert(title: NSLocalizedString("error", comment: ""), 
                     message: NSLocalizedString("new_password_required", comment: ""))
            return false
        }
        
        if confirmPassword.isEmpty {
            showAlert(title: NSLocalizedString("error", comment: ""), 
                     message: NSLocalizedString("confirm_password_required", comment: ""))
            return false
        }
        
        if newPassword.count < 8 {
            showAlert(title: NSLocalizedString("error", comment: ""), 
                     message: NSLocalizedString("password_too_short", comment: ""))
            return false
        }
        
        if newPassword != confirmPassword {
            showAlert(title: NSLocalizedString("error", comment: ""), 
                     message: NSLocalizedString("passwords_do_not_match", comment: ""))
            return false
        }
        
        return true
    }
    
    @MainActor
    private func performPasswordChange() async {
        guard let token = authService.getAccessToken() else {
            isLoading = false
            showAlert(title: NSLocalizedString("error", comment: ""), 
                     message: NSLocalizedString("password_change_failed", comment: ""))
            return
        }
        
        let success = await dataService.updatePassword(
            accessToken: token,
            currentPassword: "", // Not needed for API
            newPassword: newPassword
        )
        
        isLoading = false
        
        if success {
            passwordChangeSuccess = true
            showAlert(title: NSLocalizedString("change_password_title", comment: ""), 
                     message: NSLocalizedString("password_changed_successfully", comment: ""))
        } else {
            showAlert(title: NSLocalizedString("error", comment: ""), 
                     message: NSLocalizedString("password_change_failed", comment: ""))
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

#Preview {
    ChangePasswordView(authService: AuthenticationService(), dataService: DataService())
}
