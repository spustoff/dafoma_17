//
//  Activity.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import Foundation
import CoreLocation

struct Activity: Identifiable, Codable {
    let id = UUID()
    var type: ActivityType
    var name: String
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var distance: Double // in meters
    var calories: Int
    var averageHeartRate: Int?
    var maxHeartRate: Int?
    var averageSpeed: Double // in m/s
    var maxSpeed: Double // in m/s
    var elevationGain: Double? // in meters
    var route: [LocationPoint]
    var intensity: ActivityIntensity
    var notes: String?
    var weather: WeatherData?
    var isCompleted: Bool
    var achievements: [Achievement]
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedDistance: String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
    
    var formattedSpeed: String {
        let kmh = averageSpeed * 3.6
        return String(format: "%.1f km/h", kmh)
    }
    
    var intensityColor: String {
        switch intensity {
        case .low: return "#4CAF50"
        case .moderate: return "#FF9800"
        case .high: return "#F44336"
        case .extreme: return "#9C27B0"
        }
    }
}

enum ActivityType: String, CaseIterable, Codable {
    case running = "running"
    case cycling = "cycling"
    case walking = "walking"
    case swimming = "swimming"
    case hiking = "hiking"
    case yoga = "yoga"
    case gym = "gym"
    case basketball = "basketball"
    case football = "football"
    case tennis = "tennis"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        case .yoga: return "Yoga"
        case .gym: return "Gym Workout"
        case .basketball: return "Basketball"
        case .football: return "Football"
        case .tennis: return "Tennis"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .walking: return "figure.walk"
        case .swimming: return "figure.pool.swim"
        case .hiking: return "figure.hiking"
        case .yoga: return "figure.yoga"
        case .gym: return "dumbbell"
        case .basketball: return "basketball"
        case .football: return "football"
        case .tennis: return "tennisball"
        case .other: return "figure.strengthtraining.traditional"
        }
    }
}

enum ActivityIntensity: String, CaseIterable, Codable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case extreme = "extreme"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .extreme: return "Extreme"
        }
    }
}

struct LocationPoint: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let altitude: Double?
    let speed: Double?
    let heartRate: Int?
}

struct WeatherData: Codable {
    let temperature: Double // in Celsius
    let humidity: Double // percentage
    let windSpeed: Double // in m/s
    let condition: String
    let icon: String
}

struct Achievement: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let earnedDate: Date
    let category: AchievementCategory
}

enum AchievementCategory: String, CaseIterable, Codable {
    case distance = "distance"
    case duration = "duration"
    case speed = "speed"
    case consistency = "consistency"
    case milestone = "milestone"
    
    var displayName: String {
        switch self {
        case .distance: return "Distance"
        case .duration: return "Duration"
        case .speed: return "Speed"
        case .consistency: return "Consistency"
        case .milestone: return "Milestone"
        }
    }
} 