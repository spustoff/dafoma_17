//
//  AerotrackerApp.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import SwiftUI

@main
struct AerotrackerApp: App {
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @StateObject private var activityViewModel = ActivityViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingViewModel.shouldShowOnboarding {
                    OnboardingView()
                        .environmentObject(onboardingViewModel)
                } else {
                    ContentView()
                        .environmentObject(activityViewModel)
                        .environmentObject(settingsViewModel)
                        .environmentObject(profileViewModel)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
