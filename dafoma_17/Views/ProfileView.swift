//
//  ProfileView.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    @State private var selectedTab: ProfileTab = .overview
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    profileHeader
                    
                    tabSelector
                    
                    tabContent
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        profileViewModel.showingEditProfile = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(settingsViewModel.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $profileViewModel.showingEditProfile) {
            EditProfileView()
                .environmentObject(profileViewModel)
                .environmentObject(settingsViewModel)
        }
        .refreshable {
            profileViewModel.loadUserProfile()
            profileViewModel.loadStatistics()
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
    
    private var profileHeader: some View {
        VStack(spacing: 20) {
            // Profile picture and basic info
            HStack(spacing: 20) {
                // Profile picture
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    settingsViewModel.accentColor.opacity(0.3),
                                    settingsViewModel.accentColor
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .neumorphicStyle()
                    
                    if let user = profileViewModel.user, !user.name.isEmpty {
                        Text(String(user.name.prefix(1)).uppercased())
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(profileViewModel.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(profileViewModel.memberSince)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    // BMI if available
                    if let bmi = profileViewModel.bmiInfo.value {
                        Text("BMI: \(String(format: "%.1f", bmi)) (\(profileViewModel.bmiInfo.category))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
            }
            
            // Quick stats
            HStack(spacing: 20) {
                ProfileQuickStat(
                    title: "Activities",
                    value: "\(profileViewModel.totalActivitiesCount)",
                    icon: "figure.run"
                )
                
                ProfileQuickStat(
                    title: "Distance",
                    value: profileViewModel.totalDistance,
                    icon: "location"
                )
                
                ProfileQuickStat(
                    title: "Duration",
                    value: profileViewModel.totalDuration,
                    icon: "clock.fill"
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 6) {
                        Text(tab.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(selectedTab == tab ? settingsViewModel.accentColor : .white.opacity(0.6))
                        
                        Rectangle()
                            .fill(selectedTab == tab ? settingsViewModel.accentColor : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .overview:
                OverviewTabView()
            case .statistics:
                StatisticsTabView()
            case .achievements:
                AchievementsTabView()
            case .goals:
                GoalsTabView()
            }
        }
        .environmentObject(profileViewModel)
        .environmentObject(settingsViewModel)
    }
}

// MARK: - Profile Tabs

enum ProfileTab: String, CaseIterable {
    case overview = "overview"
    case statistics = "statistics"
    case achievements = "achievements"
    case goals = "goals"
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .statistics: return "Statistics"
        case .achievements: return "Achievements"
        case .goals: return "Goals"
        }
    }
}

// MARK: - Overview Tab

struct OverviewTabView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 25) {
                // Current streaks
                currentStreaksSection
                
                // Recent activities
                recentActivitiesSection
                
                // Progress chart
                progressChartSection
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var currentStreaksSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Current Streaks")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(spacing: 15) {
                StreakCard(
                    title: "Current",
                    value: "\(profileViewModel.currentStreak)",
                    subtitle: "days",
                    color: Color.green
                )
                
                StreakCard(
                    title: "Longest",
                    value: "\(profileViewModel.longestStreak)",
                    subtitle: "days",
                    color: Color.orange
                )
                
                StreakCard(
                    title: "This Week",
                    value: "4",
                    subtitle: "workouts",
                    color: settingsViewModel.accentColor
                )
            }
        }
    }
    
    private var recentActivitiesSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Recent Activities")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to activities
                }
                .font(.subheadline)
                .foregroundColor(settingsViewModel.accentColor)
            }
            
            if profileViewModel.recentActivities.isEmpty {
                EmptyStateView(
                    icon: "figure.run",
                    title: "No Recent Activities",
                    subtitle: "Start your first workout!"
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(profileViewModel.recentActivities.prefix(3)) { activity in
                        ProfileActivityRow(activity: activity)
                    }
                }
            }
        }
    }
    
    private var progressChartSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Weekly Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Picker("Metric", selection: $profileViewModel.selectedMetric) {
                    ForEach(ProfileMetric.allCases, id: \.self) { metric in
                        Text(metric.displayName).tag(metric)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(settingsViewModel.accentColor)
            }
            
            WeeklyProgressChart(
                data: profileViewModel.weeklyProgress,
                metric: profileViewModel.selectedMetric
            )
            .frame(height: 200)
        }
    }
}

// MARK: - Statistics Tab

struct StatisticsTabView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 25) {
                // Time period selector
                timeFrameSelector
                
                // Statistics cards
                statisticsCardsSection
                
