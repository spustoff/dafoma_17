//
//  OnboardingViewModel.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import Foundation
import SwiftUI

class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var shouldShowOnboarding: Bool = true
    @Published var user: User
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // User input data
    @Published var userName: String = ""
    @Published var userAge: String = ""
    @Published var userWeight: String = ""
    @Published var userHeight: String = ""
    @Published var selectedGender: Gender?
    @Published var selectedFitnessLevel: FitnessLevel = .beginner
    @Published var selectedGoals: Set<GoalType> = []
    @Published var agreedToTerms: Bool = false
    @Published var allowNotifications: Bool = false
    @Published var allowLocationAccess: Bool = false
    
    private let userService = UserService()
    private let settingsService = SettingsService()
    
    init() {
        // Check if user has completed onboarding
        self.shouldShowOnboarding = !UserDefaults.standard.bool(forKey: "onboarding_completed")
        
        // Initialize default user
        let currentDate = Date()
        self.user = User(
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
    
    func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                currentStep = .personalSetup
            case .personalSetup:
                if validatePersonalSetup() {
                    updateUserFromInput()
                    currentStep = .featureShowcase
                }
            case .featureShowcase:
                currentStep = .permissions
            case .permissions:
                currentStep = .readyToGo
            case .readyToGo:
                completeOnboarding()
            }
        }
    }
    
    func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                break
            case .personalSetup:
                currentStep = .welcome
            case .featureShowcase:
                currentStep = .personalSetup
            case .permissions:
                currentStep = .featureShowcase
            case .readyToGo:
                currentStep = .permissions
            }
        }
    }
    
    func skipOnboarding() {
        completeOnboarding()
    }
    
    private func validatePersonalSetup() -> Bool {
        guard !userName.trimmingCharacters(in: .whitespaces).isEmpty else {
            showErrorMessage("Please enter your name")
            return false
        }
        
        if !userAge.isEmpty {
            guard let age = Int(userAge), age >= 13, age <= 120 else {
                showErrorMessage("Please enter a valid age (13-120)")
                return false
            }
        }
        
        if !userWeight.isEmpty {
            guard let weight = Double(userWeight), weight > 0, weight <= 500 else {
                showErrorMessage("Please enter a valid weight")
                return false
            }
        }
        
        if !userHeight.isEmpty {
            guard let height = Double(userHeight), height > 0, height <= 300 else {
                showErrorMessage("Please enter a valid height")
                return false
            }
        }
        
        return true
    }
    
    private func updateUserFromInput() {
        user.name = userName.trimmingCharacters(in: .whitespaces)
        
        if !userAge.isEmpty, let age = Int(userAge) {
            user.age = age
        }
        
        if !userWeight.isEmpty, let weight = Double(userWeight) {
            user.weight = weight
        }
        
        if !userHeight.isEmpty, let height = Double(userHeight) {
            user.height = height
        }
        
        user.gender = selectedGender
        user.fitnessLevel = selectedFitnessLevel
        
        // Convert selected goals to FitnessGoal objects
        user.goals = selectedGoals.map { goalType in
            FitnessGoal(
                type: goalType,
                targetValue: getDefaultTargetValue(for: goalType),
                currentValue: 0,
                startDate: Date(),
                targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
                isCompleted: false,
                title: goalType.displayName,
                description: "Achieve your \(goalType.displayName.lowercased()) goal"
            )
        }
    }
    
    private func getDefaultTargetValue(for goalType: GoalType) -> Double {
        switch goalType {
        case .weightLoss:
            return 5.0 // 5 kg
        case .weightGain:
            return 3.0 // 3 kg
        case .distancePerWeek:
            return 10.0 // 10 km per week
        case .workoutsPerWeek:
            return 3.0 // 3 workouts per week
        case .caloriesBurn:
            return 2000.0 // 2000 calories per week
        case .runningPace:
            return 6.0 // 6 min/km
        case .strengthGain:
            return 10.0 // 10% strength increase
        case .enduranceImprovement:
            return 30.0 // 30 minutes continuous activity
        }
    }
    
    private func completeOnboarding() {
        isLoading = true
        
        // Save user data
        Task {
            do {
                try await userService.saveUser(user)
                
                // Mark onboarding as completed
                await MainActor.run {
                    UserDefaults.standard.set(true, forKey: "onboarding_completed")
                    shouldShowOnboarding = false
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    showErrorMessage("Failed to save user data: \(error.localizedDescription)")
                    isLoading = false
                }
            }
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        // Auto dismiss error after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showError = false
        }
    }
    
    func requestLocationPermission() {
        // This would integrate with CoreLocation
        allowLocationAccess = true
    }
    
    func requestNotificationPermission() {
        // This would integrate with UserNotifications
        allowNotifications = true
    }
    
    var canProceedFromPersonalSetup: Bool {
        return !userName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var canCompleteOnboarding: Bool {
        return agreedToTerms
    }
    
    var progressPercentage: Double {
        switch currentStep {
        case .welcome: return 0.25
        case .personalSetup: return 0.5
        case .featureShowcase: return 0.75
        case .permissions: return 0.9
        case .readyToGo: return 1.0
        }
    }
}

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case personalSetup = 1
    case featureShowcase = 2
    case permissions = 3
    case readyToGo = 4
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to Aerotracker"
        case .personalSetup:
            return "Personal Setup"
        case .featureShowcase:
            return "Features"
        case .permissions:
            return "Permissions"
        case .readyToGo:
            return "Ready to Go!"
        }
    }
    
    var subtitle: String {
        switch self {
        case .welcome:
            return "Your journey to better fitness starts here"
        case .personalSetup:
            return "Help us personalize your experience"
        case .featureShowcase:
            return "Discover what makes Aerotracker special"
        case .permissions:
            return "Enable features for the best experience"
        case .readyToGo:
            return "Everything is set up and ready"
        }
    }
} 