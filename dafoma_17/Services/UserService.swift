//
//  UserService.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import Foundation

class UserService: ObservableObject {
    private let userDefaultsKey = "aerotracker_user"
    private let documentsDirectory: URL
    private let userDataFileName = "user_data.json"
    
    init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    // MARK: - User Management
    
    @MainActor
    func saveUser(_ user: User) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let userData = try encoder.encode(user)
            let fileURL = documentsDirectory.appendingPathComponent(userDataFileName)
            try userData.write(to: fileURL)
            
            // Also save to UserDefaults as backup
            UserDefaults.standard.set(userData, forKey: userDefaultsKey)
            
            print("✅ User data saved successfully")
        } catch {
            print("❌ Failed to save user data: \(error)")
            throw UserServiceError.saveFailed(error)
        }
    }
    
    @MainActor
    func loadUser() async throws -> User {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Try to load from file first
        let fileURL = documentsDirectory.appendingPathComponent(userDataFileName)
        
        if let userData = try? Data(contentsOf: fileURL),
           let user = try? decoder.decode(User.self, from: userData) {
            print("✅ User data loaded from file")
            return user
        }
        
        // Fallback to UserDefaults
        if let userData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? decoder.decode(User.self, from: userData) {
            print("✅ User data loaded from UserDefaults")
            return user
        }
        
        // If no user exists, create a default one
        print("🆕 Creating new user")
        return createDefaultUser()
    }
    
    func loadUserStatistics() async throws -> UserStatistics {
        let user = try await loadUser()
        return user.statistics
    }
    
    private func createDefaultUser() -> User {
        let currentDate = Date()
        
        return User(
            name: "",
            email: nil,
            age: nil,
            weight: nil,
            height: nil,
            gender: nil,
            fitnessLevel: .beginner,
            goals: [],
            profileImageURL: nil,
            createdAt: currentDate,
            lastActiveDate: currentDate,
            preferences: UserPreferences(
                units: .metric,
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
                theme: ThemeSettings(
                    accentColor: "#01A2FF",
                    useSystemTheme: false,
                    animationsEnabled: true,
                    reducedMotion: false
                ),
                autoDetectActivity: true,
                shareData: false,
                voiceCoaching: false,
                hapticFeedback: true
            ),
            statistics: UserStatistics(
                totalActivities: 0,
                totalDistance: 0,
                totalDuration: 0,
                totalCaloriesBurned: 0,
                averageWorkoutsPerWeek: 0,
                longestStreak: 0,
                currentStreak: 0,
                favoriteActivityType: nil,
                totalElevationGain: 0,
                personalRecords: [],
                monthlyStats: []
            ),
            badges: [],
            streaks: []
        )
    }
    
    // MARK: - Goals Management
    
    func addGoal(_ goal: FitnessGoal, to user: User) async throws {
        var updatedUser = user
        updatedUser.goals.append(goal)
        try await saveUser(updatedUser)
    }
    
    func updateGoal(_ goal: FitnessGoal, for user: User) async throws {
        var updatedUser = user
        
        if let index = updatedUser.goals.firstIndex(where: { $0.id == goal.id }) {
            updatedUser.goals[index] = goal
            try await saveUser(updatedUser)
        } else {
            throw UserServiceError.goalNotFound
        }
    }
    
    func deleteGoal(with id: UUID, from user: User) async throws {
        var updatedUser = user
        updatedUser.goals.removeAll { $0.id == id }
        try await saveUser(updatedUser)
    }
    
    // MARK: - Badges and Achievements
    
    func addBadge(_ badge: Badge, to user: User) async throws {
        var updatedUser = user
        updatedUser.badges.append(badge)
        try await saveUser(updatedUser)
    }
    
    func updateStreak(_ streak: Streak, for user: User) async throws {
        var updatedUser = user
        
        if let index = updatedUser.streaks.firstIndex(where: { $0.id == streak.id }) {
            updatedUser.streaks[index] = streak
        } else {
            updatedUser.streaks.append(streak)
        }
        
        try await saveUser(updatedUser)
    }
    
    // MARK: - Statistics Updates
    
    func updateStatistics(with activity: Activity, for user: User) async throws {
        var updatedUser = user
        var stats = updatedUser.statistics
        
        // Update basic statistics
        stats.totalActivities += 1
        stats.totalDistance += activity.distance
        stats.totalDuration += activity.duration
        stats.totalCaloriesBurned += activity.calories
        
        if let elevation = activity.elevationGain {
            stats.totalElevationGain += elevation
        }
        
        // Update favorite activity type
        updateFavoriteActivityType(&stats, with: activity.type, user: updatedUser)
        
        // Update personal records
        updatePersonalRecords(&stats, with: activity)
        
        // Update weekly average
        updateWeeklyAverage(&stats, user: updatedUser)
        
        // Update monthly stats
        updateMonthlyStats(&stats, with: activity)
        
        // Update streaks
        updateStreaks(&updatedUser, with: activity)
        
        updatedUser.statistics = stats
        updatedUser.lastActiveDate = Date()
        
        try await saveUser(updatedUser)
    }
    
    private func updateFavoriteActivityType(_ stats: inout UserStatistics, with activityType: ActivityType, user: User) {
        // Count activities by type
        var activityCounts: [ActivityType: Int] = [:]
        
        // This would normally come from loading all activities
        // For now, we'll use a simple heuristic
        activityCounts[activityType] = (activityCounts[activityType] ?? 0) + 1
        
        if let mostFrequent = activityCounts.max(by: { $0.value < $1.value }) {
            stats.favoriteActivityType = mostFrequent.key
        }
    }
    
    private func updatePersonalRecords(_ stats: inout UserStatistics, with activity: Activity) {
        let activityType = activity.type
        
        // Check for longest distance record
        if let existingDistanceRecord = stats.personalRecords.first(where: { 
            $0.activityType == activityType && $0.recordType == .longestDistance 
        }) {
            if activity.distance > existingDistanceRecord.value {
                if let index = stats.personalRecords.firstIndex(where: { $0.id == existingDistanceRecord.id }) {
                    stats.personalRecords[index].value = activity.distance
                    stats.personalRecords[index].achievedDate = activity.startTime
                    stats.personalRecords[index].activityId = activity.id
                }
            }
        } else {
            stats.personalRecords.append(PersonalRecord(
                activityType: activityType,
                recordType: .longestDistance,
                value: activity.distance,
                achievedDate: activity.startTime,
                activityId: activity.id
            ))
        }
        
        // Check for longest duration record
        if let existingDurationRecord = stats.personalRecords.first(where: { 
            $0.activityType == activityType && $0.recordType == .longestDuration 
        }) {
            if activity.duration > existingDurationRecord.value {
                if let index = stats.personalRecords.firstIndex(where: { $0.id == existingDurationRecord.id }) {
                    stats.personalRecords[index].value = activity.duration
                    stats.personalRecords[index].achievedDate = activity.startTime
                    stats.personalRecords[index].activityId = activity.id
                }
            }
        } else {
            stats.personalRecords.append(PersonalRecord(
                activityType: activityType,
                recordType: .longestDuration,
                value: activity.duration,
                achievedDate: activity.startTime,
                activityId: activity.id
            ))
        }
        
        // Check for fastest pace record (only for activities with distance)
        if activity.distance > 0 {
            let pace = activity.duration / (activity.distance / 1000) // minutes per km
            
            if let existingPaceRecord = stats.personalRecords.first(where: { 
                $0.activityType == activityType && $0.recordType == .fastestPace 
            }) {
                if pace < existingPaceRecord.value { // Lower is better for pace
                    if let index = stats.personalRecords.firstIndex(where: { $0.id == existingPaceRecord.id }) {
                        stats.personalRecords[index].value = pace
                        stats.personalRecords[index].achievedDate = activity.startTime
                        stats.personalRecords[index].activityId = activity.id
                    }
                }
            } else {
                stats.personalRecords.append(PersonalRecord(
                    activityType: activityType,
                    recordType: .fastestPace,
                    value: pace,
                    achievedDate: activity.startTime,
                    activityId: activity.id
                ))
            }
        }
        
        // Check for calories burned record
        if let existingCaloriesRecord = stats.personalRecords.first(where: { 
            $0.activityType == activityType && $0.recordType == .mostCaloriesBurned 
        }) {
            if Double(activity.calories) > existingCaloriesRecord.value {
                if let index = stats.personalRecords.firstIndex(where: { $0.id == existingCaloriesRecord.id }) {
                    stats.personalRecords[index].value = Double(activity.calories)
                    stats.personalRecords[index].achievedDate = activity.startTime
                    stats.personalRecords[index].activityId = activity.id
                }
            }
        } else {
            stats.personalRecords.append(PersonalRecord(
                activityType: activityType,
                recordType: .mostCaloriesBurned,
                value: Double(activity.calories),
                achievedDate: activity.startTime,
                activityId: activity.id
            ))
        }
    }
    
    private func updateWeeklyAverage(_ stats: inout UserStatistics, user: User) {
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: user.createdAt, to: Date()).day ?? 0
        let weeksSinceCreation = max(Double(daysSinceCreation) / 7.0, 1.0)
        
        stats.averageWorkoutsPerWeek = Double(stats.totalActivities) / weeksSinceCreation
    }
    
    private func updateMonthlyStats(_ stats: inout UserStatistics, with activity: Activity) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: activity.startTime)
        let year = calendar.component(.year, from: activity.startTime)
        
        if let index = stats.monthlyStats.firstIndex(where: { $0.month == month && $0.year == year }) {
            stats.monthlyStats[index].totalActivities += 1
            stats.monthlyStats[index].totalDistance += activity.distance
            stats.monthlyStats[index].totalDuration += activity.duration
            stats.monthlyStats[index].totalCalories += activity.calories
        } else {
            stats.monthlyStats.append(MonthlyStats(
                month: month,
                year: year,
                totalActivities: 1,
                totalDistance: activity.distance,
                totalDuration: activity.duration,
                totalCalories: activity.calories,
                averageWorkoutsPerWeek: 0 // This would be calculated differently
            ))
        }
    }
    
    private func updateStreaks(_ user: inout User, with activity: Activity) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let activityDate = calendar.startOfDay(for: activity.startTime)
        
        // Update daily workout streak
        if let dailyStreakIndex = user.streaks.firstIndex(where: { $0.type == .dailyWorkout }) {
            var dailyStreak = user.streaks[dailyStreakIndex]
            
            let daysSinceLastActivity = calendar.dateComponents([.day], from: dailyStreak.lastActiveDate, to: activityDate).day ?? 0
            
            if daysSinceLastActivity == 1 {
                // Consecutive day
                dailyStreak.currentCount += 1
                dailyStreak.longestCount = max(dailyStreak.longestCount, dailyStreak.currentCount)
            } else if daysSinceLastActivity == 0 {
                // Same day, no change to streak
            } else {
                // Streak broken, restart
                dailyStreak.currentCount = 1
            }
            
            dailyStreak.lastActiveDate = activityDate
            dailyStreak.isActive = calendar.dateComponents([.day], from: activityDate, to: today).day ?? 0 <= 1
            
            user.streaks[dailyStreakIndex] = dailyStreak
        } else {
            // Create new daily streak
            user.streaks.append(Streak(
                type: .dailyWorkout,
                currentCount: 1,
                longestCount: 1,
                startDate: activityDate,
                lastActiveDate: activityDate,
                isActive: true
            ))
        }
        
        // Update current and longest streaks in statistics
        if let dailyStreak = user.streaks.first(where: { $0.type == .dailyWorkout }) {
            user.statistics.currentStreak = dailyStreak.currentCount
            user.statistics.longestStreak = dailyStreak.longestCount
        }
    }
    
    // MARK: - Data Export/Import
    
    func exportUserData() async throws -> URL {
        let user = try await loadUser()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let userData = try encoder.encode(user)
        
        let exportURL = documentsDirectory.appendingPathComponent("aerotracker_user_export.json")
        try userData.write(to: exportURL)
        
        return exportURL
    }
    
    func importUserData(from url: URL) async throws {
        let userData = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let user = try decoder.decode(User.self, from: userData)
        try await saveUser(user)
    }
    
    // MARK: - User Deletion
    
    func deleteUser() async throws {
        let fileURL = documentsDirectory.appendingPathComponent(userDataFileName)
        
        // Remove from file system
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        // Remove from UserDefaults
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        
        // Reset onboarding flag
        UserDefaults.standard.removeObject(forKey: "onboarding_completed")
        
        print("✅ User data deleted successfully")
    }
}

// MARK: - Error Types

enum UserServiceError: LocalizedError {
    case saveFailed(Error)
    case loadFailed(Error)
    case goalNotFound
    case invalidData
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save user data: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load user data: \(error.localizedDescription)"
        case .goalNotFound:
            return "Goal not found"
        case .invalidData:
            return "Invalid user data format"
        case .fileNotFound:
            return "User data file not found"
        }
    }
} 