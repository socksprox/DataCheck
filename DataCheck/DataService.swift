//
//  DataService.swift
//  DataCheck
//
//  Created by socksprox on 26.09.25.
//

import Foundation
import Combine
import WidgetKit
import UIKit

@MainActor
class DataService: ObservableObject {
    @Published var customerData: Customer?
    @Published var subscriptionData: SubscriptionCustomer?
    @Published var profileData: ProfileCustomer?
    @Published var isLoading = false
    @Published var isLoadingSubscription = false
    @Published var isLoadingProfile = false
    @Published var errorMessage: String?
    @Published var subscriptionErrorMessage: String?
    @Published var profileErrorMessage: String?
    @Published var cdrData: [CdrRecord]?
    @Published var isLoadingCdrData = false
    @Published var cdrDataErrorMessage: String?
    @Published var provisionalCdrData: [ProvisionalCdrRecord]?
    @Published var isLoadingProvisionalCdrData = false
    @Published var provisionalCdrDataErrorMessage: String?
    @Published var dayAggregatedData: [DayAggregatedData]?
    @Published var phoneNumber: String?
    
    private let baseURL = "https://mijn.50plusmobiel.nl"
    
    private let customerDataCacheKey = "customerData"
    private let subscriptionDataCacheKey = "subscriptionData"
    private let profileDataCacheKey = "profileData"
    private let phoneNumberCacheKey = "phoneNumber"

    func fetchPhoneNumber(accessToken: String) async -> String? {
        do {
            guard let url = URL(string: "\(baseURL)/api/graphql") else {
                throw DataError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "authorization")
            request.setValue("https://mijn.50plusmobiel.nl/", forHTTPHeaderField: "Referer")
            request.setValue("https://mijn.50plusmobiel.nl", forHTTPHeaderField: "Origin")
            
            let graphQLQuery = """
            {
              msisdns
            }
            """
            
            let graphQLRequest = MsisdnGraphQLRequest(variables: [:], query: graphQLQuery)
            request.httpBody = try JSONEncoder().encode(graphQLRequest)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(MsisdnGraphQLResponse.self, from: data)
            
            if let firstNumber = response.data.msisdns.first {
                self.phoneNumber = firstNumber
                CacheManager.shared.saveData(firstNumber, forKey: phoneNumberCacheKey)
                return firstNumber
            }
            return nil
        } catch {
            print("Error fetching phone number: \(error)")
            return nil
        }
    }
    
