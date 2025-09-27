//
//  ProfileView.swift
//  DataCheck
//
//  Created by socksprox on 26.09.25.
//

import SwiftUI

struct ProfileCard<Content: View>: View {
    var title: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            content
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
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

struct ProfileView: View {
    @ObservedObject var authService: AuthenticationService
    @ObservedObject var dataService: DataService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if dataService.isLoadingProfile {
                        ProgressView(NSLocalizedString("loading_profile", comment: ""))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                    } else if let profile = dataService.profileData {
                        // Personal Information
                        personalInfoCard(profile: profile)
                        
                        // Address Information
                        addressInfoCard(profile: profile)
                        
                        // Banking Information
                        bankingInfoCard(profile: profile)
                        
                        // Account Actions
                        accountActionsCard()
                        
                    } else if let errorMessage = dataService.profileErrorMessage {
                        ErrorView(message: errorMessage) {
                            Task {
                                if let token = authService.getAccessToken() {
                                    await dataService.fetchProfileData(accessToken: token)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("my_profile", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            if let token = authService.getAccessToken() {
                await dataService.fetchProfileData(accessToken: token)
            }
        }
        .refreshable {
            if let token = authService.getAccessToken() {
                await dataService.fetchProfileData(accessToken: token)
            }
        }
    }
    
    
    private func personalInfoCard(profile: ProfileCustomer) -> some View {
        ProfileCard(title: NSLocalizedString("personal_information", comment: "")) {
            VStack(spacing: 16) {
                ProfileInfoRow(
                    icon: "person.fill",
                    iconColor: .blue,
                    label: NSLocalizedString("full_name", comment: ""),
                    value: getFullName(profile: profile)
                )
                
                Divider()
                
                ProfileInfoRow(
                    icon: "envelope.fill",
                    iconColor: .green,
                    label: NSLocalizedString("email_address", comment: ""),
                    value: profile.email
                )
                
                Divider()
                
                ProfileInfoRow(
                    icon: "number.circle.fill",
                    iconColor: .orange,
                    label: NSLocalizedString("customer_id", comment: ""),
                    value: profile.id
                )
            }
        }
    }
    
    
    private func addressInfoCard(profile: ProfileCustomer) -> some View {
        ProfileCard {
            VStack(spacing: 16) {
                HStack {
                    Text(NSLocalizedString("invoice_address", comment: ""))
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Button(NSLocalizedString("change", comment: "")) {
                        openExternalProfile()
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(20)
                }
                
                Divider()
                
                ProfileInfoRow(
                    icon: "house.fill",
                    iconColor: .green,
                    label: NSLocalizedString("street_address", comment: ""),
                    value: formatAddress(profile.invoiceAddress)
                )
                
                Divider()
                
                ProfileInfoRow(
                    icon: "location.fill",
                    iconColor: .red,
                    label: NSLocalizedString("city", comment: ""),
                    value: "\(profile.invoiceAddress.postalCode) \(profile.invoiceAddress.city)"
                )
            }
        }
    }
    
    private func bankingInfoCard(profile: ProfileCustomer) -> some View {
        ProfileCard {
            VStack(spacing: 16) {
                HStack {
                    Text(NSLocalizedString("banking_information", comment: ""))
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Button(NSLocalizedString("change", comment: "")) {
                        openExternalProfile()
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(20)
                }
                
                Divider()
                
                HStack(spacing: 16) {
                    Image(systemName: "creditcard.fill")
                        .font(.title3)
                        .foregroundColor(.purple)
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("iban", comment: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatIBAN(profile.iban))
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private func accountActionsCard() -> some View {
        VStack(spacing: 12) {
            NavigationLink(destination: ChangePasswordView(authService: authService, dataService: dataService)) {
                HStack {
                    Image(systemName: "key.fill")
                    Text(NSLocalizedString("change_password", comment: ""))
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.primary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            
            NavigationLink(destination: SettingsView()) {
                HStack {
                    Image(systemName: "gear")
                    Text(NSLocalizedString("app_settings", comment: ""))
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.primary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            Button(action: { authService.logout() }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text(NSLocalizedString("logout", comment: ""))
                    Spacer()
                }
                .foregroundColor(.red)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }
    
    // Helper functions
    private func openExternalProfile() {
        if let url = URL(string: "https://mijn.50plusmobiel.nl/#/profile") {
            UIApplication.shared.open(url)
        }
    }
    
    private func getFullName(profile: ProfileCustomer) -> String {
        var fullName = ""
        
        if !profile.prefix.isEmpty {
            fullName += profile.prefix + " "
        }
        
        fullName += profile.firstName
        
        if !profile.lastName.isEmpty {
            fullName += " " + profile.lastName
        }
        
        return fullName
    }
    
    private func formatAddress(_ address: Address) -> String {
        var addressString = "\(address.street) \(address.number)"
        
        if let addendum = address.addendum, !addendum.isEmpty {
            addressString += " \(addendum)"
        }
        
        return addressString
    }
    
    private func formatIBAN(_ iban: String) -> String {
        // Remove extra spaces and format IBAN properly
        let cleanIBAN = iban.replacingOccurrences(of: " ", with: "")
        
        // Add spaces every 4 characters for better readability
        var formattedIBAN = ""
        for (index, character) in cleanIBAN.enumerated() {
            if index > 0 && index % 4 == 0 {
                formattedIBAN += " "
            }
            formattedIBAN += String(character)
        }
        
        return formattedIBAN
    }
}

#Preview {
    ProfileView(authService: AuthenticationService(), dataService: DataService())
}
