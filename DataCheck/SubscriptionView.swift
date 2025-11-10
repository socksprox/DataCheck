//
//  SubscriptionView.swift
//  DataCheck
//
//  Created by socksprox on 26.09.25.
//

import SwiftUI

struct InfoCard<Content: View>: View {
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

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

struct SubscriptionView: View {
    @ObservedObject var authService: AuthenticationService
    @ObservedObject var dataService: DataService
    @State private var serviceSettings: ServiceSettingsCustomer?
    @State private var isLoadingSettings = false
    @State private var isTogglingService = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if dataService.isLoadingSubscription {
                        ProgressView(NSLocalizedString("loading_subscription_details", comment: ""))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                    } else if let subscriptionData = dataService.subscriptionData {
                        // Wallet Balance
                        walletBalanceCard(wallet: subscriptionData.wallet)
                        
                        // Subscription Details
                        if let subscriptionGroup = subscriptionData.subscriptionGroups.first {
                            subscriptionDetailsCard(subscriptionGroup: subscriptionGroup)
                            
                            // Plan Details
                            if let bundle = subscriptionGroup.activeSubscriptionGroupBundle {
                                planDetailsCard(bundle: bundle, subscriptionGroup: subscriptionGroup)
                            }
                            
                            // Phone Details
                            if let msisdn = subscriptionGroup.msisdns.first {
                                phoneDetailsCard(msisdn: msisdn)
                            }
                            
                            // Service Settings
                            if let settings = serviceSettings,
                               let settingsGroup = settings.subscriptionGroups.first,
                               let settingsMsisdn = settingsGroup.msisdns.first {
                                serviceSettingsCard(
                                    msisdn: settingsMsisdn,
                                    bundle: settingsGroup.activeSubscriptionGroupBundle,
                                    lockedAddOns: settings.lockedAddOns
                                )
                            }
                            
                            // Available Add-ons
                            if !subscriptionGroup.availableAddOns.isEmpty {
                                availableAddOnsCard(addOns: subscriptionGroup.availableAddOns)
                            }
                        }
                    } else if let errorMessage = dataService.subscriptionErrorMessage {
                        ErrorView(message: errorMessage) {
                            Task {
                                if let token = authService.getAccessToken() {
                                    await dataService.fetchSubscriptionData(accessToken: token)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("subscription", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            if let token = authService.getAccessToken() {
                await dataService.fetchSubscriptionData(accessToken: token)
                await fetchServiceSettings()
            }
        }
        .refreshable {
            if let token = authService.getAccessToken() {
                await dataService.fetchSubscriptionData(accessToken: token)
                await fetchServiceSettings()
            }
        }
    }
    
    
    private func walletBalanceCard(wallet: Wallet) -> some View {
        InfoCard(title: NSLocalizedString("wallet_balance", comment: "")) {
            HStack(spacing: 16) {
                Image(systemName: "creditcard.fill")
                    .font(.title)
                    .foregroundColor(.green)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("€\(wallet.balance, specifier: "%.2f")")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(wallet.balance > 0 ? .green : .red)
                    
                    Text(NSLocalizedString("available_to_use_for_addons", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    private func subscriptionDetailsCard(subscriptionGroup: DetailedSubscriptionGroup) -> some View {
        InfoCard(title: NSLocalizedString("contract_details", comment: "")) {
            VStack(spacing: 12) {
                InfoRow(
                    label: NSLocalizedString("contract_period", comment: ""),
                    value: "\(formatDate(subscriptionGroup.startDate)) - \(formatDate(subscriptionGroup.endDate))"
                )
                
                
                Divider()
                
                InfoRow(
                    label: NSLocalizedString("clever_enable", comment: ""),
                    value: subscriptionGroup.isCleverEnable ? NSLocalizedString("yes", comment: "") : NSLocalizedString("no", comment: ""),
                    valueColor: subscriptionGroup.isCleverEnable ? .green : .red
                )
            }
        }
    }
    
    private func planDetailsCard(bundle: SubscriptionGroupBundle, subscriptionGroup: DetailedSubscriptionGroup) -> some View {
        let planName = localizedPlanName(bundle.recurringAddOns?.first?.name)
        
        return InfoCard {
            VStack(alignment: .leading, spacing: 16) {
                // Custom title with change button
                HStack {
                    Text(planName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(NSLocalizedString("change_subscription", comment: "")) {
                        openChangeSubscriptionURL()
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(20)
                }
                
                // Plan content
                VStack(spacing: 16) {
                    HStack(alignment: .top, spacing: 16) {
                        planFeatureView(icon: "phone.fill", color: .green, value: formatMinutes(bundle.details.marketingData.minutes), label: NSLocalizedString("minutes", comment: ""))
                        planFeatureView(icon: "message.fill", color: .purple, value: formatSMS(bundle.details.marketingData.sms), label: NSLocalizedString("sms", comment: ""))
                        planFeatureView(icon: "wifi", color: .blue, value: formatData(bundle.details.marketingData.data), label: NSLocalizedString("data", comment: ""))
                    }
                
                    if !bundle.details.campaignRows.isEmpty || !bundle.details.priceForecast.isEmpty {
                        Divider()
                    }
                    
                    if !bundle.details.campaignRows.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("active_campaigns", comment: ""))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            ForEach(bundle.details.campaignRows, id: \.self) { campaign in
                                HStack(spacing: 8) {
                                    Image(systemName: "tag.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text(localizedCampaignText(campaign))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    
                    if !bundle.details.priceForecast.isEmpty {
                        priceForecastView(
                            priceForecast: bundle.details.priceForecast,
                            contractStartDate: subscriptionGroup.startDate,
                            contractEndDate: subscriptionGroup.endDate
                        )
                    }
                }
            }
        }
    }
    
    private func planFeatureView(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func priceForecastView(priceForecast: [String], contractStartDate: String, contractEndDate: String) -> some View {
        NavigationLink(destination: PriceForecastDetailView(
            priceForecast: priceForecast,
            contractStartDate: contractStartDate,
            contractEndDate: contractEndDate
        )) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(NSLocalizedString("price_forecast", comment: ""))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    ForEach(Array(priceForecast.enumerated()), id: \.offset) { index, forecast in
                        let parsedForecast = parsePriceForecast(forecast)
                        
                        HStack(spacing: 12) {
                            // Timeline indicator
                            VStack {
                                Circle()
                                    .fill(index == 0 ? Color.green : Color.blue)
                                    .frame(width: 8, height: 8)
                                
                                if index < priceForecast.count - 1 {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 2, height: 20)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(parsedForecast.period)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text(parsedForecast.price)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(index == 0 ? .green : .blue)
                                }
                                
                                if index == 0 {
                                    Text(NSLocalizedString("current", comment: ""))
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func parsePriceForecast(_ forecast: String) -> (period: String, price: String) {
        // Parse different forecast formats
        // Examples: "volgende factuur: € 5,69", "vanaf 23-11: € 5,00", "vanaf 23-09-2026: € 10,00"
        
        if forecast.contains("volgende factuur:") || forecast.contains("next bill:") {
            let components = forecast.components(separatedBy: ":")
            if components.count >= 2 {
                let period = NSLocalizedString("next_bill", comment: "")
                let price = components[1].trimmingCharacters(in: .whitespaces)
                return (period, price)
            }
        } else if forecast.contains("vanaf") || forecast.contains("from") {
            let components = forecast.components(separatedBy: ":")
            if components.count >= 2 {
                let dateString = components[0].replacingOccurrences(of: "vanaf", with: "").replacingOccurrences(of: "from", with: "").trimmingCharacters(in: .whitespaces)
                let period = "\(NSLocalizedString("from", comment: "")) \(dateString)"
                let price = components[1].trimmingCharacters(in: .whitespaces)
                return (period, price)
            }
        }
        
        // Fallback: try to split by colon
        let components = forecast.components(separatedBy: ":")
        if components.count >= 2 {
            return (components[0].trimmingCharacters(in: .whitespaces), components[1].trimmingCharacters(in: .whitespaces))
        }
        
        return (forecast, "")
    }
    
    private func serviceSettingsCard(msisdn: ServiceSettingsMSISDN, bundle: ServiceSettingsBundle?, lockedAddOns: Bool) -> some View {
        InfoCard(title: NSLocalizedString("service_settings", comment: "")) {
            VStack(spacing: 16) {
                // Cost Ceiling Toggle
                if let bundle = bundle,
                   let costCeilingAddon = bundle.recurringAddOns.first(where: { $0.name.lowercased().contains("kostenplafond") || $0.name.lowercased().contains("cost ceiling") }) {
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(NSLocalizedString("cost_ceiling", comment: ""))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("€\(costCeilingAddon.priceGroup.price, specifier: "%.2f") \(NSLocalizedString("per_month", comment: ""))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: .constant(costCeilingAddon.active))
                                .disabled(true)
                                .labelsHidden()
                        }
                        if lockedAddOns {
                            Text(NSLocalizedString("addons_locked_message", comment: ""))
                                .font(.caption2)
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    Divider()
                }
                
                // Voicemail Toggle
                serviceToggleRow(
                    label: NSLocalizedString("voicemail", comment: ""),
                    isEnabled: msisdn.voicemailEnabled,
                    serviceId: "voicemail",
                    msisdnId: msisdn.id
                )
                
                // Optional Services
                ForEach(msisdn.optionalServices, id: \.id) { service in
                    Divider()
                    serviceToggleRow(
                        label: localizedServiceName(service.displayName),
                        isEnabled: service.enabled,
                        serviceId: service.id,
                        msisdnId: msisdn.id
                    )
                }
            }
        }
        .disabled(isTogglingService)
        .opacity(isTogglingService ? 0.6 : 1.0)
    }
    
    private func serviceToggleRow(label: String, isEnabled: Bool, serviceId: String, msisdnId: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { newValue in
                    Task {
                        await toggleService(msisdnId: msisdnId, serviceId: serviceId, enabled: newValue)
                    }
                }
            ))
            .labelsHidden()
        }
    }
    
    private func localizedServiceName(_ serviceName: String) -> String {
        // Create a key from the service name by converting to lowercase and replacing spaces with underscores
        let key = "service_" + serviceName.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ",", with: "")
        
        let localized = NSLocalizedString(key, comment: "")
        
        // If no localization exists, return the original name
        return localized != key ? localized : serviceName
    }
    
    private func fetchServiceSettings() async {
        guard let token = authService.getAccessToken() else { return }
        isLoadingSettings = true
        serviceSettings = await dataService.fetchServiceSettings(accessToken: token)
        isLoadingSettings = false
    }
    
    private func toggleService(msisdnId: String, serviceId: String, enabled: Bool) async {
        guard let token = authService.getAccessToken() else { return }
        isTogglingService = true
        
        let success: Bool
        
        // Voicemail uses a different mutation
        if serviceId == "voicemail" {
            success = await dataService.toggleVoicemail(
                accessToken: token,
                msisdnId: msisdnId,
                enabled: enabled
            )
        } else {
            success = await dataService.toggleOptionalService(
                accessToken: token,
                msisdnId: msisdnId,
                serviceId: serviceId,
                enabled: enabled
            )
        }
        
        if success {
            // Refresh service settings to get updated state
            await fetchServiceSettings()
        }
        
        isTogglingService = false
    }
    
    private func phoneDetailsCard(msisdn: DetailedMSISDN) -> some View {
        InfoCard(title: NSLocalizedString("phone_details", comment: "")) {
            VStack(spacing: 12) {
                InfoRow(
                    label: NSLocalizedString("phone_number", comment: ""),
                    value: formatPhoneNumber(msisdn.msisdn)
                )
                Divider()
                InfoRow(
                    label: NSLocalizedString("status", comment: ""),
                    value: getPhoneStatus(msisdn),
                    valueColor: msisdn.active ? .green : .red
                )
                Divider()
                HStack {
                    InfoRow(
                        label: NSLocalizedString("sim_card_iccid", comment: ""),
                        value: msisdn.iccid.iccid
                    )
                    Button(action: {
                        UIPasteboard.general.string = msisdn.iccid.iccid
                    }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                Divider()
                HStack {
                    InfoRow(
                        label: NSLocalizedString("puk_code", comment: ""),
                        value: msisdn.iccid.puk1
                    )
                    Button(action: {
                        UIPasteboard.general.string = msisdn.iccid.puk1
                    }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
    }
    
    private func availableAddOnsCard(addOns: [AddOn]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Modern section header
            HStack {
                Text(NSLocalizedString("available_addons", comment: ""))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            
            // Modern addon cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(addOns, id: \.id) { addOn in
                        modernAddonCard(addOn: addOn)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            Color(.systemGray6).opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 5)
        )
    }
    
    private func modernAddonCard(addOn: AddOn) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon
            HStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: getAddonIcon(for: addOn.name))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("€\(addOn.priceGroup.price, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(NSLocalizedString("per_month", comment: ""))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(addOn.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Modern CTA button
            Button(action: {
                openSubscriptionURL()
            }) {
                HStack(spacing: 8) {
                    Text(NSLocalizedString("add_to_plan", comment: ""))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: false)
        }
        .padding(20)
        .frame(width: 200, height: 220)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    // Helper functions
    private func localizedPlanName(_ planName: String?) -> String {
        guard let planName = planName else {
            return NSLocalizedString("current_plan", comment: "")
        }
        
        // Convert to lowercase and remove spaces for consistent key matching
        let key = planName.lowercased().replacingOccurrences(of: " ", with: "")
        
        // Try to get localized version, fallback to original if not found
        let localizedKey = NSLocalizedString(key, comment: "")
        return localizedKey != key ? localizedKey : planName
    }
    
    private func localizedCampaignText(_ campaignText: String) -> String {
        // Check for the specific campaign text we want to translate
        if campaignText == "Actie: Eerste 12 maanden 50% korting" {
            return NSLocalizedString("actie_eerste_12_maanden_50_korting", comment: "")
        }
        
        // For any other campaign text, return the original API result
        return campaignText
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        return minutes >= 9000 ? NSLocalizedString("unlimited", comment: "") : NumberFormatter.localizedString(from: NSNumber(value: minutes), number: .decimal)
    }
    
    private func formatSMS(_ sms: Int) -> String {
        return sms >= 500 ? NSLocalizedString("unlimited", comment: "") : NumberFormatter.localizedString(from: NSNumber(value: sms), number: .decimal)
    }
    
    private func formatData(_ data: Int) -> String {
        return NumberFormatter.localizedString(from: NSNumber(value: data / 1000), number: .decimal) + " GB"
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "dd MMM yyyy"
            return formatter.string(from: date)
        } else {
            // Try alternative format
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateString) {
                formatter.dateFormat = "dd MMM yyyy"
                return formatter.string(from: date)
            }
        }
        
        return dateString
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        // Format Dutch phone number
        if number.hasPrefix("31") {
            let cleaned = String(number.dropFirst(2))
            if cleaned.count >= 9 {
                let prefix = String(cleaned.prefix(3))
                let middle = String(cleaned.dropFirst(3).prefix(3))
                let suffix = String(cleaned.dropFirst(6))
                return "+31 \(prefix) \(middle) \(suffix)"
            }
        }
        return number
    }
    
    private func getPhoneStatus(_ msisdn: DetailedMSISDN) -> String {
        if msisdn.hardSuspended {
            return NSLocalizedString("hard_suspended", comment: "")
        } else if msisdn.suspended {
            return NSLocalizedString("suspended", comment: "")
        } else if msisdn.activating {
            return NSLocalizedString("activating", comment: "")
        } else if msisdn.active {
            return NSLocalizedString("active", comment: "")
        } else {
            return NSLocalizedString("inactive", comment: "")
        }
    }
    
    private func openChangeSubscriptionURL() {
        if let url = URL(string: "https://mijn.50plusmobiel.nl/#/subscription/edit") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openSubscriptionURL() {
        if let url = URL(string: "https://mijn.50plusmobiel.nl/#/subscription") {
            UIApplication.shared.open(url)
        }
    }
    
    private func getAddonIcon(for addonName: String) -> String {
        let name = addonName.lowercased()
        
        if name.contains("data") || name.contains("gb") || name.contains("internet") {
            return "wifi"
        } else if name.contains("minute") || name.contains("call") || name.contains("bel") {
            return "phone.fill"
        } else if name.contains("sms") || name.contains("text") || name.contains("bericht") {
            return "message.fill"
        } else if name.contains("roaming") || name.contains("international") || name.contains("internationaal") {
            return "globe"
        } else if name.contains("voicemail") || name.contains("voicemail") {
            return "voicemail"
        } else {
            return "plus.circle.fill"
        }
    }
    
    private func getAddonDescription(for addonName: String) -> String {
        let name = addonName.lowercased()
        
        if name.contains("data") || name.contains("gb") || name.contains("internet") {
            return NSLocalizedString("extra_data_description", comment: "")
        } else if name.contains("minute") || name.contains("call") || name.contains("bel") {
            return NSLocalizedString("extra_minutes_description", comment: "")
        } else if name.contains("sms") || name.contains("text") || name.contains("bericht") {
            return NSLocalizedString("extra_sms_description", comment: "")
        } else if name.contains("roaming") || name.contains("international") || name.contains("internationaal") {
            return NSLocalizedString("roaming_description", comment: "")
        } else if name.contains("voicemail") || name.contains("voicemail") {
            return NSLocalizedString("voicemail_description", comment: "")
        } else {
            return NSLocalizedString("addon_description", comment: "")
        }
    }
}

#Preview {
    SubscriptionView(authService: AuthenticationService(), dataService: DataService())
}
