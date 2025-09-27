//
//  MainDashboardView.swift
//  DataCheck
//
//  Created by socksprox on 26.09.25.
//

import SwiftUI
import UIKit

struct MainDashboardView: View {
    @ObservedObject var authService: AuthenticationService
    @ObservedObject var dataService: DataService
    @State private var isDataDetailPresented = false
    @State private var isAdjustUsagePresented = false
    @State private var copied = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    if dataService.isLoading {
                        ProgressView(NSLocalizedString("loading_your_data", comment: ""))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                    } else if let customer = dataService.customerData {
                        // Account Balance
                        accountBalanceCard(customer: customer)
                        
                        // Usage Cards
                        if let subscriptionGroup = customer.subscriptionGroups.first,
                           let msisdn = subscriptionGroup.msisdns.first {
                            usageCardsView(balance: msisdn.balance, dataAssigned: msisdn.balance.dataAssigned)
                        }
                        
                        // Phone Number Info
                        if let subscriptionGroup = customer.subscriptionGroups.first,
                           let msisdn = subscriptionGroup.msisdns.first {
                            phoneInfoCard(msisdn: msisdn)
                        }
                    } else if let errorMessage = dataService.errorMessage {
                        ErrorView(message: errorMessage) {
                            Task {
                                if let token = authService.getAccessToken() {
                                    await dataService.fetchCustomerData(accessToken: token)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("datacheck", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isDataDetailPresented) {
                DataConsumptionDetailView()
                    .environmentObject(dataService)
                    .environmentObject(authService)
            }
            .sheet(isPresented: $isAdjustUsagePresented) {
                AdjustUsagePopupView(
                    authService: authService,
                    dataService: dataService,
                    isPresented: $isAdjustUsagePresented
                )
            }
        }
        .task {
            if let token = authService.getAccessToken() {
                await dataService.fetchCustomerData(accessToken: token)
            }
        }
        .refreshable {
            if let token = authService.getAccessToken() {
                await dataService.fetchCustomerData(accessToken: token)
            }
        }
    }
    
    
    private func accountBalanceCard(customer: Customer) -> some View {
        VStack(spacing: 20) {
            // Out-of-bundle usage with playful design
            if let subscriptionGroup = customer.subscriptionGroups.first,
               let msisdn = subscriptionGroup.msisdns.first {
                
                let usagePercentage = min(customer.charge / msisdn.thresholds.relevantCeiling, 1.0)
                let isOverLimit = customer.charge > msisdn.thresholds.relevantCeiling
                let statusColor: Color = {
                    if customer.charge == 0 { return .green }
                    if customer.charge > msisdn.thresholds.relevantCeiling * 0.8 { return .red }
                    return .orange
                }()
                
                VStack(spacing: 16) {
                    // Header with emoji and title
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(customer.charge == 0 ? "🎉" : (isOverLimit ? "⚠️" : "💰"))
                                    .font(.title2)
                                Text(NSLocalizedString("extra_usage", comment: ""))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            
                            Text(customer.charge == 0 ? NSLocalizedString("you_are_doing_great", comment: "") : NSLocalizedString("keep_an_eye_on_this", comment: ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            isAdjustUsagePresented = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "slider.horizontal.3")
                                Text(NSLocalizedString("adjust", comment: ""))
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.blue)
                            .cornerRadius(20)
                        }
                    }
                    
                    // Simplified spending display
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("€\(customer.charge, specifier: "%.2f")")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(statusColor)
                            
                            Text(NSLocalizedString("extra_charges_this_period", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        // Single circular progress indicator
                        ZStack {
                            Circle()
                                .stroke(Color(.systemGray5), lineWidth: 10)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: usagePercentage)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [statusColor.opacity(0.7), statusColor]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.2), value: usagePercentage)
                            
                            VStack(spacing: 2) {
                                Text("€\(msisdn.thresholds.relevantCeiling, specifier: "%.0f")")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Text(NSLocalizedString("limit", comment: ""))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Period information with improved design
                Divider()
                    .background(Color(.systemGray4))
                
                HStack(spacing: 16) {
                    // Days remaining
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "calendar")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(subscriptionGroup.remainingBeforeBill)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("days_left", comment: ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(subscriptionGroup.remainingBeforeBill <= 7 ? .orange : .green)
                                .frame(width: 8, height: 8)
                            
                            Text(subscriptionGroup.remainingBeforeBill <= 7 ? NSLocalizedString("renewing_soon", comment: "") : NSLocalizedString("active_period", comment: ""))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(subscriptionGroup.remainingBeforeBill <= 7 ? .orange : .green)
                        }
                        
                        Text(NSLocalizedString("until_next_bill", comment: ""))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    private func usageCardsView(balance: Balance, dataAssigned: Double) -> some View {
        VStack(spacing: 16) {
            // Data Usage
            UsageCard(
                title: NSLocalizedString("data", comment: ""),
                icon: "wifi",
                used: dataAssigned - balance.dataAvailable,
                total: dataAssigned,
                unit: "MB",
                percentage: Double(100 - balance.dataPercentage),
                color: .blue,
                isUnlimited: false, // Data is never unlimited in this context
                isClickable: true
            )
            .onTapGesture {
                isDataDetailPresented = true
            }
            
            // Voice Usage - Check if unlimited
            UsageCard(
                title: NSLocalizedString("voice", comment: ""),
                icon: "phone.fill",
                used: 0,
                total: 100,
                unit: "%",
                percentage: Double(100 - balance.voicePercentage),
                color: .green,
                isUnlimited: balance.voiceAvailable == nil && balance.voiceAssigned == nil && balance.voicePercentage == 100,
                isClickable: false
            )
            
            // SMS Usage - Check if unlimited
            UsageCard(
                title: NSLocalizedString("sms", comment: ""),
                icon: "message.fill",
                used: 0,
                total: 100,
                unit: "%",
                percentage: Double(100 - balance.smsPercentage),
                color: .purple,
                isUnlimited: balance.smsAvailable == nil && balance.smsAssigned == nil && balance.smsPercentage == 100,
                isClickable: false
            )
        }
    }
    
    private func phoneInfoCard(msisdn: MSISDN) -> some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 12) {
                    Text("📱")
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("your_number", comment: ""))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(NSLocalizedString("ready_to_connect", comment: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = msisdn.localizedName
                    withAnimation {
                        self.copied = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            self.copied = false
                        }
                    }
                }) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
            }
            
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "phone.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(msisdn.localizedName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(NSLocalizedString("netherlands", comment: "") + " 🇳🇱")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    
                    Text(NSLocalizedString("active", comment: ""))
                        .font(.caption2)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(16)
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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.2), Color.clear]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct UsageCard: View {
    let title: String
    let icon: String
    let used: Double
    let total: Double
    let unit: String
    let percentage: Double
    let color: Color
    let isUnlimited: Bool
    let isClickable: Bool
    
    private var emoji: String {
        switch title {
        case "Data": return "📶"
        case "Voice": return "📞"
        case "SMS": return "💬"
        default: return "📊"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with emoji and usage info
            HStack {
                HStack(spacing: 8) {
                    Text(emoji)
                        .font(.title3)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Usage percentage or unlimited indicator
                if isUnlimited {
                    HStack(spacing: 4) {
                        Image(systemName: "infinity")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(color)
                        Text(NSLocalizedString("unlimited", comment: ""))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(color)
                    }
                } else {
                    Text("\(Int(percentage))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
                
                if isClickable {
                    Image(systemName: "chevron.right")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
            }
            
            // Progress Bar only
            if isUnlimited {
                // Unlimited indicator bar with animation
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color.opacity(0.3), color.opacity(0.6), color.opacity(0.3)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.clear, color.opacity(0.8), Color.clear]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 30, height: 8)
                                .offset(x: -geometry.size.width/2)
                                .animation(
                                    Animation.linear(duration: 2.0).repeatForever(autoreverses: false),
                                    value: UUID()
                                )
                        )
                }
                .frame(height: 8)
            } else {
                // Simplified progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray6))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [color.opacity(0.7), color]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (percentage / 100), height: 8)
                            .animation(.easeInOut(duration: 1.0), value: percentage)
                    }
                }
                .frame(height: 8)
            }
            
            // Simplified usage details
            if !isUnlimited {
                HStack {
                    if unit == "MB" {
                        Text(String(format: NSLocalizedString("gb_used", comment: ""), used / 1000))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(String(format: NSLocalizedString("percent_used", comment: ""), percentage))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if unit == "MB" {
                        Text(String(format: NSLocalizedString("gb_total", comment: ""), total / 1000))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(String(format: NSLocalizedString("percent_left", comment: ""), 100 - percentage))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: color.opacity(0.08), radius: 4, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    color.opacity(0.15),
                    lineWidth: 0.5
                )
        )
        .contentShape(Rectangle())
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text(NSLocalizedString("error", comment: ""))
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(NSLocalizedString("retry", comment: "")) {
                retry()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    MainDashboardView(authService: AuthenticationService(), dataService: DataService())
}