                // Personal records
                personalRecordsSection
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var timeFrameSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                Button(action: {
                    profileViewModel.selectedTimeframe = timeFrame
                }) {
                    Text(timeFrame.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(profileViewModel.selectedTimeframe == timeFrame ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(profileViewModel.selectedTimeframe == timeFrame ? 
                                     settingsViewModel.accentColor : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
    
    private var statisticsCardsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            StatisticCard(
                title: "Total Activities",
                value: "\(profileViewModel.totalActivitiesCount)",
                icon: "figure.run",
                color: settingsViewModel.accentColor
            )
            
            StatisticCard(
                title: "Total Distance",
                value: profileViewModel.totalDistance,
                icon: "location",
                color: Color.blue
            )
            
            StatisticCard(
                title: "Total Time",
                value: profileViewModel.totalDuration,
                icon: "clock.fill",
                color: Color.orange
            )
            
            StatisticCard(
                title: "Favorite Activity",
                value: profileViewModel.favoriteActivity,
                icon: "heart.fill",
                color: Color.red
            )
        }
    }
    
    private var personalRecordsSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Personal Records")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if profileViewModel.user?.statistics.personalRecords.isEmpty ?? true {
                EmptyStateView(
                    icon: "trophy",
                    title: "No Records Yet",
                    subtitle: "Complete more activities to set records!"
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(profileViewModel.user?.statistics.personalRecords ?? []) { record in
                        PersonalRecordRow(record: record)
                    }
                }
            }
        }
    }
}

// MARK: - Achievements Tab

struct AchievementsTabView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 25) {
                // Achievement summary
                achievementSummarySection
                
                // Recent achievements
                recentAchievementsSection
                
                // All badges
                allBadgesSection
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var achievementSummarySection: some View {
        HStack(spacing: 20) {
            AchievementSummaryCard(
                title: "Total Badges",
                value: "\(profileViewModel.totalBadgesCount)",
                icon: "rosette",
                color: Color.yellow
            )
            
            AchievementSummaryCard(
                title: "Completed Goals",
                value: "\(profileViewModel.completedGoalsCount)",
                icon: "target",
                color: Color.green
            )
        }
    }
    
    private var recentAchievementsSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Recent Achievements")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if profileViewModel.topAchievements.isEmpty {
                EmptyStateView(
                    icon: "star",
                    title: "No Achievements Yet",
                    subtitle: "Complete activities to earn achievements!"
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(profileViewModel.topAchievements) { badge in
                        BadgeCard(badge: badge)
                    }
                }
            }
        }
    }
    
    private var allBadgesSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("All Badges")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if let user = profileViewModel.user, !user.badges.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(user.badges) { badge in
                        CompactBadgeCard(badge: badge)
                    }
                }
            } else {
                EmptyStateView(
                    icon: "medal",
                    title: "No Badges Earned",
                    subtitle: "Keep working out to unlock badges!"
                )
            }
        }
    }
}

// MARK: - Goals Tab

struct GoalsTabView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 25) {
                // Active goals
                activeGoalsSection
                
                // Add new goal button
                addGoalButton
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var activeGoalsSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Active Goals")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if profileViewModel.currentGoals.isEmpty {
                EmptyStateView(
                    icon: "target",
                    title: "No Active Goals",
                    subtitle: "Set your first goal to track progress!"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(profileViewModel.currentGoals) { goal in
                        GoalProgressCard(goal: goal)
                    }
                }
            }
        }
    }
    
    private var addGoalButton: some View {
        Button(action: {
            // Add new goal
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                
                Text("Add New Goal")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(settingsViewModel.accentColor)
                    .neumorphicStyle()
            )
        }
    }
}

// MARK: - Supporting Views

struct ProfileQuickStat: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: "#01A2FF") ?? .blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
}

struct StreakCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
}

