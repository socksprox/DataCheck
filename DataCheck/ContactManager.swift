//
//  ContactManager.swift
//  DataCheck
//
//  Created by socksprox on 27.09.25.
//

import Foundation
import Contacts
import SwiftUI
import Combine

@MainActor
class ContactManager: ObservableObject {
    @Published var contactsPermissionStatus: CNAuthorizationStatus = .notDetermined
    @Published var showContactNames: Bool = false {
        didSet {
            UserDefaults.standard.set(showContactNames, forKey: "showContactNames")
        }
    }
    
    private let contactStore = CNContactStore()
    private var contacts: [CNContact] = []
    
    init() {
        // Load saved preference
        showContactNames = UserDefaults.standard.bool(forKey: "showContactNames")
        updatePermissionStatus()
        
        // Load contacts if permission is already granted
        if contactsPermissionStatus == .authorized {
            loadContacts()
        }
    }
    
    func updatePermissionStatus() {
        contactsPermissionStatus = CNContactStore.authorizationStatus(for: .contacts)
    }
    
    func requestContactsPermission() async -> Bool {
        do {
            let granted = try await contactStore.requestAccess(for: .contacts)
            updatePermissionStatus()
            if granted {
                loadContacts()
            }
            return granted
        } catch {
            print("Error requesting contacts permission: \(error)")
            updatePermissionStatus()
            return false
        }
    }
    
    private func loadContacts() {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        
        do {
            contacts.removeAll()
            try contactStore.enumerateContacts(with: request) { contact, _ in
                self.contacts.append(contact)
            }
        } catch {
            print("Error loading contacts: \(error)")
        }
    }
    
    func getContactName(for phoneNumber: String) -> String? {
        guard showContactNames && contactsPermissionStatus == .authorized else {
            return nil
        }
        
        // Clean the phone number for comparison
        let cleanedNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        for contact in contacts {
            for phoneNumberValue in contact.phoneNumbers {
                let contactNumber = phoneNumberValue.value.stringValue.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                
                // Check if the numbers match (allowing for different formats)
                if cleanedNumber.hasSuffix(contactNumber) || contactNumber.hasSuffix(cleanedNumber) {
                    let firstName = contact.givenName
                    let lastName = contact.familyName
                    
                    if !firstName.isEmpty && !lastName.isEmpty {
                        return "\(firstName) \(lastName)"
                    } else if !firstName.isEmpty {
                        return firstName
                    } else if !lastName.isEmpty {
                        return lastName
                    }
                }
            }
        }
        
        return nil
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}