    func fetchCustomerData(accessToken: String) async {
        // Load from cache first
        if let cachedData: Customer = CacheManager.shared.loadData(forKey: customerDataCacheKey) {
            self.customerData = cachedData
        } else {
            isLoading = true
        }
        errorMessage = nil
        
        // Get phone number first
        var msisdn: String?
        if let cachedPhone: String = CacheManager.shared.loadData(forKey: phoneNumberCacheKey) {
            msisdn = cachedPhone
            self.phoneNumber = cachedPhone
        } else {
            msisdn = await fetchPhoneNumber(accessToken: accessToken)
        }
        
        guard let phoneNumber = msisdn else {
            self.errorMessage = "Failed to retrieve phone number"
            isLoading = false
            return
        }
        
        do {
            guard let url = URL(string: "\(baseURL)/api/graphql") else {
                throw DataError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "authorization")
            request.setValue("https://mijn.50plusmobiel.nl/", forHTTPHeaderField: "Referer")
            request.setValue("https://mijn.50plusmobiel.nl", forHTTPHeaderField: "Origin")
            
            let graphQLQuery = """
            query ($selectedMsisdn: String) {
              me(selectedMsisdn: $selectedMsisdn) {
                id
                canRenew
                renewalUrl
                subscriptionGroups {
                  id
                  charge
                  remainingBeforeBill
                  unlockingAllowed
                  contractUnlocked
                  referralCode
                  nextRenewedSubscriptionDate
                  msisdns {
                    id
                    localizedName
                    thresholds {
                      relevantCeiling
                      __typename
                    }
                    balance {
                      voiceAvailable
                      voiceAssigned
                      voicePercentage
                      smsAvailable
                      smsAssigned
                      smsPercentage
                      dataAvailable
                      dataAssigned
                      dataPercentage
                      dataReserved
                      __typename
                    }
                    __typename
                  }
                  __typename
                }
                iccidSwaps {
                  id
                  __typename
                }
                __typename
              }
            }
            """
            
            let graphQLRequest = GraphQLRequest(variables: ["selectedMsisdn": phoneNumber], query: graphQLQuery)
            request.httpBody = try JSONEncoder().encode(graphQLRequest)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(GraphQLResponse.self, from: data)
            
            self.customerData = response.data.me
            CacheManager.shared.saveData(response.data.me, forKey: customerDataCacheKey)
            shareDataWithWidget(customer: response.data.me)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func fetchSubscriptionData(accessToken: String) async {
        if let cachedData: SubscriptionCustomer = CacheManager.shared.loadData(forKey: subscriptionDataCacheKey) {
            self.subscriptionData = cachedData
        } else {
            isLoadingSubscription = true
        }
        subscriptionErrorMessage = nil
        
        // Get phone number first
        var msisdn: String?
        if let cachedPhone: String = CacheManager.shared.loadData(forKey: phoneNumberCacheKey) {
            msisdn = cachedPhone
        } else {
            msisdn = await fetchPhoneNumber(accessToken: accessToken)
        }
        
        guard let phoneNumber = msisdn else {
            self.subscriptionErrorMessage = "Failed to retrieve phone number"
            isLoadingSubscription = false
            return
        }
        
        do {
            guard let url = URL(string: "\(baseURL)/api/graphql") else {
                throw DataError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "authorization")
            request.setValue("https://mijn.50plusmobiel.nl/", forHTTPHeaderField: "Referer")
            request.setValue("https://mijn.50plusmobiel.nl", forHTTPHeaderField: "Origin")
            
            let subscriptionQuery = """
            query ($selectedMsisdn: String) {
              me(selectedMsisdn: $selectedMsisdn) {
                id
                wallet {
                  id
                  balance
                  __typename
                }
                allowAddOns
                invoicePeriods
                MAX_LATE_PAYMENT_DAYS
                latePayments
                subscriptionGroups {
                  id
                  isCleverEnable
                  startDate
                  endDate
                  activeContract {
                    startDate
                    endDate
                    originalEndDate
                    __typename
                  }
                  nextContract {
                    startDate
                    endDate
                    originalEndDate
                    __typename
                  }
                  activeSubscriptionGroupBundle {
                    id
                    recurringAddOns {
                      id
                      name
                      active
                      __typename
                    }
                    details {
                      marketingData {
                        minutes
                        sms
                        data
                        __typename
                      }
                      campaignRows
                      priceForecast(recurringOnly: false)
                      __typename
                    }
                    hasAvailableUpgrades
                    __typename
                  }
                  nextSubscriptionGroupBundle {
                    id
                    startDate
                    details {
                      marketingData {
                        minutes
                        sms
                        data
                        __typename
                      }
                      __typename
                    }
                    __typename
                  }
                  msisdns {
                    id
                    cooldown
                    active
                    suspended
                    hardSuspended
                    activating
                    msisdn
                    thresholds {
                      relevantCeiling
                      __typename
                    }
                    iccid {
                      iccid
                      puk1
                      __typename
                    }
                    voicemailEnabled
                    optionalServices {
                      displayName
                      enabled
                      __typename
                    }
                    __typename
                  }
                  availableAddOns {
                    id
                    name
                    priceGroup {
                      id
                      price
                      priceArrangements {
                        description
                        __typename
                      }
                      __typename
                    }
                    __typename
                  }
                  temporaryAddOns {
                    name
                    __typename
                  }
                  __typename
                }
                iccidSwaps {
                  id
                  __typename
                }
                __typename
              }
            }
            """
            
            let graphQLRequest = GraphQLRequest(variables: ["selectedMsisdn": phoneNumber], query: subscriptionQuery)
            request.httpBody = try JSONEncoder().encode(graphQLRequest)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(SubscriptionGraphQLResponse.self, from: data)
            
            self.subscriptionData = response.data.me
            CacheManager.shared.saveData(response.data.me, forKey: subscriptionDataCacheKey)
        } catch {
            self.subscriptionErrorMessage = error.localizedDescription
        }
        
        isLoadingSubscription = false
    }
    
    func fetchProfileData(accessToken: String) async {
        if let cachedData: ProfileCustomer = CacheManager.shared.loadData(forKey: profileDataCacheKey) {
            self.profileData = cachedData
        } else {
            isLoadingProfile = true
        }
        profileErrorMessage = nil
        
        // Get phone number first
        var msisdn: String?
        if let cachedPhone: String = CacheManager.shared.loadData(forKey: phoneNumberCacheKey) {
            msisdn = cachedPhone
        } else {
            msisdn = await fetchPhoneNumber(accessToken: accessToken)
        }
        
        guard let phoneNumber = msisdn else {
            self.profileErrorMessage = "Failed to retrieve phone number"
            isLoadingProfile = false
            return
        }
        
        do {
            guard let url = URL(string: "\(baseURL)/api/graphql") else {
                throw DataError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "authorization")
            request.setValue("https://mijn.50plusmobiel.nl/", forHTTPHeaderField: "Referer")
            request.setValue("https://mijn.50plusmobiel.nl", forHTTPHeaderField: "Origin")
            
            let profileQuery = """
            query ($selectedMsisdn: String) {
              me(selectedMsisdn: $selectedMsisdn) {
                id
                prefix
                firstName
                lastName
                email
                invoiceAddress {
                  street
                  number
                  addendum
                  postalCode
                  city
                  __typename
                }
                iban
                __typename
              }
            }
            """
            
            let graphQLRequest = GraphQLRequest(variables: ["selectedMsisdn": phoneNumber], query: profileQuery)
            request.httpBody = try JSONEncoder().encode(graphQLRequest)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(ProfileGraphQLResponse.self, from: data)
            
            self.profileData = response.data.me
            CacheManager.shared.saveData(response.data.me, forKey: profileDataCacheKey)
        } catch {
            self.profileErrorMessage = error.localizedDescription
        }
        
        isLoadingProfile = false
    }
    
    func fetchCdrData(accessToken: String, subscriptionGroup: String) async {
        isLoadingCdrData = true
        cdrDataErrorMessage = nil
        
        do {
            guard let url = URL(string: "\(baseURL)/api/graphql") else {
                throw DataError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "authorization")
            request.setValue("https://mijn.50plusmobiel.nl/", forHTTPHeaderField: "Referer")
            request.setValue("https://mijn.50plusmobiel.nl", forHTTPHeaderField: "Origin")
            
            let cdrQuery = """
            query cdrData($subscriptionGroup: String!, $invoice: String, $types: [Int], $onlyCharged: Boolean) {
              cdrData(subscriptionGroup: $subscriptionGroup, invoice: $invoice, types: $types, onlyCharged: $onlyCharged) {
                startDate
                cdrType
                retailCharge
                originalRetailCharge
                otherParty
                aLocation
                aCountry
                duration
                durationInBundle
                __typename
              }
            }
            """
            
            let variables: [String: AnyCodable] = [
                "onlyCharged": AnyCodable(false),
                "subscriptionGroup": AnyCodable(subscriptionGroup),
                "invoice": AnyCodable(nil as String?),
                "types": AnyCodable([1, 2, 3, 5, 6, 7] as [Int])
            ]
            
            let graphQLRequest = CdrGraphQLRequest(operationName: "cdrData", variables: variables, query: cdrQuery)
            
            let encoder = JSONEncoder()
            let requestBody = try encoder.encode(graphQLRequest)
            request.httpBody = requestBody
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(CdrDataResponse.self, from: data)
            
            self.cdrData = response.data.cdrData
        } catch {
            self.cdrDataErrorMessage = error.localizedDescription
        }
        
        isLoadingCdrData = false
    }
    
    func fetchProvisionalCdrData(accessToken: String, subscriptionGroup: String) async {
        isLoadingProvisionalCdrData = true
        provisionalCdrDataErrorMessage = nil
        
        do {
            guard let url = URL(string: "\(baseURL)/api/graphql") else {
                throw DataError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "authorization")
            request.setValue("https://mijn.50plusmobiel.nl/", forHTTPHeaderField: "Referer")
            request.setValue("https://mijn.50plusmobiel.nl", forHTTPHeaderField: "Origin")
            
            let provisionalCdrQuery = """
            query provisionalCdrData($subscriptionGroup: String!) {
              provisionalCdrData(subscriptionGroup: $subscriptionGroup) {
                startDate
                cdrType
                otherParty
                duration
                aLocation
                aCountry
                retailCharge
                __typename
              }
            }
            """
            
            let variables: [String: AnyCodable] = [
                "subscriptionGroup": AnyCodable(subscriptionGroup)
            ]
            
            let graphQLRequest = CdrGraphQLRequest(operationName: "provisionalCdrData", variables: variables, query: provisionalCdrQuery)
            
            let encoder = JSONEncoder()
            let requestBody = try encoder.encode(graphQLRequest)
            request.httpBody = requestBody
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(ProvisionalCdrDataResponse.self, from: data)
            
            self.provisionalCdrData = response.data.provisionalCdrData
        } catch {
            self.provisionalCdrDataErrorMessage = error.localizedDescription
        }
        
        isLoadingProvisionalCdrData = false
    }
    
    func fetchBothCdrDataTypes(accessToken: String, subscriptionGroup: String) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchCdrData(accessToken: accessToken, subscriptionGroup: subscriptionGroup)
            }
            group.addTask {
                await self.fetchProvisionalCdrData(accessToken: accessToken, subscriptionGroup: subscriptionGroup)
            }
        }
        
