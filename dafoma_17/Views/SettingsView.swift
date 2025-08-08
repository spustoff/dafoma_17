//
//  SettingsView.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var showingAbout = false
    @State private var showingDataExport = false
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 25) {
                        // General Settings
                        generalSettingsSection
                        
                        // Workout Settings
                        workoutSettingsSection
                        
                        // Notifications
                        notificationsSection
                        
                        // Display & Appearance
                        displaySection
                        
                        // Data & Privacy
                        dataSection
                        
                        // About & Support
                        aboutSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
                .environmentObject(settingsViewModel)
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView()
                .environmentObject(settingsViewModel)
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
    
    private var generalSettingsSection: some View {
        SettingsSection(title: "General") {
            VStack(spacing: 12) {
                SettingsToggleRow(
                    icon: "hand.raised.fill",
                    title: "Haptic Feedback",
                    subtitle: "Feel vibrations for interactions",
                    isOn: Binding(
                        get: { settingsViewModel.settings.general.hapticFeedback },
                        set: { newValue in
                            settingsViewModel.settings.general.hapticFeedback = newValue
                            settingsViewModel.saveSettings()
                        }
                    )
                )
                
                SettingsToggleRow(
                    icon: "speaker.wave.3.fill",
                    title: "Sound Effects",
                    subtitle: "Play sounds for actions",
                    isOn: Binding(
                        get: { settingsViewModel.settings.general.soundEffects },
                        set: { newValue in
                            settingsViewModel.settings.general.soundEffects = newValue
                            settingsViewModel.saveSettings()
                        }
                    )
                )
                
                SettingsToggleRow(
                    icon: "mic.fill",
                    title: "Voice Coaching",
                    subtitle: "Audio feedback during workouts",
                    isOn: Binding(
                        get: { settingsViewModel.settings.general.voiceCoaching },
                        set: { newValue in
                            settingsViewModel.settings.general.voiceCoaching = newValue
                            settingsViewModel.saveSettings()
                        }
                    )
                )
            }
        }
    }
    
    private var workoutSettingsSection: some View {
        SettingsSection(title: "Workout") {
            VStack(spacing: 12) {
                SettingsToggleRow(
                    icon: "play.fill",
                    title: "Auto Start",
                    subtitle: "Automatically start tracking when movement detected",
                    isOn: Binding(
                        get: { settingsViewModel.settings.workout.autoStart },
                        set: { newValue in
                            settingsViewModel.settings.workout.autoStart = newValue
                            settingsViewModel.saveSettings()
                        }
                    )
                )
                
                SettingsToggleRow(
                    icon: "pause.fill",
                    title: "Auto Pause",
                    subtitle: "Pause tracking when you stop moving",
                    isOn: Binding(
                        get: { settingsViewModel.settings.workout.autoPause },
                        set: { newValue in
                            settingsViewModel.settings.workout.autoPause = newValue
                            settingsViewModel.saveSettings()
                        }
                    )
                )
                
                SettingsToggleRow(
                    icon: "figure.run",
                    title: "Auto-Detect Activity",
                    subtitle: "Automatically recognize activity type",
                    isOn: Binding(
                        get: { settingsViewModel.settings.workout.autoDetectActivity },
                        set: { newValue in
                            settingsViewModel.settings.workout.autoDetectActivity = newValue
                            settingsViewModel.saveSettings()
                        }
                    )
                )
            }
        }
    }
    
    private var notificationsSection: some View {
        SettingsSection(title: "Notifications") {
            VStack(spacing: 12) {
                SettingsToggleRow(
                    icon: "bell.fill",
                    title: "Workout Reminders",
                    subtitle: "Get reminders to stay active",
                    isOn: Binding(
                        get: { settingsViewModel.settings.notifications.workoutReminders },
                        set: { newValue in
                            settingsViewModel.settings.notifications.workoutReminders = newValue
                            settingsViewModel.saveSettings()
                        }
                    )
                )
                
                SettingsToggleRow(
                    icon: "target",
                    title: "Goal Progress",
                    subtitle: "Updates on your fitness goals",
                    isOn: Binding(
                        get: { settingsViewModel.settings.notifications.goalProgress },
                        set: { newValue in
                            settingsViewModel.settings.notifications.goalProgress = newValue
                            settingsViewModel.saveSettings()
                        }
                    )
                )
                
                SettingsToggleRow(
                    icon: "trophy.fill",
                    title: "Achievements",
                    subtitle: "Celebrate your accomplishments",
                    isOn: Binding(
                        get: { settingsViewModel.settings.notifications.achievements },
                        set: { newValue in
                            settingsViewModel.settings.notifications.achievements = newValue
                            settingsViewModel.saveSettings()
                        }
                    )
                )
                
                SettingsToggleRow(
                    icon: "chart.bar.fill",
                    title: "Weekly Reports",
                    subtitle: "Summary of your weekly progress",
                    isOn: Binding(
                        get: { settingsViewModel.settings.notifications.weeklyReports },
                        set: { newValue in
                            settingsViewModel.settings.notifications.weeklyReports = newValue
                            settingsViewModel.saveSettings()
                        }
                    )
                )
            }
        }
    }
    
    private var displaySection: some View {
        SettingsSection(title: "Display & Appearance") {
            VStack(spacing: 12) {
                SettingsToggleRow(
                    icon: "moon.fill",
                    title: "Use System Theme",
                    subtitle: "Follow system dark/light mode",
                    isOn: Binding(
                        get: { settingsViewModel.settings.display.useSystemTheme },
                        set: { newValue in
                            settingsViewModel.settings.display.useSystemTheme = newValue
                            settingsViewModel.saveSettings()
                        }
                    )
                )
                
                SettingsToggleRow(
                    icon: "sparkles",
                    title: "Animations",
                    subtitle: "Enable smooth animations",
                    isOn: Binding(
                        get: { settingsViewModel.settings.display.animationsEnabled },
                        set: { newValue in
                            settingsViewModel.settings.display.animationsEnabled = newValue
                            settingsViewModel.saveSettings()
                        }
                    )
                )
            }
        }
    }
    
    private var dataSection: some View {
        SettingsSection(title: "Data & Privacy") {
            VStack(spacing: 12) {
                SettingsToggleRow(
                    icon: "icloud.fill",
                    title: "Cloud Backup",
                    subtitle: "Sync your data across devices",
                    isOn: Binding(
                        get: { settingsViewModel.settings.data.cloudBackup },
                        set: { newValue in
                            settingsViewModel.settings.data.cloudBackup = newValue
                            settingsViewModel.saveSettings()
                        }
                    )
                )
                
                SettingsRow(
                    icon: "square.and.arrow.up.fill",
                    title: "Export Data",
                    subtitle: "Download your activity data",
                    action: {
                        showingDataExport = true
                    }
                )
                
                SettingsRow(
                    icon: "trash.fill",
                    title: "Clear Cache",
                    subtitle: "Free up storage space",
                    action: {
                        settingsViewModel.clearCache()
                    }
                )
                
                SettingsToggleRow(
                    icon: "hand.raised.fill",
                    title: "Share Analytics",
                    subtitle: "Help improve the app",
                    isOn: Binding(
                        get: { settingsViewModel.settings.data.shareAnalytics },
                        set: { newValue in
                            settingsViewModel.settings.data.shareAnalytics = newValue
                            settingsViewModel.saveSettings()
                        }
                    )
                )
            }
        }
    }
    
    private var aboutSection: some View {
        SettingsSection(title: "About & Support") {
            VStack(spacing: 12) {
                SettingsRow(
                    icon: "info.circle.fill",
                    title: "About Aerotracker",
                    subtitle: "Version \(settingsViewModel.appVersion)",
                    action: {
                        showingAbout = true
                    }
                )
            }
        }
    }
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 1) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#1A2339") ?? .gray)
                    .neumorphicStyle()
            )
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var trailing: AnyView? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Color(hex: "#01A2FF") ?? .blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if let trailing = trailing {
                    trailing
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(15)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: "#01A2FF") ?? .blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#01A2FF") ?? .blue))
        }
        .padding(15)
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
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
                    VStack(spacing: 30) {
                        // App icon and info
                        appInfoSection
                        
                        // Features
                        featuresSection
                        
                        // Credits
                        creditsSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(settingsViewModel.accentColor)
                }
            }
        }
    }
    
    private var appInfoSection: some View {
        VStack(spacing: 20) {
            // App icon
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
                
                Image(systemName: "figure.run")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text("Aerotracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Your Fitness Journey Companion")
                    .font(.title3)
                    .foregroundColor(settingsViewModel.accentColor)
                
                Text("Version \(settingsViewModel.appVersion) (\(settingsViewModel.buildNumber))")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var featuresSection: some View {
        VStack(spacing: 20) {
            Text("What Makes Aerotracker Special")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 15) {
                AboutFeatureRow(
                    icon: "location.circle.fill",
                    title: "Smart Activity Tracking",
                    description: "Automatically detect and track your workouts with precision"
                )
                
                AboutFeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Performance Analytics",
                    description: "Detailed insights and progress tracking to help you improve"
                )
                
                AboutFeatureRow(
                    icon: "brain.head.profile",
                    title: "AI-Powered Suggestions",
                    description: "Personalized recommendations based on your fitness data"
                )
                
                AboutFeatureRow(
                    icon: "person.3.fill",
                    title: "Community Features",
                    description: "Connect with friends and join challenges for motivation"
                )
            }
        }
    }
    
    private var creditsSection: some View {
        VStack(spacing: 15) {
            Text("Credits")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                Text("Developed with ❤️ for fitness enthusiasts")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Text("Thank you for choosing Aerotracker to power your fitness journey!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#1A2339") ?? .gray)
                    .neumorphicStyle()
            )
        }
    }
}