struct ProfileActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.type.icon)
                .font(.title3)
                .foregroundColor(Color(hex: "#01A2FF") ?? .blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(formatDate(activity.startTime))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(activity.formattedDistance)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(activity.formattedDuration)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDate(date, inSameDayAs: Date()) {
            return "Today"
        } else if Calendar.current.isDate(date, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

struct WeeklyProgressChart: View {
    let data: [DailyProgress]
    let metric: ProfileMetric
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
            
            VStack {
                Text("Chart visualization would go here")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Showing \(metric.displayName) progress")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
}

struct PersonalRecordRow: View {
    let record: PersonalRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.recordType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(record.activityType.displayName)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatRecordValue(record))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#01A2FF") ?? .blue)
                
                Text(formatDate(record.achievedDate))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
    
    private func formatRecordValue(_ record: PersonalRecord) -> String {
        switch record.recordType {
        case .longestDistance:
            return String(format: "%.2f km", record.value / 1000)
        case .longestDuration:
            let hours = Int(record.value) / 3600
            let minutes = (Int(record.value) % 3600) / 60
            return "\(hours)h \(minutes)m"
        case .fastestPace:
            let minutes = Int(record.value)
            let seconds = Int((record.value - Double(minutes)) * 60)
            return String(format: "%d:%02d /km", minutes, seconds)
        case .mostCaloriesBurned:
            return "\(Int(record.value)) cal"
        case .highestElevationGain:
            return "\(Int(record.value)) m"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct AchievementSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
}

struct BadgeCard: View {
    let badge: Badge
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: badge.icon)
                .font(.title2)
                .foregroundColor(Color(hex: badge.color) ?? .yellow)
            
            Text(badge.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
}

struct CompactBadgeCard: View {
    let badge: Badge
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: badge.icon)
                .font(.title3)
                .foregroundColor(Color(hex: badge.color) ?? .yellow)
            
            Text(badge.title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(1)
        }
        .frame(width: 60, height: 60)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
}

struct GoalProgressCard: View {
    let goal: FitnessGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(goal.progressPercentage)%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#01A2FF") ?? .blue)
            }
            
            ProgressView(value: goal.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "#01A2FF") ?? .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("\(Int(goal.currentValue)) / \(Int(goal.targetValue)) \(goal.type.unit)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text("Due \(formatDate(goal.targetDate))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#090F1E") ?? .black,
                        Color(hex: "#1A2339") ?? .gray
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Profile picture section
                        profilePictureSection
                        
                        // Basic info fields
                        basicInfoSection
                        
                        // Fitness info
                        fitnessInfoSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        profileViewModel.saveUserProfile()
                    }
                    .foregroundColor(settingsViewModel.accentColor)
                }
            }
        }
    }
    
    private var profilePictureSection: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                settingsViewModel.accentColor.opacity(0.3),
                                settingsViewModel.accentColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .neumorphicStyle()
                
                if !profileViewModel.editName.isEmpty {
                    Text(String(profileViewModel.editName.prefix(1)).uppercased())
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                // Camera icon for changing photo
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "camera.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .frame(width: 100, height: 100)
            }
            
            Text("Tap to change photo")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var basicInfoSection: some View {
        VStack(spacing: 15) {
            Text("Basic Information")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                EditTextField(
                    title: "Name",
                    text: $profileViewModel.editName,
                    placeholder: "Enter your name"
                )
                
                HStack(spacing: 12) {
                    EditTextField(
                        title: "Age",
                        text: $profileViewModel.editAge,
                        placeholder: "25",
                        keyboardType: .numberPad
                    )
                    
                    EditTextField(
                        title: "Weight (kg)",
                        text: $profileViewModel.editWeight,
                        placeholder: "70",
                        keyboardType: .decimalPad
                    )
                }
                
                EditTextField(
                    title: "Height (cm)",
                    text: $profileViewModel.editHeight,
                    placeholder: "175",
                    keyboardType: .numberPad
                )
            }
        }
    }
    
    private var fitnessInfoSection: some View {
        VStack(spacing: 15) {
            Text("Fitness Information")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Gender selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gender")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 8) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Button(action: {
                                profileViewModel.editGender = gender
                            }) {
                                Text(gender.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(profileViewModel.editGender == gender ? 
                                                 settingsViewModel.accentColor : 
                                                 Color(hex: "#1A2339") ?? .gray)
                                    )
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                
                // Fitness level selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fitness Level")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    VStack(spacing: 8) {
                        ForEach(FitnessLevel.allCases, id: \.self) { level in
                            Button(action: {
                                profileViewModel.editFitnessLevel = level
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(level.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        Text(level.description)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    if profileViewModel.editFitnessLevel == level {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(settingsViewModel.accentColor)
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(profileViewModel.editFitnessLevel == level ? 
                                               settingsViewModel.accentColor : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

struct EditTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
            
            TextField(placeholder, text: $text)
                .font(.body)
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "#1A2339") ?? .gray)
                        .neumorphicStyle()
                )
                .foregroundColor(.white)
                .keyboardType(keyboardType)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(ProfileViewModel())
        .environmentObject(SettingsViewModel())
} 
