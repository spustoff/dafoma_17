//
//  SettingsService.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import Foundation

class SettingsService: ObservableObject {
    private let settingsKey = "aerotracker_settings"
    private let documentsDirectory: URL
    private let settingsFileName = "app_settings.json"
    
    init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    // MARK: - Settings Management
    
    func saveSettings(_ settings: Settings) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let settingsData = try encoder.encode(settings)
            let fileURL = documentsDirectory.appendingPathComponent(settingsFileName)
            
            try settingsData.write(to: fileURL)
            
            // Also save to UserDefaults as backup
            UserDefaults.standard.set(settingsData, forKey: settingsKey)
            
            print("✅ Settings saved successfully")
        } catch {
            print("❌ Failed to save settings: \(error)")
            throw SettingsServiceError.saveFailed(error)
        }
    }
    
    func loadSettings() async throws -> Settings {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Try to load from file first
        let fileURL = documentsDirectory.appendingPathComponent(settingsFileName)
        
        if let settingsData = try? Data(contentsOf: fileURL),
           let settings = try? decoder.decode(Settings.self, from: settingsData) {
            print("✅ Settings loaded from file")
            return settings
        }
        
        // Fallback to UserDefaults
        if let settingsData = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? decoder.decode(Settings.self, from: settingsData) {
            print("✅ Settings loaded from UserDefaults")
            return settings
        }
        
        // If no settings exist, create default ones
        print("🆕 Creating default settings")
        let defaultSettings = createDefaultSettings()
        try await saveSettings(defaultSettings)
        return defaultSettings
    }
    
    private func createDefaultSettings() -> Settings {
        return Settings(
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
                dataFields: createDefaultDataFields(),
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
    }
    
    private func createDefaultDataFields() -> [DataField] {
        return [
            DataField(type: .duration, isEnabled: true, position: 0, size: .large),
            DataField(type: .distance, isEnabled: true, position: 1, size: .large),
            DataField(type: .pace, isEnabled: true, position: 2, size: .medium),
            DataField(type: .heartRate, isEnabled: false, position: 3, size: .medium),
            DataField(type: .calories, isEnabled: true, position: 4, size: .small),
            DataField(type: .elevation, isEnabled: false, position: 5, size: .small)
        ]
    }
    
    // MARK: - Theme Management
    
    func applyTheme(_ theme: AppTheme) async throws {
        var settings = try await loadSettings()
        settings.display.theme = theme
        
        // Update system theme preference
        settings.display.useSystemTheme = (theme == .system)
        
        try await saveSettings(settings)
    }
    
    func updateAccentColor(_ color: String) async throws {
        var settings = try await loadSettings()
        settings.display.accentColor = color
        settings.display.customColors.accentColor = color
        settings.display.customColors.primaryColor = color
        
        try await saveSettings(settings)
    }
    
    // MARK: - Notification Settings
    
    func updateNotificationSettings(_ notificationSettings: NotificationSettings) async throws {
        var settings = try await loadSettings()
        settings.notifications = notificationSettings
        
        try await saveSettings(settings)
    }
    
    // MARK: - Workout Settings
    
    func updateWorkoutSettings(_ workoutSettings: WorkoutSettings) async throws {
        var settings = try await loadSettings()
        settings.workout = workoutSettings
        
        try await saveSettings(settings)
    }
    
    func updateHeartRateZones(maxHeartRate: Int, restingHeartRate: Int) async throws {
        var settings = try await loadSettings()
        settings.workout.heartRateZones = HeartRateZones(
            maxHeartRate: maxHeartRate,
            restingHeartRate: restingHeartRate
        )
        
        try await saveSettings(settings)
    }
    
    // MARK: - Data Management
    
    func exportData(format: ExportFormat) async throws -> URL {
        let exportDirectory = documentsDirectory.appendingPathComponent("exports")
        
        // Create export directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: exportDirectory.path) {
            try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
        }
        
        let timestamp = DateFormatter().string(from: Date())
        let fileName = "aerotracker_export_\(timestamp).\(format.rawValue)"
        let exportURL = exportDirectory.appendingPathComponent(fileName)
        
        switch format {
        case .json:
            try await exportAsJSON(to: exportURL)
        case .csv:
            try await exportAsCSV(to: exportURL)
        case .gpx:
            try await exportAsGPX(to: exportURL)
        case .tcx:
            try await exportAsTCX(to: exportURL)
        }
        
        return exportURL
    }
    
    private func exportAsJSON(to url: URL) async throws {
        let settings = try await loadSettings()
        
        // Create comprehensive export data
        let exportData = ExportData(
            settings: settings,
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let jsonData = try encoder.encode(exportData)
        try jsonData.write(to: url)
    }
    
    private func exportAsCSV(to url: URL) async throws {
        let settings = try await loadSettings()
        
        var csvContent = "Setting Category,Setting Name,Value\n"
        
        // General settings
        csvContent += "General,Units,\(settings.general.units.displayName)\n"
        csvContent += "General,Language,\(settings.general.language)\n"
        csvContent += "General,Haptic Feedback,\(settings.general.hapticFeedback)\n"
        csvContent += "General,Sound Effects,\(settings.general.soundEffects)\n"
        
        // Workout settings
        csvContent += "Workout,Auto Start,\(settings.workout.autoStart)\n"
        csvContent += "Workout,Auto Pause,\(settings.workout.autoPause)\n"
        csvContent += "Workout,GPS Accuracy,\(settings.workout.gpsAccuracy.displayName)\n"
        
        // Display settings
        csvContent += "Display,Theme,\(settings.display.theme.displayName)\n"
        csvContent += "Display,Accent Color,\(settings.display.accentColor)\n"
        csvContent += "Display,Font Size,\(settings.display.fontSize.displayName)\n"
        
        try csvContent.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func exportAsGPX(to url: URL) async throws {
        // For settings export, GPX doesn't make much sense, but we'll create a basic file
        let gpxContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Aerotracker Settings Export">
            <!-- Settings export not applicable for GPX format -->
        </gpx>
        """
        
        try gpxContent.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func exportAsTCX(to url: URL) async throws {
        // For settings export, TCX doesn't make much sense, but we'll create a basic file
        let tcxContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">
            <!-- Settings export not applicable for TCX format -->
        </TrainingCenterDatabase>
        """
        
        try tcxContent.write(to: url, atomically: true, encoding: .utf8)
    }
    
    func importSettings(from url: URL) async throws {
        let settingsData = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Try to decode as ExportData first
        if let exportData = try? decoder.decode(ExportData.self, from: settingsData) {
            try await saveSettings(exportData.settings)
        } else {
            // Try to decode as Settings directly
            let settings = try decoder.decode(Settings.self, from: settingsData)
            try await saveSettings(settings)
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache() async throws {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let appCacheDirectory = cacheDirectory.appendingPathComponent("Aerotracker")
        
        if FileManager.default.fileExists(atPath: appCacheDirectory.path) {
            try FileManager.default.removeItem(at: appCacheDirectory)
            print("✅ Cache cleared successfully")
        }
    }
    
    func getCacheSize() async throws -> Int64 {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let appCacheDirectory = cacheDirectory.appendingPathComponent("Aerotracker")
        
        guard FileManager.default.fileExists(atPath: appCacheDirectory.path) else {
            return 0
        }
        
        let resourceKeys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey]
        let fileEnumerator = FileManager.default.enumerator(
            at: appCacheDirectory,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        )
        
        var totalSize: Int64 = 0
        
        guard let fileEnumerator = fileEnumerator else {
            return 0
        }
        
        for case let fileURL as URL in fileEnumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            
            if !resourceValues.isDirectory! {
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }
        }
        
        return totalSize
    }
    
    // MARK: - Data Cleanup
    
    func clearAllData() async throws {
        // Clear settings file
        let settingsURL = documentsDirectory.appendingPathComponent(settingsFileName)
        if FileManager.default.fileExists(atPath: settingsURL.path) {
            try FileManager.default.removeItem(at: settingsURL)
        }
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: settingsKey)
        
        // Clear cache
        try await clearCache()
        
        print("✅ All app data cleared")
    }
    
    // MARK: - Reset to Defaults
    
    func resetToDefaults() async throws {
        let defaultSettings = createDefaultSettings()
        try await saveSettings(defaultSettings)
        print("✅ Settings reset to defaults")
    }
    
    // MARK: - Settings Validation
    
    func validateSettings(_ settings: Settings) throws {
        // Validate heart rate zones
        let zones = settings.workout.heartRateZones
        guard zones.maxHeartRate > zones.restingHeartRate,
              zones.maxHeartRate >= 120, zones.maxHeartRate <= 220,
              zones.restingHeartRate >= 40, zones.restingHeartRate <= 100 else {
            throw SettingsServiceError.invalidHeartRateZones
        }
        
        // Validate target pace if set
        if let targetPace = settings.workout.targetPace {
            guard targetPace > 0, targetPace <= 15 else {
                throw SettingsServiceError.invalidTargetPace
            }
        }
        
        // Validate target heart rate if set
        if let targetHeartRate = settings.workout.targetHeartRate {
            guard targetHeartRate >= 100, targetHeartRate <= 200 else {
                throw SettingsServiceError.invalidTargetHeartRate
            }
        }
        
        // Validate color formats
        guard settings.display.accentColor.hasPrefix("#"),
              settings.display.accentColor.count == 7 else {
            throw SettingsServiceError.invalidColorFormat
        }
    }
    
    // MARK: - Settings Migration
    
    func migrateSettingsIfNeeded() async throws {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let savedVersion = UserDefaults.standard.string(forKey: "app_version") ?? "1.0"
        
        if currentVersion != savedVersion {
            print("🔄 Migrating settings from \(savedVersion) to \(currentVersion)")
            
            // Perform migration logic here based on version differences
            // For now, we'll just update the version
            
            UserDefaults.standard.set(currentVersion, forKey: "app_version")
            print("✅ Settings migration completed")
        }
    }
}

// MARK: - Supporting Structures

private struct ExportData: Codable {
    let settings: Settings
    let exportDate: Date
    let appVersion: String
}

// MARK: - Error Types

enum SettingsServiceError: LocalizedError {
    case saveFailed(Error)
    case loadFailed(Error)
    case invalidHeartRateZones
    case invalidTargetPace
    case invalidTargetHeartRate
    case invalidColorFormat
    case migrationFailed(Error)
    case exportFailed(Error)
    case importFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save settings: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load settings: \(error.localizedDescription)"
        case .invalidHeartRateZones:
            return "Invalid heart rate zones configuration"
        case .invalidTargetPace:
            return "Target pace must be between 0 and 15 minutes per kilometer"
        case .invalidTargetHeartRate:
            return "Target heart rate must be between 100 and 200 BPM"
        case .invalidColorFormat:
            return "Color must be in hex format (#RRGGBB)"
        case .migrationFailed(let error):
            return "Settings migration failed: \(error.localizedDescription)"
        case .exportFailed(let error):
            return "Failed to export data: \(error.localizedDescription)"
        case .importFailed(let error):
            return "Failed to import settings: \(error.localizedDescription)"
        }
    }
} 