        // After both are fetched, aggregate the data by day
        aggregateDataByDay()
    }
    
    private func aggregateDataByDay() {
        var dayData: [String: DayAggregatedData] = [:]
        
        // Process historical CDR data
        if let cdrData = cdrData {
            for record in cdrData {
                let dateKey = extractDateKey(from: record.startDate)
                
                if dayData[dateKey] == nil {
                    dayData[dateKey] = DayAggregatedData(
                        id: dateKey,
                        date: dateKey,
                        dataUsageMB: 0,
                        callMinutes: 0,
                        smsCount: 0,
                        totalCharge: 0
                    )
                }
                
                var existingData = dayData[dateKey]!
                
                // Parse data usage
                if record.cdrType.lowercased() == "data" {
                    let dataMB = parseDataUsage(record.duration)
                    existingData = DayAggregatedData(
                        id: existingData.id,
                        date: existingData.date,
                        dataUsageMB: existingData.dataUsageMB + dataMB,
                        callMinutes: existingData.callMinutes,
                        smsCount: existingData.smsCount,
                        totalCharge: existingData.totalCharge + record.retailCharge
                    )
                }
                // Parse call minutes
                else if record.cdrType.lowercased().contains("gesprek") {
                    let minutes = parseCallDuration(record.duration)
                    existingData = DayAggregatedData(
                        id: existingData.id,
                        date: existingData.date,
                        dataUsageMB: existingData.dataUsageMB,
                        callMinutes: existingData.callMinutes + minutes,
                        smsCount: existingData.smsCount,
                        totalCharge: existingData.totalCharge + record.retailCharge
                    )
                }
                // Parse SMS
                else if record.cdrType.lowercased().contains("sms") {
                    existingData = DayAggregatedData(
                        id: existingData.id,
                        date: existingData.date,
                        dataUsageMB: existingData.dataUsageMB,
                        callMinutes: existingData.callMinutes,
                        smsCount: existingData.smsCount + 1,
                        totalCharge: existingData.totalCharge + record.retailCharge
                    )
                }
                
                dayData[dateKey] = existingData
            }
        }
        
        // Process provisional CDR data
        if let provisionalData = provisionalCdrData {
            for record in provisionalData {
                let dateKey = extractDateKey(from: record.startDate)
                
                if dayData[dateKey] == nil {
                    dayData[dateKey] = DayAggregatedData(
                        id: dateKey,
                        date: dateKey,
                        dataUsageMB: 0,
                        callMinutes: 0,
                        smsCount: 0,
                        totalCharge: 0
                    )
                }
                
                var existingData = dayData[dateKey]!
                
                // Parse provisional data usage
                if record.cdrType.lowercased() == "data" {
                    let dataMB = parseDataUsage(record.duration)
                    existingData = DayAggregatedData(
                        id: existingData.id,
                        date: existingData.date,
                        dataUsageMB: existingData.dataUsageMB + dataMB,
                        callMinutes: existingData.callMinutes,
                        smsCount: existingData.smsCount,
                        totalCharge: existingData.totalCharge + record.retailCharge
                    )
                }
                
                dayData[dateKey] = existingData
            }
        }
        
        // Sort by date (most recent first)
        self.dayAggregatedData = dayData.values.sorted { $0.date > $1.date }
    }
    
    private func extractDateKey(from dateString: String) -> String {
        // Extract date from "2025-09-28T15:41:15+0200" format to "2025-09-28"
        let components = dateString.components(separatedBy: "T")
        return components.first ?? dateString
    }
    
    private func parseDataUsage(_ durationString: String) -> Double {
        // Parse "150,00 MB" or "1.208,52 MB" format
        let cleanedString = durationString.replacingOccurrences(of: " MB", with: "")
            .replacingOccurrences(of: ".", with: "") // Remove thousand separators
            .replacingOccurrences(of: ",", with: ".") // Convert decimal separator
        
        return Double(cleanedString) ?? 0.0
    }
    
    private func parseCallDuration(_ durationString: String) -> Int {
        // Parse "39:36" format to minutes
        let components = durationString.components(separatedBy: ":")
        guard components.count == 2,
              let minutes = Int(components[0]),
              let seconds = Int(components[1]) else {
            return 0
        }
        
        return minutes + (seconds > 0 ? 1 : 0) // Round up if there are seconds
    }
    
    func updatePassword(accessToken: String, currentPassword: String, newPassword: String) async -> Bool {
        do {
            guard let url = URL(string: "\(baseURL)/api/graphql") else {
                throw DataError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "authorization")
            request.setValue("https://mijn.50plusmobiel.nl/", forHTTPHeaderField: "Referer")
            request.setValue("https://mijn.50plusmobiel.nl", forHTTPHeaderField: "Origin")
            
            let updatePasswordMutation = """
            mutation updatePassword($first: String, $second: String) {
              updatePassword(first: $first, second: $second) {
                id
                __typename
              }
            }
            """
            
            let variables: [String: String] = [
                "first": newPassword,
                "second": newPassword
            ]
            
            let graphQLRequest = UpdatePasswordRequest(
                operationName: "updatePassword",
                variables: variables,
                query: updatePasswordMutation
            )
            
            request.httpBody = try JSONEncoder().encode(graphQLRequest)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    return false
                }
            }
            
            // Try to decode the response
            let updatePasswordResponse = try JSONDecoder().decode(UpdatePasswordResponse.self, from: data)
            
            // Check if the response contains the expected data
            return updatePasswordResponse.data.updatePassword.id != nil
            
        } catch {
            print("Password update error: \(error)")
            return false
        }
    }
    
    func updateOutsideBundleCeiling(accessToken: String, subscriptionId: String, amount: Int) async -> Bool {
        do {
            guard let url = URL(string: "\(baseURL)/api/graphql") else {
                throw DataError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "authorization")
            request.setValue("https://mijn.50plusmobiel.nl/", forHTTPHeaderField: "Referer")
            request.setValue("https://mijn.50plusmobiel.nl", forHTTPHeaderField: "Origin")
            
            let updateOutsideBundleCeilingMutation = """
            mutation updateOutsideBundleCeiling($id: ID!, $value: Int!) {
              updateOutsideBundleCeiling(id: $id, value: $value) {
                redirectUrl
                __typename
              }
            }
            """
            
            let variables = UpdateOutsideBundleCeilingVariables(
                id: subscriptionId,
                value: amount
            )
            
            let graphQLRequest = UpdateOutsideBundleCeilingRequest(
                operationName: "updateOutsideBundleCeiling",
                variables: variables,
                query: updateOutsideBundleCeilingMutation
            )
            
            request.httpBody = try JSONEncoder().encode(graphQLRequest)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    print("HTTP Error: \(httpResponse.statusCode)")
                    return false
                }
            }
            
            // Try to decode the response
            let updateResponse = try JSONDecoder().decode(UpdateOutsideBundleCeilingResponse.self, from: data)
            
            // Open the payment URL
            if let redirectUrl = URL(string: updateResponse.data.updateOutsideBundleCeiling.redirectUrl) {
                await MainActor.run {
                    UIApplication.shared.open(redirectUrl)
                }
            }
            
            return true
            
        } catch {
            print("Update outside bundle ceiling error: \(error)")
            return false
        }
    }
    
    private func shareDataWithWidget(customer: Customer) {
        // IMPORTANT: Replace "group.com.yourcompany.DataCheck" with your App Group ID
        guard let userDefaults = UserDefaults(suiteName: "group.shadowfly.DataCheck"),
              let balance = customer.subscriptionGroups.first?.msisdns.first?.balance else {
            return
        }
        
        userDefaults.set(balance.dataAvailable, forKey: "dataAvailable")
        userDefaults.set(balance.dataAssigned, forKey: "dataAssigned")
        
        // Reload the widget timeline to show the new data
        WidgetCenter.shared.reloadAllTimelines()
    }
}

enum DataError: LocalizedError {
    case invalidURL
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