struct AboutFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: "#01A2FF") ?? .blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
}

// MARK: - Data Export View

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    @State private var selectedFormat: ExportFormat = .gpx
    @State private var includePersonalInfo = true
    @State private var includeActivities = true
    @State private var includeSettings = false
    @State private var isExporting = false
    
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
                    VStack(spacing: 25) {
                        exportInfoSection
                        
                        formatSelectionSection
                        
                        dataOptionsSection
                        
                        exportButtonSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private var exportInfoSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "square.and.arrow.up.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(settingsViewModel.accentColor)
            
            Text("Export Your Data")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Download your activity data in various formats to use with other apps or for backup purposes.")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    private var formatSelectionSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Export Format")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 10) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Button(action: {
                        selectedFormat = format
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(format.displayName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text(getFormatDescription(format))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            if selectedFormat == format {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(settingsViewModel.accentColor)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedFormat == format ? 
                                       settingsViewModel.accentColor : Color.clear, lineWidth: 2)
                                .neumorphicStyle()
                        )
                    }
                }
            }
        }
    }
    
    private var dataOptionsSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("What to Include")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ExportOptionRow(
                    title: "Personal Information",
                    subtitle: "Profile data, goals, and preferences",
                    isSelected: $includePersonalInfo
                )
                
                ExportOptionRow(
                    title: "Activity Data",
                    subtitle: "All recorded workouts and routes",
                    isSelected: $includeActivities
                )
                
                ExportOptionRow(
                    title: "App Settings",
                    subtitle: "Your app configuration and preferences",
                    isSelected: $includeSettings
                )
            }
        }
    }
    
    private var exportButtonSection: some View {
        VStack(spacing: 15) {
            Button(action: exportData) {
                HStack {
                    if isExporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.title2)
                    }
                    
                    Text(isExporting ? "Exporting..." : "Export Data")
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
            .disabled(isExporting || (!includePersonalInfo && !includeActivities && !includeSettings))
            .opacity((!includePersonalInfo && !includeActivities && !includeSettings) ? 0.6 : 1.0)
            
            Text("The exported file will be saved to your device and can be shared or backed up.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
    
    private func getFormatDescription(_ format: ExportFormat) -> String {
        switch format {
        case .gpx:
            return "GPS Exchange Format - Compatible with most fitness apps"
        case .tcx:
            return "Training Center XML - Detailed workout data format"
        case .csv:
            return "Comma Separated Values - Spreadsheet compatible"
        case .json:
            return "JavaScript Object Notation - Complete data structure"
        }
    }
    
    private func exportData() {
        isExporting = true
        
        Task {
            do {
                _ = try await settingsViewModel.exportData(format: selectedFormat)
                await MainActor.run {
                    isExporting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    // Handle error
                }
            }
        }
    }
}

struct ExportOptionRow: View {
    let title: String
    let subtitle: String
    @Binding var isSelected: Bool
    
    var body: some View {
        Button(action: {
            isSelected.toggle()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isSelected ? Color(hex: "#01A2FF") ?? .blue : .white.opacity(0.5))
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#1A2339") ?? .gray)
                    .neumorphicStyle()
            )
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel())
} 
