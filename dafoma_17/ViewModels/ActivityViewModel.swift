//
//  ActivityViewModel.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import Foundation
import SwiftUI
import CoreLocation
import Combine

class ActivityViewModel: NSObject, ObservableObject {
    @Published var activities: [Activity] = []
    @Published var currentActivity: Activity?
    @Published var isTracking: Bool = false
    @Published var isPaused: Bool = false
    @Published var selectedActivityType: ActivityType = .running
    @Published var searchText: String = ""
    @Published var filterType: ActivityType?
    @Published var sortOrder: SortOrder = .dateDescending
    @Published var showingActivityDetail: Bool = false
    @Published var selectedActivity: Activity?
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // Real-time tracking data
    @Published var currentDuration: TimeInterval = 0
    @Published var currentDistance: Double = 0
    @Published var currentPace: Double = 0
    @Published var currentSpeed: Double = 0
    @Published var currentHeartRate: Int?
    @Published var currentCalories: Int = 0
    @Published var currentElevationGain: Double = 0
    @Published var locationPoints: [LocationPoint] = []
    
    // Statistics
    @Published var weeklyStats: WeeklyStats?
    @Published var monthlyStats: MonthlyStats?
    @Published var personalRecords: [PersonalRecord] = []
    @Published var recentAchievements: [Achievement] = []
    
