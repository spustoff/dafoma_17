//
//  ProfileViewModel.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import Foundation
import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var showingEditProfile: Bool = false
    @Published var showingAchievements: Bool = false
    @Published var showingStatistics: Bool = false
    @Published var showingGoals: Bool = false
    
    // Edit profile form data
    @Published var editName: String = ""
    @Published var editAge: String = ""
    @Published var editWeight: String = ""
    @Published var editHeight: String = ""
    @Published var editGender: Gender?
    @Published var editFitnessLevel: FitnessLevel = .beginner
    
    // Statistics
    @Published var weeklyProgress: [DailyProgress] = []
    @Published var monthlyProgress: [WeeklyProgress] = []
    @Published var yearlyProgress: [MonthlyProgress] = []
    @Published var recentActivities: [Activity] = []
    @Published var topAchievements: [Badge] = []
    @Published var currentGoals: [FitnessGoal] = []
    @Published var activeStreaks: [Streak] = []
    
    // Analytics
    @Published var selectedTimeframe: TimeFrame = .week
    @Published var selectedMetric: ProfileMetric = .activities
    
    private let userService = UserService()
    private let activityService = ActivityService()
    
    init() {
        loadUserProfile()
        loadStatistics()
    }
    
    func loadUserProfile() {
        isLoading = true
        
        Task {
            do {
                let loadedUser = try await userService.loadUser()
                await MainActor.run {
                    self.user = loadedUser
                    self.setupEditFormData()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.showErrorMessage("Failed to load user profile: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func saveUserProfile() {
        guard var user = user else { return }
        
        // Validate edit form data
        guard validateEditForm() else { return }
        
        // Update user with edit form data
        user.name = editName.trimmingCharacters(in: .whitespaces)
        
        if !editAge.isEmpty, let age = Int(editAge) {
            user.age = age
        } else {
            user.age = nil
        }
        
        if !editWeight.isEmpty, let weight = Double(editWeight) {
            user.weight = weight
        } else {
            user.weight = nil
        }
        
        if !editHeight.isEmpty, let height = Double(editHeight) {
            user.height = height
        } else {
            user.height = nil
        }
        
        user.gender = editGender
        user.fitnessLevel = editFitnessLevel
        user.lastActiveDate = Date()
        
        isLoading = true
        
        Task {
            do {
                try await userService.saveUser(user)
                await MainActor.run {
                    self.user = user
                    self.showingEditProfile = false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.showErrorMessage("Failed to save profile: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func loadStatistics() {
        Task {
            do {
                let stats = try await userService.loadUserStatistics()
                let activities = try await activityService.loadRecentActivities(limit: 5)
                
                await MainActor.run {
                    self.updateStatistics(stats)
                    self.recentActivities = activities
                    self.generateProgressData()
                }
            } catch {
                await MainActor.run {
                    self.showErrorMessage("Failed to load statistics: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func addGoal(_ goal: FitnessGoal) {
        guard var user = user else { return }
        
        user.goals.append(goal)
        
        Task {
            do {
                try await userService.saveUser(user)
                await MainActor.run {
                    self.user = user
                    self.currentGoals = user.goals.filter { !$0.isCompleted }
                }
            } catch {
                await MainActor.run {
                    self.showErrorMessage("Failed to add goal: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func updateGoal(_ goal: FitnessGoal) {
        guard var user = user else { return }
        
        if let index = user.goals.firstIndex(where: { $0.id == goal.id }) {
            user.goals[index] = goal
            
            Task {
                do {
                    try await userService.saveUser(user)
                    await MainActor.run {
                        self.user = user
                        self.currentGoals = user.goals.filter { !$0.isCompleted }
                    }
                } catch {
                    await MainActor.run {
                        self.showErrorMessage("Failed to update goal: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func deleteGoal(_ goal: FitnessGoal) {
        guard var user = user else { return }
        
        user.goals.removeAll { $0.id == goal.id }
        
        Task {
            do {
                try await userService.saveUser(user)
                await MainActor.run {
                    self.user = user
                    self.currentGoals = user.goals.filter { !$0.isCompleted }
                }
            } catch {
                await MainActor.run {
                    self.showErrorMessage("Failed to delete goal: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func setupEditFormData() {
        guard let user = user else { return }
        
        editName = user.name
        editAge = user.age?.description ?? ""
        editWeight = user.weight?.description ?? ""
        editHeight = user.height?.description ?? ""
        editGender = user.gender
        editFitnessLevel = user.fitnessLevel
    }
    
    private func validateEditForm() -> Bool {
        guard !editName.trimmingCharacters(in: .whitespaces).isEmpty else {
            showErrorMessage("Name cannot be empty")
            return false
        }
        
        if !editAge.isEmpty {
            guard let age = Int(editAge), age >= 13, age <= 120 else {
                showErrorMessage("Please enter a valid age (13-120)")
                return false
            }
        }
        
        if !editWeight.isEmpty {
            guard let weight = Double(editWeight), weight > 0, weight <= 500 else {
                showErrorMessage("Please enter a valid weight")
                return false
            }
        }
        
        if !editHeight.isEmpty {
            guard let height = Double(editHeight), height > 0, height <= 300 else {
                showErrorMessage("Please enter a valid height")
                return false
            }
        }
        
        return true
    }
    
    private func updateStatistics(_ stats: UserStatistics) {
        guard let user = user else { return }
        
        currentGoals = user.goals.filter { !$0.isCompleted }
        activeStreaks = user.streaks.filter { $0.isActive }
        topAchievements = user.badges.sorted { $0.earnedDate > $1.earnedDate }.prefix(6).map { $0 }
    }
    
    private func generateProgressData() {
        // Generate weekly progress (7 days)
        weeklyProgress = generateDailyProgress()
        
        // Generate monthly progress (4 weeks)
        monthlyProgress = generateWeeklyProgress()
        
        // Generate yearly progress (12 months)
        yearlyProgress = generateMonthlyProgress()
    }
    
    private func generateDailyProgress() -> [DailyProgress] {
        var progress: [DailyProgress] = []
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                // Filter activities for this day
                let dayActivities = recentActivities.filter { activity in
                    calendar.isDate(activity.startTime, inSameDayAs: date)
                }
                
                let totalDistance = dayActivities.reduce(0) { $0 + $1.distance }
                let totalDuration = dayActivities.reduce(0) { $0 + $1.duration }
                let totalCalories = dayActivities.reduce(0) { $0 + $1.calories }
                
                progress.append(DailyProgress(
                    date: date,
                    activities: dayActivities.count,
                    distance: totalDistance,
                    duration: totalDuration,
                    calories: totalCalories
                ))
            }
        }
        
        return progress.reversed()
    }
    
    private func generateWeeklyProgress() -> [WeeklyProgress] {
        var progress: [WeeklyProgress] = []
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<4 {
            if let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: today) {
                let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
                
                // Filter activities for this week
                let weekActivities = recentActivities.filter { activity in
                    activity.startTime >= weekStart && activity.startTime <= weekEnd
                }
                
                let totalDistance = weekActivities.reduce(0) { $0 + $1.distance }
                let totalDuration = weekActivities.reduce(0) { $0 + $1.duration }
                let totalCalories = weekActivities.reduce(0) { $0 + $1.calories }
                
                progress.append(WeeklyProgress(
                    weekStart: weekStart,
                    weekEnd: weekEnd,
                    activities: weekActivities.count,
                    distance: totalDistance,
                    duration: totalDuration,
                    calories: totalCalories
                ))
            }
        }
        
        return progress.reversed()
    }
    
    private func generateMonthlyProgress() -> [MonthlyProgress] {
        var progress: [MonthlyProgress] = []
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<12 {
            if let monthStart = calendar.date(byAdding: .month, value: -i, to: today) {
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
                
                // Filter activities for this month
                let monthActivities = recentActivities.filter { activity in
                    activity.startTime >= monthStart && activity.startTime < monthEnd
                }
                
                let totalDistance = monthActivities.reduce(0) { $0 + $1.distance }
                let totalDuration = monthActivities.reduce(0) { $0 + $1.duration }
                let totalCalories = monthActivities.reduce(0) { $0 + $1.calories }
                
                progress.append(MonthlyProgress(
                    month: calendar.component(.month, from: monthStart),
                    year: calendar.component(.year, from: monthStart),
                    activities: monthActivities.count,
                    distance: totalDistance,
                    duration: totalDuration,
                    calories: totalCalories
                ))
            }
        }
        
        return progress.reversed()
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showError = false
        }
    }
    
    // Computed properties
    var displayName: String {
        user?.displayName ?? "User"
    }
    
    var memberSince: String {
        guard let user = user else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Member since \(formatter.string(from: user.createdAt))"
    }
    
    var totalActivitiesCount: Int {
        user?.statistics.totalActivities ?? 0
    }
    
    var totalDistance: String {
        guard let user = user else { return "0 km" }
        
        let distance = user.statistics.totalDistance
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
    
    var totalDuration: String {
        guard let user = user else { return "0h 0m" }
        
        let duration = user.statistics.totalDuration
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        return "\(hours)h \(minutes)m"
    }
    
    var currentStreak: Int {
        user?.statistics.currentStreak ?? 0
    }
    
    var longestStreak: Int {
        user?.statistics.longestStreak ?? 0
    }
    
    var bmiInfo: (value: Double?, category: String) {
        guard let user = user else { return (nil, "Unknown") }
        return (user.bmi, user.bmiCategory)
    }
    
    var completedGoalsCount: Int {
        user?.goals.filter { $0.isCompleted }.count ?? 0
    }
    
    var totalBadgesCount: Int {
        user?.badges.count ?? 0
    }
    
    var favoriteActivity: String {
        user?.statistics.favoriteActivityType?.displayName ?? "None"
    }
}

enum TimeFrame: String, CaseIterable {
    case week = "week"
    case month = "month"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
}

enum ProfileMetric: String, CaseIterable {
    case activities = "activities"
    case distance = "distance"
    case duration = "duration"
    case calories = "calories"
    
    var displayName: String {
        switch self {
        case .activities: return "Activities"
        case .distance: return "Distance"
        case .duration: return "Duration"
        case .calories: return "Calories"
        }
    }
    
    var unit: String {
        switch self {
        case .activities: return "activities"
        case .distance: return "km"
        case .duration: return "minutes"
        case .calories: return "cal"
        }
    }
}

struct DailyProgress {
    let date: Date
    let activities: Int
    let distance: Double
    let duration: TimeInterval
    let calories: Int
    
    var displayValue: Double {
        distance / 1000 // Convert to km
    }
}

struct WeeklyProgress {
    let weekStart: Date
    let weekEnd: Date
    let activities: Int
    let distance: Double
    let duration: TimeInterval
    let calories: Int
    
    var displayValue: Double {
        distance / 1000 // Convert to km
    }
}

struct MonthlyProgress {
    let month: Int
    let year: Int
    let activities: Int
    let distance: Double
    let duration: TimeInterval
    let calories: Int
    
    var displayValue: Double {
        distance / 1000 // Convert to km
    }
    
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let date = Calendar.current.date(from: DateComponents(year: year, month: month)) ?? Date()
        return formatter.string(from: date)
    }
} 