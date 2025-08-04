//
//  ActivityDetailView.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import SwiftUI

struct ActivityDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    let activity: Activity
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 25) {
                        headerSection
                        
                        primaryStatsSection
                        
                        detailedStatsSection
                        
                        if !activity.route.isEmpty {
                            routeSection
                        }
                        
                        if !activity.achievements.isEmpty {
                            achievementsSection
                        }
                        
                        if let notes = activity.notes, !notes.isEmpty {
                            notesSection
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Activity Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(role: .destructive, action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(settingsViewModel.accentColor)
                    }
                }
            }
        }
        .alert("Delete Activity", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                activityViewModel.deleteActivity(activity)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this activity? This action cannot be undone.")
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#090F1E") ?? .black,
                Color(hex: "#1A2339") ?? .gray
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Activity icon and type
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: activity.intensityColor)?.opacity(0.3) ?? .blue.opacity(0.3),
                                Color(hex: activity.intensityColor) ?? .blue
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .neumorphicStyle()
                
                Image(systemName: activity.type.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text(activity.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(activity.type.displayName)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(settingsViewModel.accentColor)
                
                Text(formatFullDate(activity.startTime))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Intensity badge
            HStack {
                Text(activity.intensity.displayName.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: activity.intensityColor) ?? .blue)
                    )
                    .foregroundColor(.white)
                
                if activity.isCompleted {
                    Text("COMPLETED")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green)
                        )
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var primaryStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            PrimaryStatCard(
                title: "Distance",
                value: activity.formattedDistance,
                icon: "location",
                color: Color.blue
            )
            
            PrimaryStatCard(
                title: "Duration",
                value: activity.formattedDuration,
                icon: "clock.fill",
                color: Color.orange
            )
            
            PrimaryStatCard(
                title: "Avg Speed",
                value: activity.formattedSpeed,
                icon: "speedometer",
                color: Color.green
            )
            
            PrimaryStatCard(
                title: "Calories",
                value: "\(activity.calories)",
                icon: "flame.fill",
                color: Color.red
            )
        }
    }
    
    private var detailedStatsSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Detailed Statistics")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                if let avgHeartRate = activity.averageHeartRate {
                    DetailedStatRow(
                        title: "Average Heart Rate",
                        value: "\(avgHeartRate) bpm",
                        icon: "heart.fill"
                    )
                }
                
                if let maxHeartRate = activity.maxHeartRate {
                    DetailedStatRow(
                        title: "Maximum Heart Rate",
                        value: "\(maxHeartRate) bpm",
                        icon: "heart.circle.fill"
                    )
                }
                
                if activity.maxSpeed > 0 {
                    DetailedStatRow(
                        title: "Maximum Speed",
                        value: String(format: "%.1f km/h", activity.maxSpeed * 3.6),
                        icon: "speedometer"
                    )
                }
                
                if let elevation = activity.elevationGain, elevation > 0 {
                    DetailedStatRow(
                        title: "Elevation Gain",
                        value: String(format: "%.0f m", elevation),
                        icon: "mountain.2.fill"
                    )
                }
                
                if let weather = activity.weather {
                    DetailedStatRow(
                        title: "Weather",
                        value: "\(Int(weather.temperature))°C, \(weather.condition)",
                        icon: "cloud.sun.fill"
                    )
                }
            }
        }
    }
    
    private var routeSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Route")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(activity.route.count) points")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Route map placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: "#1A2339") ?? .gray)
                    .frame(height: 200)
                    .neumorphicStyle()
                
                VStack(spacing: 10) {
                    Image(systemName: "map")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Route Map")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Map integration would show the actual route here")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    private var achievementsSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(activity.achievements) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Notes")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text(activity.notes ?? "")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#1A2339") ?? .gray)
                        .neumorphicStyle()
                )
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Primary Stat Card

struct PrimaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
}

// MARK: - Detailed Stat Row

struct DetailedStatRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: "#01A2FF") ?? .blue)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(Color.yellow)
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(achievement.description)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
}

#Preview {
    ActivityDetailView(
        activity: Activity(
            type: .running,
            name: "Morning Run",
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800),
            duration: 1800,
            distance: 5000,
            calories: 300,
            averageHeartRate: 150,
            maxHeartRate: 180,
            averageSpeed: 2.78,
            maxSpeed: 4.17,
            elevationGain: 50,
            route: [],
            intensity: .moderate,
            notes: "Great morning run! Felt really good today.",
            weather: nil,
            isCompleted: true,
            achievements: []
        )
    )
    .environmentObject(ActivityViewModel())
    .environmentObject(SettingsViewModel())
} 