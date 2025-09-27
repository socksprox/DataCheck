import SwiftUI
import Combine

struct DataConsumptionDetailView: View {
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var contactManager = ContactManager()
    
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
            if dataService.isLoadingCdrData {
                ProgressView()
            } else if let errorMessage = dataService.cdrDataErrorMessage {
                Text("\(NSLocalizedString("error", comment: "")): \(errorMessage)")
            } else if let cdrData = dataService.cdrData {
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
        .navigationTitle(NSLocalizedString("data_consumption", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let token = authService.getAccessToken(),
               let subscriptionGroup = dataService.customerData?.subscriptionGroups.first?.id {
                Task {
                    await dataService.fetchCdrData(accessToken: token, subscriptionGroup: subscriptionGroup)
                }
            }
        }
    }
}