    private let activityService = ActivityService()
    private let locationManager = CLLocationManager()
    private var trackingTimer: Timer?
    private var startTime: Date?
    private var lastLocation: CLLocation?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupLocationManager()
        loadActivities()
        loadStatistics()
        setupSearchFilter()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupSearchFilter() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.filterActivities()
            }
            .store(in: &cancellables)
    }
    
    func loadActivities() {
        isLoading = true
        
        Task {
            do {
                let loadedActivities = try await activityService.loadActivities()
                await MainActor.run {
                    self.activities = loadedActivities
                    self.filterActivities()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.showErrorMessage("Failed to load activities: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }
    
    func startActivity() {
        guard !isTracking else { return }
        
        startTime = Date()
        currentActivity = Activity(
            type: selectedActivityType,
            name: generateActivityName(),
            startTime: startTime!,
            endTime: nil,
            duration: 0,
            distance: 0,
            calories: 0,
            averageHeartRate: nil,
            maxHeartRate: nil,
            averageSpeed: 0,
            maxSpeed: 0,
            elevationGain: 0,
            route: [],
            intensity: .moderate,
            notes: nil,
            weather: nil,
            isCompleted: false,
            achievements: []
        )
        
        isTracking = true
        isPaused = false
        resetTrackingData()
        startLocationTracking()
        startTrackingTimer()
        
        // Request notification permission if needed
        requestNotificationPermissionIfNeeded()
    }
    
    func pauseActivity() {
        guard isTracking && !isPaused else { return }
        
        isPaused = true
        stopTrackingTimer()
        locationManager.stopUpdatingLocation()
    }
    
    func resumeActivity() {
        guard isTracking && isPaused else { return }
        
        isPaused = false
        startLocationTracking()
        startTrackingTimer()
    }
    
    func stopActivity() {
        guard isTracking else { return }
        
        isTracking = false
        isPaused = false
        stopTrackingTimer()
        locationManager.stopUpdatingLocation()
        
        guard var activity = currentActivity else { return }
        
        // Finalize activity data
        activity.endTime = Date()
        activity.duration = currentDuration
        activity.distance = currentDistance
        activity.calories = currentCalories
        activity.averageSpeed = currentDistance > 0 ? currentDistance / currentDuration : 0
        activity.maxSpeed = locationPoints.compactMap { $0.speed }.max() ?? 0
        activity.elevationGain = currentElevationGain
        activity.route = locationPoints
        activity.isCompleted = true
        activity.intensity = calculateIntensity(for: activity)
        
        // Check for achievements
        activity.achievements = checkForAchievements(activity: activity)
        
        saveActivity(activity)
        currentActivity = nil
        resetTrackingData()
    }
    
    private func startLocationTracking() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    private func startTrackingTimer() {
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTrackingData()
        }
    }
    
    private func stopTrackingTimer() {
        trackingTimer?.invalidate()
        trackingTimer = nil
    }
    
    private func updateTrackingData() {
        guard let startTime = startTime else { return }
        
        currentDuration = Date().timeIntervalSince(startTime)
        updateCalories()
        updatePace()
    }
    
    private func updateCalories() {
        // Simplified calorie calculation based on activity type and duration
        let baseCaloriesPerMinute: Double
        
        switch selectedActivityType {
        case .running:
            baseCaloriesPerMinute = 12.0
        case .cycling:
            baseCaloriesPerMinute = 8.0
        case .walking:
            baseCaloriesPerMinute = 4.0
        case .swimming:
            baseCaloriesPerMinute = 11.0
        case .hiking:
            baseCaloriesPerMinute = 6.0
        case .yoga:
            baseCaloriesPerMinute = 3.0
        case .gym:
            baseCaloriesPerMinute = 8.0
        default:
            baseCaloriesPerMinute = 6.0
        }
        
        let minutes = currentDuration / 60
        currentCalories = Int(minutes * baseCaloriesPerMinute)
    }
    
    private func updatePace() {
        if currentDistance > 0 && currentDuration > 0 {
            currentPace = currentDuration / (currentDistance / 1000) // minutes per km
            currentSpeed = currentDistance / currentDuration // m/s
        }
    }
    
    private func generateActivityName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateString = formatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeString = timeFormatter.string(from: Date())
        
        return "\(selectedActivityType.displayName) - \(dateString) at \(timeString)"
    }
    
    private func calculateIntensity(for activity: Activity) -> ActivityIntensity {
        // Simple intensity calculation based on duration and speed
        let durationMinutes = activity.duration / 60
        let avgSpeedKmh = activity.averageSpeed * 3.6
        
        switch activity.type {
        case .running:
            if avgSpeedKmh > 12 || durationMinutes > 60 {
                return .high
            } else if avgSpeedKmh > 8 || durationMinutes > 30 {
                return .moderate
            } else {
                return .low
            }
        case .cycling:
            if avgSpeedKmh > 25 || durationMinutes > 90 {
                return .high
            } else if avgSpeedKmh > 15 || durationMinutes > 45 {
                return .moderate
            } else {
                return .low
            }
        default:
            if durationMinutes > 60 {
                return .high
            } else if durationMinutes > 30 {
                return .moderate
            } else {
                return .low
            }
        }
    }
    
    private func checkForAchievements(activity: Activity) -> [Achievement] {
        var achievements: [Achievement] = []
        
        // Check for distance achievements
        if activity.distance >= 5000 { // 5km
            achievements.append(Achievement(
                title: "5K Runner",
                description: "Completed your first 5km activity",
                icon: "figure.run",
                earnedDate: Date(),
                category: .distance
            ))
        }
        
        if activity.distance >= 10000 { // 10km
            achievements.append(Achievement(
                title: "10K Champion",
                description: "Conquered the 10km distance",
                icon: "rosette",
                earnedDate: Date(),
                category: .distance
            ))
        }
        
        // Check for duration achievements
        if activity.duration >= 3600 { // 1 hour
            achievements.append(Achievement(
                title: "Endurance Warrior",
                description: "Completed 1 hour of continuous activity",
                icon: "timer",
                earnedDate: Date(),
                category: .duration
            ))
        }
        
        return achievements
    }
    
    private func saveActivity(_ activity: Activity) {
        Task {
            do {
                try await activityService.saveActivity(activity)
                await MainActor.run {
                    self.activities.insert(activity, at: 0)
                    self.filterActivities()
                    self.updateStatistics()
                }
            } catch {
                await MainActor.run {
                    self.showErrorMessage("Failed to save activity: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func deleteActivity(_ activity: Activity) {
        Task {
            do {
                try await activityService.deleteActivity(activity.id)
                await MainActor.run {
                    if let index = self.activities.firstIndex(where: { $0.id == activity.id }) {
                        self.activities.remove(at: index)
                        self.filterActivities()
                        self.updateStatistics()
                    }
                }
            } catch {
                await MainActor.run {
                    self.showErrorMessage("Failed to delete activity: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func filterActivities() {
        var filtered = activities
        
        // Apply text search
        if !searchText.isEmpty {
            filtered = filtered.filter { activity in
                activity.name.localizedCaseInsensitiveContains(searchText) ||
                activity.type.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply type filter
        if let filterType = filterType {
            filtered = filtered.filter { $0.type == filterType }
        }
        
        // Apply sort order
        switch sortOrder {
        case .dateDescending:
            filtered.sort { $0.startTime > $1.startTime }
        case .dateAscending:
            filtered.sort { $0.startTime < $1.startTime }
        case .distanceDescending:
            filtered.sort { $0.distance > $1.distance }
        case .durationDescending:
            filtered.sort { $0.duration > $1.duration }
        }
    }
    
    private func loadStatistics() {
        Task {
            do {
                let stats = try await activityService.loadStatistics()
                await MainActor.run {
                    self.weeklyStats = stats.weekly
                    self.monthlyStats = stats.monthly
                    self.personalRecords = stats.personalRecords
                }
            } catch {
                await MainActor.run {
                    self.showErrorMessage("Failed to load statistics: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateStatistics() {
        loadStatistics()
    }
    
    private func resetTrackingData() {
        currentDuration = 0
        currentDistance = 0
        currentPace = 0
        currentSpeed = 0
        currentHeartRate = nil
        currentCalories = 0
        currentElevationGain = 0
        locationPoints = []
    }
    
    private func requestNotificationPermissionIfNeeded() {
        // This would integrate with UserNotifications framework
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showError = false
        }
    }
    
    var filteredActivities: [Activity] {
        activities
    }
    
    var totalDistance: Double {
        activities.reduce(0) { $0 + $1.distance }
    }
    
    var totalDuration: TimeInterval {
        activities.reduce(0) { $0 + $1.duration }
    }
    
    var totalCalories: Int {
        activities.reduce(0) { $0 + $1.calories }
    }
    
    var averagePace: Double {
        let completedActivities = activities.filter { $0.isCompleted && $0.distance > 0 }
        guard !completedActivities.isEmpty else { return 0 }
        
        let totalPace = completedActivities.reduce(0.0) { sum, activity in
            sum + (activity.duration / (activity.distance / 1000))
        }
        
        return totalPace / Double(completedActivities.count)
    }
}

// MARK: - CLLocationManagerDelegate
extension ActivityViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, isTracking && !isPaused else { return }
        
        let locationPoint = LocationPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: Date(),
            altitude: location.altitude,
            speed: location.speed > 0 ? location.speed : nil,
            heartRate: currentHeartRate
        )
        
        locationPoints.append(locationPoint)
        
        // Calculate distance
        if let lastLocation = lastLocation {
            let distance = location.distance(from: lastLocation)
            if distance > 5 { // Ignore small movements (less than 5 meters)
                currentDistance += distance
                
                // Calculate elevation gain
                if location.altitude > lastLocation.altitude {
                    currentElevationGain += (location.altitude - lastLocation.altitude)
                }
            }
        }
        
        lastLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showErrorMessage("Location error: \(error.localizedDescription)")
    }
}

enum SortOrder: String, CaseIterable {
    case dateDescending = "date_desc"
    case dateAscending = "date_asc"
    case distanceDescending = "distance_desc"
    case durationDescending = "duration_desc"
    
    var displayName: String {
        switch self {
        case .dateDescending: return "Newest First"
        case .dateAscending: return "Oldest First"
        case .distanceDescending: return "Longest Distance"
        case .durationDescending: return "Longest Duration"
        }
    }
}

struct WeeklyStats {
    let totalActivities: Int
    let totalDistance: Double
    let totalDuration: TimeInterval
    let totalCalories: Int
    let averageWorkoutsPerDay: Double
    let weekStartDate: Date
}

struct StatisticsData {
    let weekly: WeeklyStats
    let monthly: MonthlyStats
    let personalRecords: [PersonalRecord]
} 