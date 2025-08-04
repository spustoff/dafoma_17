//
//  OnboardingView.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                    .padding(.top, 50)
                
                // Content
                contentView
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 50)
                    .animation(.easeOut(duration: 0.5), value: animateContent)
                
                Spacer()
                
                // Navigation buttons
                navigationButtons
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                animateContent = true
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
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
    
    private var progressIndicator: some View {
        VStack(spacing: 15) {
            HStack(spacing: 8) {
                ForEach(0..<OnboardingStep.allCases.count, id: \.self) { index in
                    Circle()
                        .fill(index <= viewModel.currentStep.rawValue ? 
                             Color(hex: "#01A2FF") ?? .blue : 
                             Color.white.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                }
            }
            
            ProgressView(value: viewModel.progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "#01A2FF") ?? .blue))
                .frame(height: 4)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
                .padding(.horizontal, 40)
                .animation(.easeInOut(duration: 0.3), value: viewModel.progressPercentage)
        }
    }
    
    private var contentView: some View {
        Group {
            switch viewModel.currentStep {
            case .welcome:
                WelcomeStepView()
            case .personalSetup:
                PersonalSetupStepView()
            case .featureShowcase:
                FeatureShowcaseStepView()
            case .permissions:
                PermissionsStepView()
            case .readyToGo:
                ReadyToGoStepView()
            }
        }
        .environmentObject(viewModel)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 20) {
            // Back button
            if viewModel.currentStep != .welcome {
                Button(action: { viewModel.previousStep() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.headline)
                }
                .buttonStyle(NeumorphicButtonStyle(color: Color.gray.opacity(0.3)))
            } else {
                Spacer()
            }
            
            Spacer()
            
            // Next/Skip button
            Button(action: { 
                if viewModel.currentStep == .readyToGo {
                    viewModel.nextStep()
                } else {
                    viewModel.nextStep()
                }
            }) {
                HStack {
                    Text(viewModel.currentStep == .readyToGo ? "Get Started" : "Next")
                    if viewModel.currentStep != .readyToGo {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.headline)
            }
            .buttonStyle(NeumorphicButtonStyle(color: Color(hex: "#01A2FF") ?? .blue))
            .disabled(!canProceed)
            .opacity(canProceed ? 1.0 : 0.6)
            
            // Skip button
            if viewModel.currentStep != .readyToGo {
                Button("Skip") {
                    viewModel.skipOnboarding()
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var canProceed: Bool {
        switch viewModel.currentStep {
        case .welcome, .featureShowcase, .permissions:
            return true
        case .personalSetup:
            return viewModel.canProceedFromPersonalSetup
        case .readyToGo:
            return viewModel.canCompleteOnboarding
        }
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 30) {
            // App icon placeholder
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#01A2FF")?.opacity(0.3) ?? .blue.opacity(0.3),
                                Color(hex: "#01A2FF") ?? .blue
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .neumorphicStyle()
                
                Image(systemName: "figure.run")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 15) {
                Text("Welcome to")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Aerotracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Your journey to better fitness starts here")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "#01A2FF") ?? .blue)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                FeatureHighlight(
                    icon: "location.circle.fill",
                    title: "Smart Tracking",
                    description: "Automatically detect and track your activities"
                )
                
                FeatureHighlight(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Performance Analytics",
                    description: "Detailed insights and progress tracking"
                )
                
                FeatureHighlight(
                    icon: "target",
                    title: "Goal Achievement",
                    description: "Set and reach your fitness goals"
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 40)
    }
}

// MARK: - Personal Setup Step

struct PersonalSetupStepView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 25) {
                headerSection
                
                personalInfoSection
                
                fitnessLevelSection
                
                goalsSection
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Personal Setup")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Help us personalize your experience")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    private var personalInfoSection: some View {
        VStack(spacing: 15) {
            Text("Basic Information")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                OnboardingTextField(
                    title: "Name",
                    text: $viewModel.userName,
                    placeholder: "Enter your name"
                )
                
                HStack(spacing: 12) {
                    OnboardingTextField(
                        title: "Age",
                        text: $viewModel.userAge,
                        placeholder: "25",
                        keyboardType: .numberPad
                    )
                    
                    OnboardingTextField(
                        title: "Weight (kg)",
                        text: $viewModel.userWeight,
                        placeholder: "70",
                        keyboardType: .decimalPad
                    )
                }
                
                OnboardingTextField(
                    title: "Height (cm)",
                    text: $viewModel.userHeight,
                    placeholder: "175",
                    keyboardType: .numberPad
                )
                
                // Gender selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gender")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 12) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Button(action: {
                                viewModel.selectedGender = gender
                            }) {
                                Text(gender.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(viewModel.selectedGender == gender ? 
                                                 Color(hex: "#01A2FF") ?? .blue : 
                                                 Color(hex: "#1A2339") ?? .gray)
                                    )
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var fitnessLevelSection: some View {
        VStack(spacing: 15) {
            Text("Fitness Level")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(FitnessLevel.allCases, id: \.self) { level in
                    Button(action: {
                        viewModel.selectedFitnessLevel = level
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(level.displayName)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text(level.description)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            if viewModel.selectedFitnessLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Color(hex: "#01A2FF") ?? .blue)
                            }
                        }
                        .padding(15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedFitnessLevel == level ? 
                                       Color(hex: "#01A2FF") ?? .blue : 
                                       Color.clear, lineWidth: 2)
                                .neumorphicStyle()
                        )
                    }
                }
            }
        }
    }
    
    private var goalsSection: some View {
        VStack(spacing: 15) {
            Text("Fitness Goals")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Select your main goals (you can change these later)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(GoalType.allCases, id: \.self) { goalType in
                    Button(action: {
                        if viewModel.selectedGoals.contains(goalType) {
                            viewModel.selectedGoals.remove(goalType)
                        } else {
                            viewModel.selectedGoals.insert(goalType)
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(goalType.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            if viewModel.selectedGoals.contains(goalType) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(Color(hex: "#01A2FF") ?? .blue)
                            }
                        }
                        .frame(minHeight: 60)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(viewModel.selectedGoals.contains(goalType) ? 
                                       Color(hex: "#01A2FF") ?? .blue : 
                                       Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Feature Showcase Step

struct FeatureShowcaseStepView: View {
    @State private var currentFeature = 0
    private let features = [
        OnboardingFeature(
            icon: "figure.run.circle.fill",
            title: "Adaptive Activity Tracking",
            description: "Automatically detect different types of physical activity using motion sensors",
            color: Color(hex: "#01A2FF") ?? .blue
        ),
        OnboardingFeature(
            icon: "map.circle.fill",
            title: "Performance Heatmaps",
            description: "Generate real-time heatmaps of activity intensity and routes",
            color: Color.green
        ),
        OnboardingFeature(
            icon: "brain.head.profile",
            title: "AI-Driven Suggestions",
            description: "Get personalized exercise recommendations based on your progress",
            color: Color.purple
        ),
        OnboardingFeature(
            icon: "person.3.fill",
            title: "Community Challenges",
            description: "Join challenges and compete with friends to stay motivated",
            color: Color.orange
        )
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Discover Aerotracker")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            TabView(selection: $currentFeature) {
                ForEach(0..<features.count, id: \.self) { index in
                    FeatureShowcaseCard(feature: features[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 400)
            
            // Custom page indicator
            HStack(spacing: 8) {
                ForEach(0..<features.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentFeature ? 
                             Color(hex: "#01A2FF") ?? .blue : 
                             Color.white.opacity(0.3))
                        .frame(width: 10, height: 10)
                        .animation(.easeInOut(duration: 0.3), value: currentFeature)
                }
            }
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Permissions Step

struct PermissionsStepView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Enable Features")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Grant permissions for the best experience")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                PermissionCard(
                    icon: "location.circle.fill",
                    title: "Location Access",
                    description: "Required for tracking your routes and distance",
                    isGranted: viewModel.allowLocationAccess,
                    action: {
                        viewModel.requestLocationPermission()
                    }
                )
                
                PermissionCard(
                    icon: "bell.circle.fill",
                    title: "Notifications",
                    description: "Get workout reminders and achievement notifications",
                    isGranted: viewModel.allowNotifications,
                    action: {
                        viewModel.requestNotificationPermission()
                    }
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Ready to Go Step

struct ReadyToGoStepView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            // Success icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.3), Color.green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .neumorphicStyle()
                
                Image(systemName: "checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 15) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Everything is configured and ready to go")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                Text("What's next?")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                VStack(spacing: 15) {
                    NextStepItem(
                        icon: "plus.circle.fill",
                        title: "Start your first workout",
                        description: "Tap the center button to begin tracking"
                    )
                    
                    NextStepItem(
                        icon: "target",
                        title: "Set your goals",
                        description: "Define what you want to achieve"
                    )
                    
                    NextStepItem(
                        icon: "person.circle.fill",
                        title: "Explore your profile",
                        description: "View your progress and achievements"
                    )
                }
            }
            
            // Terms agreement
            HStack(alignment: .top, spacing: 10) {
                Button(action: {
                    viewModel.agreedToTerms.toggle()
                }) {
                    Image(systemName: viewModel.agreedToTerms ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundColor(viewModel.agreedToTerms ? Color(hex: "#01A2FF") ?? .blue : .white.opacity(0.7))
                }
                
                Text("I agree to the Terms of Service and Privacy Policy")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Supporting Views and Structs

struct FeatureHighlight: View {
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
    }
}

struct OnboardingTextField: View {
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

struct OnboardingFeature {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct FeatureShowcaseCard: View {
    let feature: OnboardingFeature
    
    var body: some View {
        VStack(spacing: 25) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [feature.color.opacity(0.3), feature.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .neumorphicStyle()
                
                Image(systemName: feature.icon)
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 15) {
                Text(feature.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(feature.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, 20)
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(Color(hex: "#01A2FF") ?? .blue)
                .frame(width: 40)
            
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
            
            Button(action: action) {
                Text(isGranted ? "Granted" : "Allow")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isGranted ? Color.green : Color(hex: "#01A2FF") ?? .blue)
                    )
                    .foregroundColor(.white)
            }
            .disabled(isGranted)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(hex: "#1A2339") ?? .gray)
                .neumorphicStyle()
        )
    }
}

struct NextStepItem: View {
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
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(OnboardingViewModel())
} 
