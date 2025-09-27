//
//  SettingsView.swift
//  DataCheck
//
//  Created by socksprox on 27.09.25.
//

import SwiftUI
import Contacts

struct SettingsView: View {
    @StateObject private var contactManager = ContactManager()
    @State private var showingPermissionAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("General")) {
                Button(action: {
                    // Open the app's settings in the Settings app
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "globe")
                        Text("Language")
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
            }
            
            Section(header: Text(NSLocalizedString("contact_settings", comment: ""))) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(NSLocalizedString("show_contact_names", comment: ""), isOn: $contactManager.showContactNames)
                        .onChange(of: contactManager.showContactNames) { newValue in
                            if newValue && contactManager.contactsPermissionStatus != .authorized {
                                // Request permission when toggle is turned on
                                Task {
                                    let granted = await contactManager.requestContactsPermission()
                                    if !granted {
                                        await MainActor.run {
                                            contactManager.showContactNames = false
                                            showingPermissionAlert = true
                                        }
                                    }
                                }
                            }
                        }
                    
                    Text(NSLocalizedString("show_contact_names_description", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if contactManager.contactsPermissionStatus == .denied {
                        Button(NSLocalizedString("open_settings", comment: "")) {
                            contactManager.openSettings()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("app_settings", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .alert(NSLocalizedString("contacts_permission_required", comment: ""), isPresented: $showingPermissionAlert) {
            Button(NSLocalizedString("open_settings", comment: "")) {
                contactManager.openSettings()
            }
            Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { }
        } message: {
            Text(NSLocalizedString("contacts_access_denied", comment: ""))
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
}
