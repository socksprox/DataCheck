//
//  Models.swift
//  DataCheck
//
//  Created by socksprox on 26.09.25.
//

import Foundation

// MARK: - Authentication Models
struct LoginRequest: Codable {
    let username: String
    let phoneNumber: String?
    let password: String
    let step: String
    let response: String
}

struct LoginResponse: Codable {
    let step: String
    let message: String?
}

struct TokenRequest: Codable {
    let username: String
    let password: String
}

struct TokenResponse: Codable {
    let tokenType: String
    let expiresIn: Int
    let accessToken: String
    let refreshToken: String
    let token: String
    
    enum CodingKeys: String, CodingKey {
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case token
    }
}

// MARK: - GraphQL Models
struct GraphQLRequest: Codable {
    let variables: [String: String]
    let query: String
}

struct CdrGraphQLRequest: Codable {
    let operationName: String
    let variables: [String: AnyCodable]
    let query: String
}

struct AnyCodable: Codable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = ()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}

struct GraphQLResponse: Codable {
    let data: CustomerData
}

struct CustomerData: Codable {
    let me: Customer
}

struct Customer: Codable {
    let id: String
    let charge: Double
    let canRenew: String?
    let renewalUrl: String?
    let subscriptionGroups: [SubscriptionGroup]
    let iccidSwaps: [IccidSwap]
    
    enum CodingKeys: String, CodingKey {
        case id, charge, canRenew, renewalUrl, subscriptionGroups, iccidSwaps
    }
}

struct SubscriptionGroup: Codable {
    let id: String
    let remainingBeforeBill: Int
    let unlockingAllowed: Bool
    let contractUnlocked: Bool
    let referralCode: String?
    let nextRenewedSubscriptionDate: String?
    let msisdns: [MSISDN]
    let koreClenMigrationInProgress: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, remainingBeforeBill, unlockingAllowed, contractUnlocked
        case referralCode, nextRenewedSubscriptionDate, msisdns, koreClenMigrationInProgress
    }
}

struct MSISDN: Codable {
    let id: String
    let localizedName: String
    let thresholds: Threshold
    let balance: Balance
}

struct Threshold: Codable {
    let relevantCeiling: Double
}

struct Balance: Codable {
    let voiceAvailable: Double?
    let voiceAssigned: Double?
    let voicePercentage: Double
    let smsAvailable: Double?
    let smsAssigned: Double?
    let smsPercentage: Double
    let dataAvailable: Double
    let dataAssigned: Double
    let dataPercentage: Double
}

struct IccidSwap: Codable {
    let id: String
}

// MARK: - Subscription Models
struct SubscriptionGraphQLResponse: Codable {
    let data: SubscriptionData
}

struct SubscriptionData: Codable {
    let me: SubscriptionCustomer
}

struct SubscriptionCustomer: Codable {
    let id: String
    let wallet: Wallet
    let allowAddOns: Bool
    let invoicePeriods: [Int]
    let maxLatePaymentDays: Int
    let latePayments: [Int]
    let subscriptionGroups: [DetailedSubscriptionGroup]
    let iccidSwaps: [IccidSwap]
    
    enum CodingKeys: String, CodingKey {
        case id, wallet, allowAddOns, invoicePeriods, latePayments, subscriptionGroups, iccidSwaps
        case maxLatePaymentDays = "MAX_LATE_PAYMENT_DAYS"
    }
}

struct Wallet: Codable {
    let id: String
    let balance: Double
}

struct DetailedSubscriptionGroup: Codable {
    let id: String
    let isCleverEnable: Bool
    let startDate: String
    let endDate: String
    let activeContract: Contract?
    let nextContract: Contract?
    let activeSubscriptionGroupBundle: SubscriptionGroupBundle?
    let nextSubscriptionGroupBundle: SubscriptionGroupBundle?
    let msisdns: [DetailedMSISDN]
    let availableAddOns: [AddOn]
    let temporaryAddOns: [TemporaryAddOn]
    let koreClenMigrationInProgress: Bool
}

struct Contract: Codable {
    let startDate: String
    let endDate: String
    let originalEndDate: String
}

struct SubscriptionGroupBundle: Codable {
    let id: String
    let startDate: String?
    let recurringAddOns: [RecurringAddOn]?
    let details: BundleDetails
    let hasAvailableUpgrades: Bool?
}

struct RecurringAddOn: Codable {
    let id: String
    let name: String
    let active: Bool
}

struct BundleDetails: Codable {
    let marketingData: MarketingData
    let campaignRows: [String]
    let priceForecast: [String]
}

struct MarketingData: Codable {
    let minutes: Int
    let sms: Int
    let data: Int
}

struct DetailedMSISDN: Codable {
    let id: String
    let cooldown: Bool
    let active: Bool
    let suspended: Bool
    let hardSuspended: Bool
    let activating: Bool
    let msisdn: String
    let thresholds: Threshold
    let iccid: ICCID
    let voicemailEnabled: Bool
    let optionalServices: [OptionalService]
}

struct ICCID: Codable {
    let iccid: String
    let puk1: String
}

struct OptionalService: Codable {
    let displayName: String
    let enabled: Bool
}

struct AddOn: Codable {
    let id: String
    let name: String
    let priceGroup: PriceGroup
}

struct PriceGroup: Codable {
    let id: String
    let price: Double
    let priceArrangements: [PriceArrangement]
}

struct PriceArrangement: Codable {
    let description: String
}

struct TemporaryAddOn: Codable {
    let name: String
}

// MARK: - Profile Models
struct ProfileGraphQLResponse: Codable {
    let data: ProfileData
}

struct ProfileData: Codable {
    let me: ProfileCustomer
}

struct ProfileCustomer: Codable {
    let id: String
    let prefix: String
    let firstName: String
    let lastName: String
    let email: String
    let invoiceAddress: Address
    let iban: String
}

struct Address: Codable {
    let street: String
    let number: String
    let addendum: String?
    let postalCode: String
    let city: String
}

struct CdrDataResponse: Codable {
    let data: CdrData
}

struct CdrData: Codable {
    let cdrData: [CdrRecord]
}

struct CdrRecord: Codable, Identifiable, Equatable {
    var id: String { startDate }
    let startDate: String
    let cdrType: String
    let retailCharge: Double
    let originalRetailCharge: Double?
    let otherParty: String?
    let aLocation: String?
    let aCountry: String?
    let duration: String
    let durationInBundle: String?
}

// MARK: - Password Update Models
struct UpdatePasswordRequest: Codable {
    let operationName: String
    let variables: [String: String]
    let query: String
}

struct UpdatePasswordResponse: Codable {
    let data: UpdatePasswordData
}

struct UpdatePasswordData: Codable {
    let updatePassword: UpdatePasswordResult
}

struct UpdatePasswordResult: Codable {
    let id: String?
    let __typename: String?
}

// MARK: - Update Outside Bundle Ceiling Models
struct UpdateOutsideBundleCeilingRequest: Codable {
    let operationName: String
    let variables: UpdateOutsideBundleCeilingVariables
    let query: String
}

struct UpdateOutsideBundleCeilingVariables: Codable {
    let id: String
    let value: Int
}

struct UpdateOutsideBundleCeilingResponse: Codable {
    let data: UpdateOutsideBundleCeilingData
}

struct UpdateOutsideBundleCeilingData: Codable {
    let updateOutsideBundleCeiling: UpdateOutsideBundleCeilingResult
}

struct UpdateOutsideBundleCeilingResult: Codable {
    let redirectUrl: String
    let __typename: String
}
