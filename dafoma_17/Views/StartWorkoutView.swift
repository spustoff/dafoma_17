//
//  StartWorkoutView.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import SwiftUI

struct StartWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    @State private var selectedActivityType: ActivityType = .running
    @State private var showingCustomSettings = false
    @State private var workoutName = ""
    @State private var targetDuration: TimeInterval = 1800 // 30 minutes
    @State private var targetDistance: Double = 5000 // 5 km
    @State private var useTargetDuration = false
    @State private var useTargetDistance = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 25) {
                        headerSection
                        
                        activityTypeSelection
                        
                        workoutCustomization
                        
                        if showingCustomSettings {
                            customSettingsSection
                        }
                        
                        startButton
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Start Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(showingCustomSettings ? "Less" : "More") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingCustomSettings.toggle()
                        }
                    }
                    .foregroundColor(settingsViewModel.accentColor)
                }
            }
        }
        .onAppear {
            workoutName = generateWorkoutName()
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
        VStack(spacing: 15) {
            // Activity icon
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
                
                Image(systemName: selectedActivityType.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 5) {
                Text("Ready to Start")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(selectedActivityType.displayName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(settingsViewModel.accentColor)
            }
        }
    }
    
    private var activityTypeSelection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Activity Type")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ActivityType.allCases, id: \.self) { activityType in
                    ActivityTypeCard(
                        activityType: activityType,
                        isSelected: selectedActivityType == activityType,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedActivityType = activityType
                                workoutName = generateWorkoutName()
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var workoutCustomization: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Workout Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                CustomTextField(
                    title: "Workout Name",
                    text: $workoutName,
                    placeholder: "Enter workout name"
                )
                
                HStack(spacing: 15) {
                    Button(action: {
                        useTargetDuration.toggle()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: useTargetDuration ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundColor(useTargetDuration ? settingsViewModel.accentColor : .white.opacity(0.7))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Target Duration")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text(formatDuration(targetDuration))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        .padding(15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#1A2339") ?? .gray)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(useTargetDuration ? settingsViewModel.accentColor : Color.clear, lineWidth: 2)
                                )
                                .neumorphicStyle()
                        )
                    }
                    
                    Button(action: {
                        useTargetDistance.toggle()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: useTargetDistance ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundColor(useTargetDistance ? settingsViewModel.accentColor : .white.opacity(0.7))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Target Distance")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text(formatDistance(targetDistance))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        .padding(15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#1A2339") ?? .gray)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(useTargetDistance ? settingsViewModel.accentColor : Color.clear, lineWidth: 2)
                                )
                                .neumorphicStyle()
                        )
                    }
                }
            }
        }
    }
    
    private var customSettingsSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Advanced Settings")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 15) {
                if useTargetDuration {
                    DurationPicker(
                        title: "Target Duration",
                        duration: $targetDuration
                    )
                }
                
                if useTargetDistance {
                    DistancePicker(
                        title: "Target Distance",
                        distance: $targetDistance
                    )
                }
                
                SettingToggle(
                    title: "Auto Pause",
                    subtitle: "Automatically pause when you stop moving",
                    isOn: .constant(settingsViewModel.settings.workout.autoPause)
                )
                
                SettingToggle(
                    title: "Voice Coaching",
                    subtitle: "Get audio feedback during your workout",
                    isOn: .constant(settingsViewModel.settings.general.voiceCoaching)
                )
                
                SettingToggle(
                    title: "Keep Screen On",
                    subtitle: "Prevent screen from turning off during workout",
                    isOn: .constant(settingsViewModel.settings.general.keepScreenOn)
                )
            }
        }
        .transition(.opacity.combined(with: .slide))
    }
    
    private var startButton: some View {
        Button(action: startWorkout) {
            HStack {
                Image(systemName: "play.fill")
                    .font(.title2)
                
                Text("Start Workout")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                settingsViewModel.accentColor.opacity(0.8),
                                settingsViewModel.accentColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .neumorphicStyle()
            )
        }
        .disabled(workoutName.trimmingCharacters(in: .whitespaces).isEmpty)
        .opacity(workoutName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
    }
    
    private func startWorkout() {
        activityViewModel.selectedActivityType = selectedActivityType
        activityViewModel.startActivity()
        dismiss()
    }
    
    private func generateWorkoutName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateString = formatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeString = timeFormatter.string(from: Date())
        
        return "\(selectedActivityType.displayName) - \(dateString) at \(timeString)"
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
}

// MARK: - Supporting Views

struct ActivityTypeCard: View {
    let activityType: ActivityType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: activityType.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Color(hex: "#01A2FF") ?? .blue)
                
                Text(activityType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? 
                         Color(hex: "#01A2FF") ?? .blue :
                         Color(hex: "#1A2339") ?? .gray)
                    .neumorphicStyle()
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
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
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#1A2339") ?? .gray)
                        .neumorphicStyle()
                )
                .foregroundColor(.white)
        }
    }
}

struct DurationPicker: View {
    let title: String
    @Binding var duration: TimeInterval
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 30
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                HStack {
                    Text("Hours")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Picker("Hours", selection: $hours) {
                        ForEach(0..<6) { hour in
                            Text("\(hour)")
                                .foregroundColor(.white)
                                .tag(hour)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 60, height: 80)
                }
                
                HStack {
                    Text("Minutes")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Picker("Minutes", selection: $minutes) {
                        ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { minute in
                            Text("\(minute)")
                                .foregroundColor(.white)
                                .tag(minute)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 60, height: 80)
                }
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#1A2339") ?? .gray)
                    .neumorphicStyle()
            )
            .onChange(of: hours) { newValue in
                updateDuration()
            }
            .onChange(of: minutes) { newValue in
                updateDuration()
            }
            .onAppear {
                hours = Int(duration) / 3600
                minutes = (Int(duration) % 3600) / 60
            }
        }
    }
    
    private func updateDuration() {
        duration = TimeInterval(hours * 3600 + minutes * 60)
    }
}

struct DistancePicker: View {
    let title: String
    @Binding var distance: Double
    
    @State private var kilometers: Int = 5
    @State private var meters: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                HStack {
                    Text("Kilometers")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Picker("Kilometers", selection: $kilometers) {
                        ForEach(0..<51) { km in
                            Text("\(km)")
                                .foregroundColor(.white)
                                .tag(km)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 60, height: 80)
                }
                
                HStack {
                    Text("Meters")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Picker("Meters", selection: $meters) {
                        ForEach(Array(stride(from: 0, through: 950, by: 50)), id: \.self) { meter in
                            Text("\(meter)")
                                .foregroundColor(.white)
                                .tag(meter)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 60, height: 80)
                }
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#1A2339") ?? .gray)
                    .neumorphicStyle()
            )
            .onChange(of: kilometers) { newValue in
                updateDistance()
            }
            .onChange(of: meters) { newValue in
                updateDistance()
            }
            .onAppear {
                kilometers = Int(distance / 1000)
                meters = Int(distance.truncatingRemainder(dividingBy: 1000))
            }
        }
    }
    
    private func updateDistance() {
        distance = Double(kilometers * 1000 + meters)
    }
}

struct SettingToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#01A2FF") ?? .blue))
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
}

#Preview {
    StartWorkoutView()
        .environmentObject(ActivityViewModel())
        .environmentObject(SettingsViewModel())
} 