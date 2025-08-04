//
//  User.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import Foundation

struct User: Codable, Identifiable {
    let id = UUID()
    var name: String
    var email: String?
    var age: Int?
    var weight: Double? // in kg
    var height: Double? // in cm
    var gender: Gender?
    var fitnessLevel: FitnessLevel
    var goals: [FitnessGoal]
    var profileImageURL: String?
    var createdAt: Date
    var lastActiveDate: Date
    var preferences: UserPreferences
    var statistics: UserStatistics
    var badges: [Badge]
    var streaks: [Streak]
    
    var bmi: Double? {
        guard let weight = weight, let height = height, height > 0 else { return nil }
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    var bmiCategory: String {
        guard let bmi = bmi else { return "Unknown" }
        
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }
    
    var displayName: String {
        return name.isEmpty ? "User" : name
    }
}

enum Gender: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"
    case other = "other"
    case preferNotToSay = "prefer_not_to_say"
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

enum FitnessLevel: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return "New to fitness or returning after a break"
        case .intermediate: return "Regular exercise, comfortable with basic movements"
        case .advanced: return "Consistent training, experienced with various exercises"
        case .expert: return "Highly experienced, training at competitive level"
        }
    }
}

struct FitnessGoal: Identifiable, Codable {
    let id = UUID()
    var type: GoalType
    var targetValue: Double
    var currentValue: Double
    var startDate: Date
    var targetDate: Date
    var isCompleted: Bool
    var title: String
    var description: String?
    
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }
    
    var progressPercentage: Int {
        return Int(progress * 100)
    }
}

enum GoalType: String, CaseIterable, Codable {
    case weightLoss = "weight_loss"
    case weightGain = "weight_gain"
    case distancePerWeek = "distance_per_week"
    case workoutsPerWeek = "workouts_per_week"
    case caloriesBurn = "calories_burn"
    case runningPace = "running_pace"
    case strengthGain = "strength_gain"
    case enduranceImprovement = "endurance_improvement"
    
    var displayName: String {
        switch self {
        case .weightLoss: return "Weight Loss"
        case .weightGain: return "Weight Gain"
        case .distancePerWeek: return "Weekly Distance"
        case .workoutsPerWeek: return "Weekly Workouts"
        case .caloriesBurn: return "Calories Burned"
        case .runningPace: return "Running Pace"
        case .strengthGain: return "Strength Building"
        case .enduranceImprovement: return "Endurance"
        }
    }
    
    var unit: String {
        switch self {
        case .weightLoss, .weightGain: return "kg"
        case .distancePerWeek: return "km"
        case .workoutsPerWeek: return "sessions"
        case .caloriesBurn: return "calories"
        case .runningPace: return "min/km"
        case .strengthGain: return "kg"
        case .enduranceImprovement: return "minutes"
        }
    }
}

struct UserPreferences: Codable {
    var units: UnitSystem
    var notifications: NotificationSettings
    var privacy: PrivacySettings
    var theme: ThemeSettings
    var autoDetectActivity: Bool
    var shareData: Bool
    var voiceCoaching: Bool
    var hapticFeedback: Bool
}

enum UnitSystem: String, CaseIterable, Codable {
    case metric = "metric"
    case imperial = "imperial"
    
    var displayName: String {
        switch self {
        case .metric: return "Metric (km, kg, °C)"
        case .imperial: return "Imperial (mi, lb, °F)"
        }
    }
}

struct NotificationSettings: Codable {
    var workoutReminders: Bool
    var goalProgress: Bool
    var achievements: Bool
    var socialUpdates: Bool
    var weeklyReports: Bool
    var motivationalQuotes: Bool
}

struct PrivacySettings: Codable {
    var shareActivities: Bool
    var shareLocation: Bool
    var shareProgress: Bool
    var allowFriendRequests: Bool
    var publicProfile: Bool
}

struct ThemeSettings: Codable {
    var accentColor: String
    var useSystemTheme: Bool
    var animationsEnabled: Bool
    var reducedMotion: Bool
}

struct UserStatistics: Codable {
    var totalActivities: Int
    var totalDistance: Double
    var totalDuration: TimeInterval
    var totalCaloriesBurned: Int
    var averageWorkoutsPerWeek: Double
    var longestStreak: Int
    var currentStreak: Int
    var favoriteActivityType: ActivityType?
    var totalElevationGain: Double
    var personalRecords: [PersonalRecord]
    var monthlyStats: [MonthlyStats]
}

struct PersonalRecord: Identifiable, Codable {
    let id = UUID()
    var activityType: ActivityType
    var recordType: RecordType
    var value: Double
    var achievedDate: Date
    var activityId: UUID?
}

enum RecordType: String, CaseIterable, Codable {
    case longestDistance = "longest_distance"
    case longestDuration = "longest_duration"
    case fastestPace = "fastest_pace"
    case mostCaloriesBurned = "most_calories_burned"
    case highestElevationGain = "highest_elevation_gain"
    
    var displayName: String {
        switch self {
        case .longestDistance: return "Longest Distance"
        case .longestDuration: return "Longest Duration"
        case .fastestPace: return "Fastest Pace"
        case .mostCaloriesBurned: return "Most Calories Burned"
        case .highestElevationGain: return "Highest Elevation Gain"
        }
    }
}

struct MonthlyStats: Identifiable, Codable {
    let id = UUID()
    var month: Int
    var year: Int
    var totalActivities: Int
    var totalDistance: Double
    var totalDuration: TimeInterval
    var totalCalories: Int
    var averageWorkoutsPerWeek: Double
}

struct Badge: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var icon: String
    var color: String
    var earnedDate: Date
    var category: BadgeCategory
    var rarity: BadgeRarity
}

enum BadgeCategory: String, CaseIterable, Codable {
    case distance = "distance"
    case speed = "speed"
    case consistency = "consistency"
    case achievement = "achievement"
    case social = "social"
    case special = "special"
}

enum BadgeRarity: String, CaseIterable, Codable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var color: String {
        switch self {
        case .common: return "#9E9E9E"
        case .rare: return "#2196F3"
        case .epic: return "#9C27B0"
        case .legendary: return "#FF9800"
        }
    }
}

struct Streak: Identifiable, Codable {
    let id = UUID()
    var type: StreakType
    var currentCount: Int
    var longestCount: Int
    var startDate: Date
    var lastActiveDate: Date
    var isActive: Bool
}

enum StreakType: String, CaseIterable, Codable {
    case dailyWorkout = "daily_workout"
    case weeklyGoal = "weekly_goal"
    case monthlyChallenge = "monthly_challenge"
    case runningStreak = "running_streak"
    
    var displayName: String {
        switch self {
        case .dailyWorkout: return "Daily Workout"
        case .weeklyGoal: return "Weekly Goal"
        case .monthlyChallenge: return "Monthly Challenge"
        case .runningStreak: return "Running Streak"
        }
    }
} 