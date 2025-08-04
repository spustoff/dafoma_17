//
//  ActivitiesView.swift
//  Aerotracker: Win
//
//  Created by Вячеслав on 8/4/25.
//

import SwiftUI

struct ActivitiesView: View {
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    @State private var showingFilterOptions = false
    @State private var selectedActivity: Activity?
    @State private var showingActivityDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and filter bar
                    searchAndFilterBar
                    
                    // Activities list
                    activitiesList
                }
            }
            .navigationTitle("Activities")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFilterOptions.toggle()
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(settingsViewModel.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilterOptions) {
            FilterOptionsView()
                .environmentObject(activityViewModel)
                .environmentObject(settingsViewModel)
        }
        .sheet(item: $selectedActivity) { activity in
            ActivityDetailView(activity: activity)
                .environmentObject(activityViewModel)
                .environmentObject(settingsViewModel)
        }
        .refreshable {
            activityViewModel.loadActivities()
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
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.7))
                
                TextField("Search activities...", text: $activityViewModel.searchText)
                    .font(.body)
                    .foregroundColor(.white)
                
                if !activityViewModel.searchText.isEmpty {
                    Button(action: {
                        activityViewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#1A2339") ?? .gray)
                    .neumorphicStyle()
            )
            
            // Quick filter buttons
            if activityViewModel.filterType != nil || activityViewModel.sortOrder != .dateDescending {
                HStack {
                    if let filterType = activityViewModel.filterType {
                        FilterChip(
                            title: filterType.displayName,
                            isSelected: true,
                            action: {
                                activityViewModel.filterType = nil
                            }
                        )
                    }
                    
                    if activityViewModel.sortOrder != .dateDescending {
                        FilterChip(
                            title: activityViewModel.sortOrder.displayName,
                            isSelected: true,
                            action: {
                                activityViewModel.sortOrder = .dateDescending
                            }
                        )
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var activitiesList: some View {
        Group {
            if activityViewModel.isLoading {
                ProgressView("Loading activities...")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if activityViewModel.filteredActivities.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(activityViewModel.filteredActivities) { activity in
                        ActivityListRow(activity: activity) {
                            selectedActivity = activity
                            showingActivityDetail = true
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                activityViewModel.deleteActivity(activity)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .modifier(ConditionalScrollContentBackground())
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: activityViewModel.searchText.isEmpty ? "figure.run" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text(activityViewModel.searchText.isEmpty ? "No Activities Yet" : "No Results Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(activityViewModel.searchText.isEmpty ? 
                 "Start your first workout to see it here!" : 
                 "Try adjusting your search or filters")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

// MARK: - Activity List Row

struct ActivityListRow: View {
    let activity: Activity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // Activity icon and type
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: activity.intensityColor)?.opacity(0.2) ?? .blue.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: activity.type.icon)
                            .font(.title2)
                            .foregroundColor(Color(hex: activity.intensityColor) ?? .blue)
                    }
                    
                    Text(activity.type.displayName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                // Activity details
                VStack(alignment: .leading, spacing: 6) {
                    Text(activity.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 15) {
                        ActivityStat(
                            icon: "location",
                            value: activity.formattedDistance
                        )
                        
                        ActivityStat(
                            icon: "clock",
                            value: activity.formattedDuration
                        )
                        
                        ActivityStat(
                            icon: "flame.fill",
                            value: "\(activity.calories)"
                        )
                    }
                    
                    Text(formatDate(activity.startTime))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: "#1A2339") ?? .gray)
                    .neumorphicStyle()
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDate(date, inSameDayAs: Date()) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if Calendar.current.isDate(date, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()) {
            formatter.dateFormat = "'Yesterday at' h:mm a"
        } else {
            formatter.dateFormat = "MMM d 'at' h:mm a"
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - Activity Stat

struct ActivityStat: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color(hex: "#01A2FF") ?? .blue)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if isSelected {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "#01A2FF") ?? .blue : Color(hex: "#1A2339") ?? .gray)
            )
            .foregroundColor(.white)
        }
    }
}

// MARK: - Filter Options View

struct FilterOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 25) {
                        // Activity Type Filter
                        filterSection(
                            title: "Activity Type",
                            content: AnyView(activityTypeFilter)
                        )
                        
                        // Sort Options
                        filterSection(
                            title: "Sort By",
                            content: AnyView(sortOptionsFilter)
                        )
                        
                        // Reset filters button
                        Button("Reset All Filters") {
                            activityViewModel.filterType = nil
                            activityViewModel.sortOrder = .dateDescending
                        }
                        .font(.headline)
                        .foregroundColor(settingsViewModel.accentColor)
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Filter & Sort")
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
    
    private func filterSection<Content: View>(title: String, content: Content) -> some View {
        VStack(spacing: 15) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            content
        }
    }
    
    private var activityTypeFilter: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            // All activities option
            FilterOptionButton(
                title: "All",
                icon: "list.bullet",
                isSelected: activityViewModel.filterType == nil,
                action: {
                    activityViewModel.filterType = nil
                }
            )
            
            // Individual activity types
            ForEach(ActivityType.allCases, id: \.self) { activityType in
                FilterOptionButton(
                    title: activityType.displayName,
                    icon: activityType.icon,
                    isSelected: activityViewModel.filterType == activityType,
                    action: {
                        activityViewModel.filterType = activityType
                    }
                )
            }
        }
    }
    
    private var sortOptionsFilter: some View {
        VStack(spacing: 12) {
            ForEach(SortOrder.allCases, id: \.self) { sortOrder in
                Button(action: {
                    activityViewModel.sortOrder = sortOrder
                }) {
                    HStack {
                        Text(sortOrder.displayName)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if activityViewModel.sortOrder == sortOrder {
                            Image(systemName: "checkmark")
                                .font(.body)
                                .foregroundColor(settingsViewModel.accentColor)
                        }
                    }
                    .padding(15)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(activityViewModel.sortOrder == sortOrder ? 
                                   settingsViewModel.accentColor : Color.clear, lineWidth: 2)
                            .neumorphicStyle()
                    )
                }
            }
        }
    }
}

// MARK: - Filter Option Button

struct FilterOptionButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : Color(hex: "#01A2FF") ?? .blue)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? 
                         Color(hex: "#01A2FF") ?? .blue :
                         Color(hex: "#1A2339") ?? .gray)
                    .neumorphicStyle()
            )
        }
    }
}

// MARK: - iOS Compatibility

struct ConditionalScrollContentBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

#Preview {
    ActivitiesView()
        .environmentObject(ActivityViewModel())
        .environmentObject(SettingsViewModel())
} 
