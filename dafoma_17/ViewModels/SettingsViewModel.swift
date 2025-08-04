//
//  SettingsViewModel.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import Foundation
import SwiftUI
import UserNotifications

class SettingsViewModel: ObservableObject {
    @Published var settings: Settings
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var showingDataExport: Bool = false
    @Published var showingAbout: Bool = false
    @Published var showingPrivacyPolicy: Bool = false
    @Published var showingTermsOfService: Bool = false
    
    // Temporary settings for editing
    @Published var tempMaxHeartRate: String = ""
    @Published var tempRestingHeartRate: String = ""
    @Published var tempTargetPace: String = ""
    @Published var tempTargetHeartRate: String = ""
    
    private let settingsService = SettingsService()
    
    init() {
        // Load default settings with placeholder dataFields first
        var tempSettings = Settings(
            general: GeneralSettings(
                units: .metric,
                language: "en",
                autoLock: false,
                hapticFeedback: true,
                soundEffects: true,
                voiceCoaching: false,
                keepScreenOn: false,
                batteryOptimization: true
            ),
            workout: WorkoutSettings(
                autoStart: false,
                autoPause: true,
                autoDetectActivity: true,
                gpsAccuracy: .high,
                heartRateZones: HeartRateZones(maxHeartRate: 190, restingHeartRate: 60),
                targetPace: nil,
                targetHeartRate: nil,
                workoutReminders: true,
                restReminders: false,
                intervalTraining: IntervalSettings(
                    warmupDuration: 300,
                    cooldownDuration: 300,
                    workInterval: 120,
                    restInterval: 60,
                    rounds: 5,
                    autoAdvance: true,
                    audioPrompts: true
                ),
                safetyFeatures: SafetySettings(
                    emergencyContacts: [],
                    shareLocationWithContacts: false,
                    automaticCrashDetection: false,
                    inactivityAlerts: true,
                    lowBatteryWarning: true,
                    nightModeAutomatic: true
                )
            ),
            notifications: NotificationSettings(
                workoutReminders: true,
                goalProgress: true,
                achievements: true,
                socialUpdates: false,
                weeklyReports: true,
                motivationalQuotes: false
            ),
            privacy: PrivacySettings(
                shareActivities: false,
                shareLocation: false,
                shareProgress: false,
                allowFriendRequests: true,
                publicProfile: false
            ),
            display: DisplaySettings(
                theme: .darkBlue,
                accentColor: "#01A2FF",
                useSystemTheme: false,
                animationsEnabled: true,
                reducedMotion: false,
                highContrast: false,
                fontSize: .medium,
                mapStyle: .standard,
                dataFields: [], // Placeholder, will be set below
                customColors: CustomColorScheme(
                    primaryColor: "#01A2FF",
                    secondaryColor: "#1A2339",
                    accentColor: "#01A2FF",
                    backgroundColor: "#090F1E",
                    surfaceColor: "#1A2339",
                    textColor: "#FFFFFF",
                    cardColor: "#2A3A4F"
                )
            ),
            data: DataSettings(
                autoSync: true,
                cloudBackup: false,
                localStorageLimit: .fiveGB,
                exportFormat: .gpx,
                dataRetention: .oneYear,
                shareAnalytics: false,
                cacheMaps: true,
                offlineMode: false
            ),
            social: SocialSettings(
                shareActivities: false,
                autoShare: false,
                allowFriendRequests: true,
                showOnLeaderboards: false,
                publicProfile: false,
                shareLocation: false,
                shareProgress: false,
                allowComments: true,
                allowLikes: true,
                communityFeatures: false
            ),
            advanced: AdvancedSettings(
                developerMode: false,
                debugLogging: false,
                experimentalFeatures: false,
                customAPIEndpoint: nil,
                maxMemoryUsage: .medium,
                networkTimeout: 30,
                cacheStrategy: .balanced,
                locationUpdateFrequency: .medium
            )
        )
        
        // Now set the dataFields after self is initialized
        tempSettings.display.dataFields = Self.createDefaultDataFields()
        self.settings = tempSettings
        
        loadSettings()
        setupTemporaryValues()
    }
    
