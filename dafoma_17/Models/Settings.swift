//
//  Settings.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import Foundation

struct Settings: Codable {
    var general: GeneralSettings
    var workout: WorkoutSettings
    var notifications: NotificationSettings
    var privacy: PrivacySettings
    var display: DisplaySettings
    var data: DataSettings
    var social: SocialSettings
    var advanced: AdvancedSettings
}

struct GeneralSettings: Codable {
    var units: UnitSystem
    var language: String
    var autoLock: Bool
    var hapticFeedback: Bool
    var soundEffects: Bool
    var voiceCoaching: Bool
    var keepScreenOn: Bool
    var batteryOptimization: Bool
}

struct WorkoutSettings: Codable {
    var autoStart: Bool
    var autoPause: Bool
    var autoDetectActivity: Bool
    var gpsAccuracy: GPSAccuracy
    var heartRateZones: HeartRateZones
    var targetPace: Double?
    var targetHeartRate: Int?
    var workoutReminders: Bool
    var restReminders: Bool
    var intervalTraining: IntervalSettings
    var safetyFeatures: SafetySettings
}

enum GPSAccuracy: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case best = "best"
    
    var displayName: String {
        switch self {
        case .low: return "Low (Battery Saving)"
        case .medium: return "Medium (Balanced)"
        case .high: return "High (Accurate)"
        case .best: return "Best (Most Accurate)"
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Minimal GPS usage, longer battery life"
        case .medium: return "Balanced accuracy and battery usage"
        case .high: return "High accuracy for most activities"
        case .best: return "Maximum accuracy, faster battery drain"
        }
    }
}

struct HeartRateZones: Codable {
    var maxHeartRate: Int
    var restingHeartRate: Int
    var zone1Min: Int // Recovery (50-60% of max)
    var zone1Max: Int
    var zone2Min: Int // Aerobic base (60-70% of max)
    var zone2Max: Int
    var zone3Min: Int // Aerobic (70-80% of max)
    var zone3Max: Int
    var zone4Min: Int // Lactate threshold (80-90% of max)
    var zone4Max: Int
    var zone5Min: Int // Anaerobic (90-100% of max)
    var zone5Max: Int
    
    init(maxHeartRate: Int, restingHeartRate: Int) {
        self.maxHeartRate = maxHeartRate
        self.restingHeartRate = restingHeartRate
        
        // Calculate zones based on percentage of max heart rate
        self.zone1Min = Int(Double(maxHeartRate) * 0.50)
        self.zone1Max = Int(Double(maxHeartRate) * 0.60)
        self.zone2Min = Int(Double(maxHeartRate) * 0.60)
        self.zone2Max = Int(Double(maxHeartRate) * 0.70)
        self.zone3Min = Int(Double(maxHeartRate) * 0.70)
        self.zone3Max = Int(Double(maxHeartRate) * 0.80)
        self.zone4Min = Int(Double(maxHeartRate) * 0.80)
        self.zone4Max = Int(Double(maxHeartRate) * 0.90)
        self.zone5Min = Int(Double(maxHeartRate) * 0.90)
        self.zone5Max = maxHeartRate
    }
    
    func getZone(for heartRate: Int) -> HeartRateZone {
        switch heartRate {
        case zone1Min...zone1Max: return .zone1
        case zone2Min...zone2Max: return .zone2
        case zone3Min...zone3Max: return .zone3
        case zone4Min...zone4Max: return .zone4
        case zone5Min...zone5Max: return .zone5
        default: return heartRate < zone1Min ? .recovery : .maximum
        }
    }
}

enum HeartRateZone: String, CaseIterable, Codable {
    case recovery = "recovery"
    case zone1 = "zone1"
    case zone2 = "zone2"
    case zone3 = "zone3"
    case zone4 = "zone4"
    case zone5 = "zone5"
    case maximum = "maximum"
    
    var displayName: String {
        switch self {
        case .recovery: return "Recovery"
        case .zone1: return "Zone 1 - Active Recovery"
        case .zone2: return "Zone 2 - Aerobic Base"
        case .zone3: return "Zone 3 - Aerobic"
        case .zone4: return "Zone 4 - Lactate Threshold"
        case .zone5: return "Zone 5 - Anaerobic"
        case .maximum: return "Maximum Effort"
        }
    }
    
    var color: String {
        switch self {
        case .recovery: return "#9E9E9E"
        case .zone1: return "#4CAF50"
        case .zone2: return "#8BC34A"
        case .zone3: return "#FFEB3B"
        case .zone4: return "#FF9800"
        case .zone5: return "#F44336"
        case .maximum: return "#9C27B0"
        }
    }
    
    var description: String {
        switch self {
        case .recovery: return "Very light activity for recovery"
        case .zone1: return "Light activity, warm-up pace"
        case .zone2: return "Comfortable aerobic pace"
        case .zone3: return "Moderate aerobic effort"
        case .zone4: return "Hard effort, lactate threshold"
        case .zone5: return "Very hard effort, anaerobic"
        case .maximum: return "Maximum sustainable effort"
        }
    }
}

struct IntervalSettings: Codable {
    var warmupDuration: TimeInterval
    var cooldownDuration: TimeInterval
    var workInterval: TimeInterval
    var restInterval: TimeInterval
    var rounds: Int
    var autoAdvance: Bool
    var audioPrompts: Bool
}

struct SafetySettings: Codable {
    var emergencyContacts: [EmergencyContact]
    var shareLocationWithContacts: Bool
    var automaticCrashDetection: Bool
    var inactivityAlerts: Bool
    var lowBatteryWarning: Bool
    var nightModeAutomatic: Bool
}

