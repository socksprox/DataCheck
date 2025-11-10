import SwiftUI
import Combine

struct DataConsumptionDetailView: View {
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var contactManager = ContactManager()
    @State private var isShowingDayView = false
    
    // Function to localize CDR types
    private func localizedCdrType(_ cdrType: String) -> String {
        let normalizedType = cdrType.lowercased()
            .replacingOccurrences(of: " ", with: "_")
        
        let localizedKey = "cdr_\(normalizedType)"
        let localizedString = NSLocalizedString(localizedKey, comment: "")
        
        // If localization key doesn't exist, return the original type
        return localizedString != localizedKey ? localizedString : cdrType
    }
    
    // Function to get contact name or phone number
    private func displayNameForPhoneNumber(_ phoneNumber: String) -> String {
        // Only try to match contacts if the string contains digits (is likely a phone number)
        if phoneNumber.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil,
           let contactName = contactManager.getContactName(for: phoneNumber) {
            return contactName
        }
        return phoneNumber
    }
    
    var body: some View {
        VStack {
            // Toggle between List and Day view
            Picker("View Type", selection: $isShowingDayView) {
                Text(NSLocalizedString("list_view", comment: "")).tag(false)
                Text(NSLocalizedString("day_view", comment: "")).tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            if dataService.isLoadingCdrData || dataService.isLoadingProvisionalCdrData {
                ProgressView()
            } else if let errorMessage = dataService.cdrDataErrorMessage {
                Text("\(NSLocalizedString("error", comment: "")): \(errorMessage)")
            } else {
                if isShowingDayView {
                    dayView
                } else {
                    listView
                }
            }
        }
        .navigationTitle(NSLocalizedString("data_consumption", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let token = authService.getAccessToken(),
               let subscriptionGroup = dataService.customerData?.subscriptionGroups.first?.id {
                Task {
                    await dataService.fetchBothCdrDataTypes(accessToken: token, subscriptionGroup: subscriptionGroup)
                }
            }
        }
    }
    
    // MARK: - List View
    private var listView: some View {
        Group {
            if let cdrData = dataService.cdrData {
                List(cdrData) { record in
                    VStack(alignment: .leading) {
                        Text(DateHelper.format(dateString: record.startDate))
                            .font(.headline)
                        Text("\(NSLocalizedString("type", comment: "")): \(localizedCdrType(record.cdrType))")
                        
                        // Show phone number for calls and SMS
                        if let otherParty = record.otherParty, !otherParty.isEmpty {
                            Text("\(NSLocalizedString("other_party", comment: "")): \(displayNameForPhoneNumber(otherParty))")
                        }
                        
                        Text("\(NSLocalizedString("duration", comment: "")): \(record.duration)")
                        if let location = record.aLocation {
                            Text("\(NSLocalizedString("location", comment: "")): \(location)")
                        }
                    }
                }
            } else {
                Text(NSLocalizedString("no_data_available", comment: ""))
            }
        }
    }
    
    // MARK: - Day View
    private var dayView: some View {
        Group {
            if let dayData = dataService.dayAggregatedData {
                List(dayData) { dayRecord in
                    VStack(alignment: .leading, spacing: 8) {
                        // Date header
                        Text(formatDate(dayRecord.date))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // Usage summary cards
                        HStack(spacing: 12) {
                            // Data usage card
                            DayUsageCard(
                                title: NSLocalizedString("data_usage", comment: ""),
                                value: String(format: NSLocalizedString("gb_format", comment: ""), dayRecord.dataUsageMB / 1024),
                                color: .blue
                            )
                            
                            // Call minutes card
                            DayUsageCard(
                                title: NSLocalizedString("call_minutes", comment: ""),
                                value: String(format: NSLocalizedString("minutes_format", comment: ""), dayRecord.callMinutes),
                                color: .green
                            )
                            
                            // SMS count card
                            DayUsageCard(
                                title: NSLocalizedString("sms_count", comment: ""),
                                value: String(format: NSLocalizedString("sms_format", comment: ""), dayRecord.smsCount),
                                color: .orange
                            )
                        }
                        
                        // Total charge if applicable
                        if dayRecord.totalCharge > 0 {
                            HStack {
                                Text(NSLocalizedString("total_charge", comment: ""))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: NSLocalizedString("charge_format", comment: ""), dayRecord.totalCharge))
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text(NSLocalizedString("no_data_available", comment: ""))
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .full
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        
        return dateString
    }
}

// MARK: - Usage Card Component
struct DayUsageCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