    func loadSettings() {
        isLoading = true
        
        Task {
            do {
                let loadedSettings = try await settingsService.loadSettings()
                await MainActor.run {
                    self.settings = loadedSettings
                    self.setupTemporaryValues()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.showErrorMessage("Failed to load settings: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func saveSettings() {
        isLoading = true
        
        Task {
            do {
                try await settingsService.saveSettings(settings)
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.showErrorMessage("Failed to save settings: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func resetToDefaults() {
        settings = Settings(
            general: GeneralSettings(
                units: .metric,
                language: "en",
                autoLock: false,
                hapticFeedback: true,
                soundEffects: true,
                voiceCoaching: false,
                keepScreenOn: false,
                batteryOptimization: true
            ),
            workout: WorkoutSettings(
                autoStart: false,
                autoPause: true,
                autoDetectActivity: true,
                gpsAccuracy: .high,
                heartRateZones: HeartRateZones(maxHeartRate: 190, restingHeartRate: 60),
                targetPace: nil,
                targetHeartRate: nil,
                workoutReminders: true,
                restReminders: false,
                intervalTraining: IntervalSettings(
                    warmupDuration: 300,
                    cooldownDuration: 300,
                    workInterval: 120,
                    restInterval: 60,
                    rounds: 5,
                    autoAdvance: true,
                    audioPrompts: true
                ),
                safetyFeatures: SafetySettings(
                    emergencyContacts: [],
                    shareLocationWithContacts: false,
                    automaticCrashDetection: false,
                    inactivityAlerts: true,
                    lowBatteryWarning: true,
                    nightModeAutomatic: true
                )
            ),
            notifications: settings.notifications,
            privacy: settings.privacy,
            display: settings.display,
            data: settings.data,
            social: settings.social,
            advanced: settings.advanced
        )
        
        saveSettings()
    }
    
    private func setupTemporaryValues() {
        tempMaxHeartRate = String(settings.workout.heartRateZones.maxHeartRate)
        tempRestingHeartRate = String(settings.workout.heartRateZones.restingHeartRate)
        tempTargetPace = settings.workout.targetPace?.description ?? ""
        tempTargetHeartRate = settings.workout.targetHeartRate?.description ?? ""
    }
    
    func updateHeartRateZones() {
        guard let maxHR = Int(tempMaxHeartRate),
              let restingHR = Int(tempRestingHeartRate),
              maxHR > restingHR,
              maxHR >= 120, maxHR <= 220,
              restingHR >= 40, restingHR <= 100 else {
            showErrorMessage("Please enter valid heart rate values")
            return
        }
        
        settings.workout.heartRateZones = HeartRateZones(
            maxHeartRate: maxHR,
            restingHeartRate: restingHR
        )
        
        saveSettings()
    }
    
    func updateTargetPace() {
        if tempTargetPace.isEmpty {
            settings.workout.targetPace = nil
        } else {
            guard let pace = Double(tempTargetPace), pace > 0, pace <= 15 else {
                showErrorMessage("Please enter a valid pace (0-15 min/km)")
                return
            }
            settings.workout.targetPace = pace
        }
        
        saveSettings()
    }
    
    func updateTargetHeartRate() {
        if tempTargetHeartRate.isEmpty {
            settings.workout.targetHeartRate = nil
        } else {
            guard let heartRate = Int(tempTargetHeartRate),
                  heartRate >= 100, heartRate <= 200 else {
                showErrorMessage("Please enter a valid heart rate (100-200 bpm)")
                return
            }
            settings.workout.targetHeartRate = heartRate
        }
        
        saveSettings()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.settings.notifications.workoutReminders = true
                    self.saveSettings()
                } else if let error = error {
                    self.showErrorMessage("Notification permission denied: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func exportData(format: ExportFormat) {
        isLoading = true
        
        Task {
            do {
                let exportURL = try await settingsService.exportData(format: format)
                await MainActor.run {
                    self.isLoading = false
                    // Here you would present sharing sheet
                    self.showingDataExport = true
                }
            } catch {
                await MainActor.run {
                    self.showErrorMessage("Failed to export data: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func clearCache() {
        Task {
            do {
                try await settingsService.clearCache()
                await MainActor.run {
                    // Show success message
                }
            } catch {
                await MainActor.run {
                    self.showErrorMessage("Failed to clear cache: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func clearAllData() {
        Task {
            do {
                try await settingsService.clearAllData()
                await MainActor.run {
                    // Show success message and possibly restart app
                }
            } catch {
                await MainActor.run {
                    self.showErrorMessage("Failed to clear data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private static func createDefaultDataFields() -> [DataField] {
        return [
            DataField(type: .duration, isEnabled: true, position: 0, size: .large),
            DataField(type: .distance, isEnabled: true, position: 1, size: .large),
            DataField(type: .pace, isEnabled: true, position: 2, size: .medium),
            DataField(type: .heartRate, isEnabled: false, position: 3, size: .medium),
            DataField(type: .calories, isEnabled: true, position: 4, size: .small),
            DataField(type: .elevation, isEnabled: false, position: 5, size: .small)
        ]
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showError = false
        }
    }
    
    // Computed properties for easy access
    var currentTheme: AppTheme {
        settings.display.theme
    }
    
    var accentColor: Color {
        Color(hex: settings.display.accentColor) ?? Color.blue
    }
    
    var backgroundColor: Color {
        Color(hex: settings.display.customColors.backgroundColor) ?? Color.black
    }
    
    var surfaceColor: Color {
        Color(hex: settings.display.customColors.surfaceColor) ?? Color.gray
    }
    
    var isNotificationsEnabled: Bool {
        settings.notifications.workoutReminders ||
        settings.notifications.goalProgress ||
        settings.notifications.achievements
    }
    
    var storageUsed: String {
        // This would calculate actual storage usage
        return "245 MB"
    }
    
    var storageLimit: String {
        settings.data.localStorageLimit.displayName
    }
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// Extension to convert hex color strings to SwiftUI Color
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0
        
        let length = hexSanitized.count
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
} 