struct EmergencyContact: Identifiable, Codable {
    let id = UUID()
    var name: String
    var phoneNumber: String
    var relationship: String
    var isPrimary: Bool
}

struct DisplaySettings: Codable {
    var theme: AppTheme
    var accentColor: String
    var useSystemTheme: Bool
    var animationsEnabled: Bool
    var reducedMotion: Bool
    var highContrast: Bool
    var fontSize: FontSize
    var mapStyle: MapStyle
    var dataFields: [DataField]
    var customColors: CustomColorScheme
}

enum AppTheme: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case darkBlue = "dark_blue"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .darkBlue: return "Dark Blue"
        }
    }
}

enum FontSize: String, CaseIterable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extra_large"
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
    
    var scale: Double {
        switch self {
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        }
    }
}

enum MapStyle: String, CaseIterable, Codable {
    case standard = "standard"
    case satellite = "satellite"
    case hybrid = "hybrid"
    case terrain = "terrain"
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .satellite: return "Satellite"
        case .hybrid: return "Hybrid"
        case .terrain: return "Terrain"
        }
    }
}

struct DataField: Identifiable, Codable {
    let id = UUID()
    var type: DataFieldType
    var isEnabled: Bool
    var position: Int
    var size: DataFieldSize
}

enum DataFieldType: String, CaseIterable, Codable {
    case duration = "duration"
    case distance = "distance"
    case pace = "pace"
    case speed = "speed"
    case heartRate = "heart_rate"
    case calories = "calories"
    case elevation = "elevation"
    case cadence = "cadence"
    case power = "power"
    case temperature = "temperature"
    
    var displayName: String {
        switch self {
        case .duration: return "Duration"
        case .distance: return "Distance"
        case .pace: return "Pace"
        case .speed: return "Speed"
        case .heartRate: return "Heart Rate"
        case .calories: return "Calories"
        case .elevation: return "Elevation"
        case .cadence: return "Cadence"
        case .power: return "Power"
        case .temperature: return "Temperature"
        }
    }
}

enum DataFieldSize: String, CaseIterable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
}

struct CustomColorScheme: Codable {
    var primaryColor: String
    var secondaryColor: String
    var accentColor: String
    var backgroundColor: String
    var surfaceColor: String
    var textColor: String
    var cardColor: String
}

struct DataSettings: Codable {
    var autoSync: Bool
    var cloudBackup: Bool
    var localStorageLimit: DataStorageLimit
    var exportFormat: ExportFormat
    var dataRetention: DataRetentionPeriod
    var shareAnalytics: Bool
    var cacheMaps: Bool
    var offlineMode: Bool
}

enum DataStorageLimit: String, CaseIterable, Codable {
    case unlimited = "unlimited"
    case oneGB = "1gb"
    case fiveGB = "5gb"
    case tenGB = "10gb"
    
    var displayName: String {
        switch self {
        case .unlimited: return "Unlimited"
        case .oneGB: return "1 GB"
        case .fiveGB: return "5 GB"
        case .tenGB: return "10 GB"
        }
    }
}

enum ExportFormat: String, CaseIterable, Codable {
    case gpx = "gpx"
    case tcx = "tcx"
    case csv = "csv"
    case json = "json"
    
    var displayName: String {
        switch self {
        case .gpx: return "GPX"
        case .tcx: return "TCX"
        case .csv: return "CSV"
        case .json: return "JSON"
        }
    }
}

enum DataRetentionPeriod: String, CaseIterable, Codable {
    case forever = "forever"
    case oneYear = "one_year"
    case sixMonths = "six_months"
    case threeMonths = "three_months"
    
    var displayName: String {
        switch self {
        case .forever: return "Forever"
        case .oneYear: return "1 Year"
        case .sixMonths: return "6 Months"
        case .threeMonths: return "3 Months"
        }
    }
}

struct SocialSettings: Codable {
    var shareActivities: Bool
    var autoShare: Bool
    var allowFriendRequests: Bool
    var showOnLeaderboards: Bool
    var publicProfile: Bool
    var shareLocation: Bool
    var shareProgress: Bool
    var allowComments: Bool
    var allowLikes: Bool
    var communityFeatures: Bool
}

struct AdvancedSettings: Codable {
    var developerMode: Bool
    var debugLogging: Bool
    var experimentalFeatures: Bool
    var customAPIEndpoint: String?
    var maxMemoryUsage: MemoryLimit
    var networkTimeout: TimeInterval
    var cacheStrategy: CacheStrategy
    var locationUpdateFrequency: LocationUpdateFrequency
}

enum MemoryLimit: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case unlimited = "unlimited"
    
    var displayName: String {
        switch self {
        case .low: return "Low (128 MB)"
        case .medium: return "Medium (256 MB)"
        case .high: return "High (512 MB)"
        case .unlimited: return "Unlimited"
        }
    }
}

enum CacheStrategy: String, CaseIterable, Codable {
    case minimal = "minimal"
    case balanced = "balanced"
    case aggressive = "aggressive"
    
    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .balanced: return "Balanced"
        case .aggressive: return "Aggressive"
        }
    }
}

enum LocationUpdateFrequency: String, CaseIterable, Codable {
    case low = "low"       // Every 10 seconds
    case medium = "medium" // Every 5 seconds
    case high = "high"     // Every 2 seconds
    case realtime = "realtime" // Every second
    
    var displayName: String {
        switch self {
        case .low: return "Low (10s)"
        case .medium: return "Medium (5s)"
        case .high: return "High (2s)"
        case .realtime: return "Real-time (1s)"
        }
    }
    
    var interval: TimeInterval {
        switch self {
        case .low: return 10.0
        case .medium: return 5.0
        case .high: return 2.0
        case .realtime: return 1.0
        }
    }
} 