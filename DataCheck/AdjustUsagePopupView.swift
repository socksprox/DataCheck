//
//  AdjustUsagePopupView.swift
//  DataCheck
//
//  Created by socksprox on 27.09.25.
//

import SwiftUI
import UIKit

struct AdjustUsagePopupView: View {
    @ObservedObject var authService: AuthenticationService
    @ObservedObject var dataService: DataService
    @Binding var isPresented: Bool
    
    @State private var selectedAmount: Double = 5.0
    @State private var displayAmount: Double = 5.0
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var lastHapticValue: Double = 5.0
    
    let minAmount: Double = 1.0
    let maxAmount: Double = 100.0
    let step: Double = 1.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header with icon
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(spacing: 8) {
                        Text(NSLocalizedString("adjust_usage_limit", comment: ""))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(NSLocalizedString("add_credit_description", comment: ""))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                // Amount selection card
                VStack(spacing: 20) {
                    // Selected amount display
                    VStack(spacing: 8) {
                        Text(NSLocalizedString("amount_to_add", comment: ""))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("€\(displayAmount, specifier: "%.0f")")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    
                    // Slider
                    VStack(spacing: 12) {
                        HStack {
                            Text("€\(minAmount, specifier: "%.0f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(
                                value: $selectedAmount,
                                in: minAmount...maxAmount,
                                step: step
                            )
                            .accentColor(.blue)
                            .onChange(of: selectedAmount) { oldValue, newValue in
                                displayAmount = newValue
                                
                                // Haptic feedback on value change (throttled)
                                if abs(newValue - lastHapticValue) >= 1.0 {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    lastHapticValue = newValue
                                }
                            }
                            
                            Text("€\(maxAmount, specifier: "%.0f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Quick amount buttons
                        HStack(spacing: 12) {
                            ForEach([10, 25, 50, 100], id: \.self) { amount in
                                Button(action: {
                                    selectedAmount = Double(amount)
                                    displayAmount = Double(amount)
                                    lastHapticValue = Double(amount)
                                    
                                    // Haptic feedback for button selection
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                }) {
                                    Text("€\(amount)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(selectedAmount == Double(amount) ? .white : .blue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedAmount == Double(amount) ? .blue : .blue.opacity(0.1))
                                        )
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.1), radius: 8, x: 0, y: 2)
                )
                
                // Info section
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("payment_info_title", comment: ""))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("payment_info_description", comment: ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
                
                Spacer()
                
                // Action button
                Button(action: {
                    addCredit()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        Text(isLoading ? NSLocalizedString("processing", comment: "") : NSLocalizedString("confirm", comment: ""))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isLoading)
            }
            .padding(24)
            .navigationTitle(NSLocalizedString("add_credit", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .disabled(isLoading)
                }
            }
        }
        .alert(NSLocalizedString("error", comment: ""), isPresented: $showingError) {
            Button(NSLocalizedString("ok", comment: "")) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func addCredit() {
        guard let token = authService.getAccessToken(),
              let customer = dataService.customerData,
              let subscriptionGroup = customer.subscriptionGroups.first,
              let msisdn = subscriptionGroup.msisdns.first else {
            errorMessage = NSLocalizedString("authentication_error", comment: "")
            showingError = true
            return
        }
        
        isLoading = true
        
        Task {
            let success = await dataService.updateOutsideBundleCeiling(
                accessToken: token,
                subscriptionId: msisdn.id,
                amount: Int(selectedAmount)
            )
            
            await MainActor.run {
                isLoading = false
                
                if success {
                    isPresented = false
                    // The DataService will handle opening the payment URL
                } else {
                    errorMessage = NSLocalizedString("add_credit_failed", comment: "")
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    AdjustUsagePopupView(
        authService: AuthenticationService(),
        dataService: DataService(),
        isPresented: .constant(true)
    )
}
