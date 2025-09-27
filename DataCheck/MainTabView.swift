//
//  MainTabView.swift
//  DataCheck
//
//  Created by socksprox on 26.09.25.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var authService: AuthenticationService
    @StateObject private var dataService = DataService()
    
    var body: some View {
        TabView {
            // Dashboard Tab
            MainDashboardView(authService: authService, dataService: dataService)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Dashboard")
                }
            
            // Subscription Tab
            SubscriptionView(authService: authService, dataService: dataService)
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Subscription")
                }
            
            // Profile Tab
            ProfileView(authService: authService, dataService: dataService)
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
    }
}


#Preview {
    MainTabView(authService: AuthenticationService())
}
