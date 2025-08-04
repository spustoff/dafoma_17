//
//  ActivityService.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import Foundation
import CoreLocation

class ActivityService: ObservableObject {
    private let documentsDirectory: URL
    private let activitiesDirectoryName = "activities"
    private let activitiesDirectory: URL
    
    init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        activitiesDirectory = documentsDirectory.appendingPathComponent(activitiesDirectoryName)
        
        // Create activities directory if it doesn't exist
        createActivitiesDirectoryIfNeeded()
    }
    
    private func createActivitiesDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: activitiesDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: activitiesDirectory, withIntermediateDirectories: true)
                print("✅ Activities directory created")
            } catch {
                print("❌ Failed to create activities directory: \(error)")
            }
        }
    }
    
    // MARK: - Activity Management
    
    func saveActivity(_ activity: Activity) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let activityData = try encoder.encode(activity)
            let fileName = "\(activity.id.uuidString).json"
            let fileURL = activitiesDirectory.appendingPathComponent(fileName)
            
            try activityData.write(to: fileURL)
            print("✅ Activity saved: \(activity.name)")
            
            // Update activity index for faster loading
            try await updateActivityIndex(adding: activity)
            
        } catch {
            print("❌ Failed to save activity: \(error)")
            throw ActivityServiceError.saveFailed(error)
        }
    }
    
    func loadActivities() async throws -> [Activity] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var activities: [Activity] = []
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: activitiesDirectory, includingPropertiesForKeys: nil)
            
            for fileURL in fileURLs {
                if fileURL.pathExtension == "json" && fileURL.lastPathComponent != "index.json" {
                    let activityData = try Data(contentsOf: fileURL)
                    let activity = try decoder.decode(Activity.self, from: activityData)
                    activities.append(activity)
                }
            }
            
            // Sort by start time, newest first
            activities.sort { $0.startTime > $1.startTime }
            
            print("✅ Loaded \(activities.count) activities")
            return activities
            
        } catch {
            print("❌ Failed to load activities: \(error)")
            throw ActivityServiceError.loadFailed(error)
        }
    }
    
    func loadActivity(with id: UUID) async throws -> Activity {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let fileName = "\(id.uuidString).json"
        let fileURL = activitiesDirectory.appendingPathComponent(fileName)
        
        do {
            let activityData = try Data(contentsOf: fileURL)
            let activity = try decoder.decode(Activity.self, from: activityData)
            return activity
        } catch {
            print("❌ Failed to load activity \(id): \(error)")
            throw ActivityServiceError.activityNotFound
        }
    }
    
    func loadRecentActivities(limit: Int) async throws -> [Activity] {
        let allActivities = try await loadActivities()
        return Array(allActivities.prefix(limit))
    }
    
    func loadActivities(ofType type: ActivityType) async throws -> [Activity] {
        let allActivities = try await loadActivities()
        return allActivities.filter { $0.type == type }
    }
    
    func loadActivities(from startDate: Date, to endDate: Date) async throws -> [Activity] {
        let allActivities = try await loadActivities()
        return allActivities.filter { activity in
            activity.startTime >= startDate && activity.startTime <= endDate
        }
    }
    
    func deleteActivity(_ id: UUID) async throws {
        let fileName = "\(id.uuidString).json"
        let fileURL = activitiesDirectory.appendingPathComponent(fileName)
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("✅ Activity deleted: \(id)")
                
                // Update activity index
                try await updateActivityIndex(removing: id)
            } else {
                throw ActivityServiceError.activityNotFound
            }
        } catch {
            print("❌ Failed to delete activity: \(error)")
            throw ActivityServiceError.deleteFailed(error)
        }
    }
    
    func updateActivity(_ activity: Activity) async throws {
        // Simply save the updated activity (overwrites existing file)
        try await saveActivity(activity)
    }
    
    // MARK: - Statistics
    
    func loadStatistics() async throws -> StatisticsData {
        let activities = try await loadActivities()
        
        let weeklyStats = generateWeeklyStats(from: activities)
        let monthlyStats = generateMonthlyStats(from: activities)
        let personalRecords = generatePersonalRecords(from: activities)
        
        return StatisticsData(
            weekly: weeklyStats,
            monthly: monthlyStats,
            personalRecords: personalRecords
        )
    }
    
    private func generateWeeklyStats(from activities: [Activity]) -> WeeklyStats {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        let weekActivities = activities.filter { activity in
            activity.startTime >= weekStart
        }
        
        let totalDistance = weekActivities.reduce(0) { $0 + $1.distance }
        let totalDuration = weekActivities.reduce(0) { $0 + $1.duration }
        let totalCalories = weekActivities.reduce(0) { $0 + $1.calories }
        
        let daysInWeek = 7.0
        let averageWorkoutsPerDay = Double(weekActivities.count) / daysInWeek
        
        return WeeklyStats(
            totalActivities: weekActivities.count,
            totalDistance: totalDistance,
            totalDuration: totalDuration,
            totalCalories: totalCalories,
            averageWorkoutsPerDay: averageWorkoutsPerDay,
            weekStartDate: weekStart
        )
    }
    
    private func generateMonthlyStats(from activities: [Activity]) -> MonthlyStats {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let monthActivities = activities.filter { activity in
            activity.startTime >= monthStart
        }
        
        let totalDistance = monthActivities.reduce(0) { $0 + $1.distance }
        let totalDuration = monthActivities.reduce(0) { $0 + $1.duration }
        let totalCalories = monthActivities.reduce(0) { $0 + $1.calories }
        
        return MonthlyStats(
            month: calendar.component(.month, from: now),
            year: calendar.component(.year, from: now),
            totalActivities: monthActivities.count,
            totalDistance: totalDistance,
            totalDuration: totalDuration,
            totalCalories: totalCalories,
            averageWorkoutsPerWeek: 0 // Would be calculated differently
        )
    }
    
    private func generatePersonalRecords(from activities: [Activity]) -> [PersonalRecord] {
        var records: [PersonalRecord] = []
        
        // Group activities by type
        let groupedActivities = Dictionary(grouping: activities, by: { $0.type })
        
        for (activityType, typeActivities) in groupedActivities {
            // Longest distance
            if let longestDistance = typeActivities.max(by: { $0.distance < $1.distance }) {
                records.append(PersonalRecord(
                    activityType: activityType,
                    recordType: .longestDistance,
                    value: longestDistance.distance,
                    achievedDate: longestDistance.startTime,
                    activityId: longestDistance.id
                ))
            }
            
            // Longest duration
            if let longestDuration = typeActivities.max(by: { $0.duration < $1.duration }) {
                records.append(PersonalRecord(
                    activityType: activityType,
                    recordType: .longestDuration,
                    value: longestDuration.duration,
                    achievedDate: longestDuration.startTime,
                    activityId: longestDuration.id
                ))
            }
            
            // Fastest pace (for activities with distance > 0)
            let activitiesWithDistance = typeActivities.filter { $0.distance > 0 }
            if let fastestPace = activitiesWithDistance.min(by: { 
                ($0.duration / ($0.distance / 1000)) < ($1.duration / ($1.distance / 1000))
            }) {
                let pace = fastestPace.duration / (fastestPace.distance / 1000)
                records.append(PersonalRecord(
                    activityType: activityType,
                    recordType: .fastestPace,
                    value: pace,
                    achievedDate: fastestPace.startTime,
                    activityId: fastestPace.id
                ))
            }
            
            // Most calories burned
            if let mostCalories = typeActivities.max(by: { $0.calories < $1.calories }) {
                records.append(PersonalRecord(
                    activityType: activityType,
                    recordType: .mostCaloriesBurned,
                    value: Double(mostCalories.calories),
                    achievedDate: mostCalories.startTime,
                    activityId: mostCalories.id
                ))
            }
            
            // Highest elevation gain (for activities with elevation data)
            let activitiesWithElevation = typeActivities.compactMap { activity -> (Activity, Double)? in
                guard let elevation = activity.elevationGain, elevation > 0 else { return nil }
                return (activity, elevation)
            }
            
            if let highestElevation = activitiesWithElevation.max(by: { $0.1 < $1.1 }) {
                records.append(PersonalRecord(
                    activityType: activityType,
                    recordType: .highestElevationGain,
                    value: highestElevation.1,
                    achievedDate: highestElevation.0.startTime,
                    activityId: highestElevation.0.id
                ))
            }
        }
        
        return records
    }
    
    // MARK: - Activity Index Management
    
    private func updateActivityIndex(adding activity: Activity) async throws {
        var index = try await loadActivityIndex()
        
        let indexEntry = ActivityIndexEntry(
            id: activity.id,
            name: activity.name,
            type: activity.type,
            startTime: activity.startTime,
            duration: activity.duration,
            distance: activity.distance,
            calories: activity.calories
        )
        
        index.activities.append(indexEntry)
        index.activities.sort { $0.startTime > $1.startTime }
        
        try await saveActivityIndex(index)
    }
    
    private func updateActivityIndex(removing id: UUID) async throws {
        var index = try await loadActivityIndex()
        index.activities.removeAll { $0.id == id }
        try await saveActivityIndex(index)
    }
    
    private func loadActivityIndex() async throws -> ActivityIndex {
        let indexURL = activitiesDirectory.appendingPathComponent("index.json")
        
        guard FileManager.default.fileExists(atPath: indexURL.path) else {
            return ActivityIndex(activities: [], lastUpdated: Date())
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let indexData = try Data(contentsOf: indexURL)
            return try decoder.decode(ActivityIndex.self, from: indexData)
        } catch {
            // If index is corrupted, rebuild it
            return try await rebuildActivityIndex()
        }
    }
    
    private func saveActivityIndex(_ index: ActivityIndex) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let indexData = try encoder.encode(index)
        let indexURL = activitiesDirectory.appendingPathComponent("index.json")
        
        try indexData.write(to: indexURL)
    }
    
    private func rebuildActivityIndex() async throws -> ActivityIndex {
        let activities = try await loadActivities()
        
        let indexEntries = activities.map { activity in
            ActivityIndexEntry(
                id: activity.id,
                name: activity.name,
                type: activity.type,
                startTime: activity.startTime,
                duration: activity.duration,
                distance: activity.distance,
                calories: activity.calories
            )
        }
        
        let index = ActivityIndex(activities: indexEntries, lastUpdated: Date())
        try await saveActivityIndex(index)
        
        return index
    }
    
    // MARK: - Data Export/Import
    
    func exportActivities(format: ExportFormat) async throws -> URL {
        let activities = try await loadActivities()
        
        switch format {
        case .json:
            return try await exportActivitiesAsJSON(activities)
        case .csv:
            return try await exportActivitiesAsCSV(activities)
        case .gpx:
            return try await exportActivitiesAsGPX(activities)
        case .tcx:
            return try await exportActivitiesAsTCX(activities)
        }
    }
    
    private func exportActivitiesAsJSON(_ activities: [Activity]) async throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let activitiesData = try encoder.encode(activities)
        let exportURL = documentsDirectory.appendingPathComponent("aerotracker_activities.json")
        
        try activitiesData.write(to: exportURL)
        return exportURL
    }
    
    private func exportActivitiesAsCSV(_ activities: [Activity]) async throws -> URL {
        var csvContent = "ID,Name,Type,Start Time,End Time,Duration (s),Distance (m),Calories,Average Speed (m/s),Max Speed (m/s),Elevation Gain (m)\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for activity in activities {
            let endTime = activity.endTime ?? activity.startTime
            let elevationGain = activity.elevationGain ?? 0
            
            csvContent += "\(activity.id),\"\(activity.name)\",\(activity.type.rawValue),\(dateFormatter.string(from: activity.startTime)),\(dateFormatter.string(from: endTime)),\(activity.duration),\(activity.distance),\(activity.calories),\(activity.averageSpeed),\(activity.maxSpeed),\(elevationGain)\n"
        }
        
        let exportURL = documentsDirectory.appendingPathComponent("aerotracker_activities.csv")
        try csvContent.write(to: exportURL, atomically: true, encoding: .utf8)
        
        return exportURL
    }
    
    private func exportActivitiesAsGPX(_ activities: [Activity]) async throws -> URL {
        // This is a simplified GPX export - in a real app you'd want full GPX specification
        var gpxContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Aerotracker" xmlns="http://www.topografix.com/GPX/1/1">
        """
        
        for activity in activities {
            if !activity.route.isEmpty {
                gpxContent += """
                <trk>
                    <name>\(activity.name)</name>
                    <type>\(activity.type.displayName)</type>
                    <trkseg>
                """
                
                for point in activity.route {
                    gpxContent += """
                        <trkpt lat="\(point.latitude)" lon="\(point.longitude)">
                    """
                    
                    if let altitude = point.altitude {
                        gpxContent += "<ele>\(altitude)</ele>"
                    }
                    
                    let dateFormatter = ISO8601DateFormatter()
                    gpxContent += "<time>\(dateFormatter.string(from: point.timestamp))</time>"
                    
                    gpxContent += "</trkpt>"
                }
                
                gpxContent += """
                    </trkseg>
                </trk>
                """
            }
        }
        
        gpxContent += "</gpx>"
        
        let exportURL = documentsDirectory.appendingPathComponent("aerotracker_activities.gpx")
        try gpxContent.write(to: exportURL, atomically: true, encoding: .utf8)
        
        return exportURL
    }
    
    private func exportActivitiesAsTCX(_ activities: [Activity]) async throws -> URL {
        // Simplified TCX export
        var tcxContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">
            <Activities>
        """
        
        let dateFormatter = ISO8601DateFormatter()
        
        for activity in activities {
            tcxContent += """
                <Activity Sport="\(activity.type.displayName)">
                    <Id>\(dateFormatter.string(from: activity.startTime))</Id>
                    <Lap StartTime="\(dateFormatter.string(from: activity.startTime))">
                        <TotalTimeSeconds>\(activity.duration)</TotalTimeSeconds>
                        <DistanceMeters>\(activity.distance)</DistanceMeters>
                        <Calories>\(activity.calories)</Calories>
                        <Intensity>Active</Intensity>
                        <TriggerMethod>Manual</TriggerMethod>
                    </Lap>
                </Activity>
            """
        }
        
        tcxContent += """
            </Activities>
        </TrainingCenterDatabase>
        """
        
        let exportURL = documentsDirectory.appendingPathComponent("aerotracker_activities.tcx")
        try tcxContent.write(to: exportURL, atomically: true, encoding: .utf8)
        
        return exportURL
    }
    
    // MARK: - Data Cleanup
    
    func clearAllActivities() async throws {
        let fileURLs = try FileManager.default.contentsOfDirectory(at: activitiesDirectory, includingPropertiesForKeys: nil)
        
        for fileURL in fileURLs {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        print("✅ All activities cleared")
    }
}

// MARK: - Supporting Structures

private struct ActivityIndex: Codable {
    var activities: [ActivityIndexEntry]
    let lastUpdated: Date
}

private struct ActivityIndexEntry: Codable {
    let id: UUID
    let name: String
    let type: ActivityType
    let startTime: Date
    let duration: TimeInterval
    let distance: Double
    let calories: Int
}

// MARK: - Error Types

enum ActivityServiceError: LocalizedError {
    case saveFailed(Error)
    case loadFailed(Error)
    case deleteFailed(Error)
    case activityNotFound
    case invalidData
    case exportFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save activity: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load activities: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete activity: \(error.localizedDescription)"
        case .activityNotFound:
            return "Activity not found"
        case .invalidData:
            return "Invalid activity data format"
        case .exportFailed(let error):
            return "Failed to export activities: \(error.localizedDescription)"
        }
    }
} 