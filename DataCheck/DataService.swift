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
    
    private let baseURL = "https://mijn.50plusmobiel.nl"
    
    private let customerDataCacheKey = "customerData"
    private let subscriptionDataCacheKey = "subscriptionData"
    private let profileDataCacheKey = "profileData"

    func fetchCustomerData(accessToken: String) async {
        // Load from cache first
        if let cachedData: Customer = CacheManager.shared.loadData(forKey: customerDataCacheKey) {
            self.customerData = cachedData
        } else {
            isLoading = true
        }
        errorMessage = nil
        
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
              me {
                id
                charge
                canRenew
                renewalUrl
                subscriptionGroups {
                  id
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
                      __typename
                    }
                    __typename
                  }
                  koreClenMigrationInProgress
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
            
            let graphQLRequest = GraphQLRequest(variables: [:], query: graphQLQuery)
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
            {
              me {
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
                  koreClenMigrationInProgress
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
            
            let graphQLRequest = GraphQLRequest(variables: [:], query: subscriptionQuery)
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
            {
              me {
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
            
            let graphQLRequest = GraphQLRequest(variables: [:], query: profileQuery)
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
                "types": AnyCodable([] as [Int])
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
