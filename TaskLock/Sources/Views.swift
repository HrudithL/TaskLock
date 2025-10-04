import SwiftUI
import Charts
import Foundation
import CoreData
import UserNotifications
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine
import CoreNFC
import AVFoundation
import UIKit

// MARK: - Main Tab View
struct MainTabView: View {
    @StateObject private var appState = AppState()
    @StateObject private var analyticsManager = AnalyticsManager(
        persistenceController: PersistenceController.shared,
        taskManager: TaskManager(persistenceController: PersistenceController.shared)
    )
    
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Today")
                }
            
            UpcomingView()
                .tabItem {
                    Image(systemName: "calendar.badge.clock")
                    Text("Upcoming")
                }
            
            CategoriesView()
                .tabItem {
                    Image(systemName: "folder")
                    Text("Categories")
                }
            
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Stats")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .environmentObject(appState)
        .environmentObject(analyticsManager)
        .onAppear {
            analyticsManager.updateAnalytics()
        }
    }
}

// MARK: - Today View
struct TodayView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingQuickAdd = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Blocking Status Banner
                if case .active(let profile, let reason) = appState.currentBlockingStatus {
                    BlockingStatusBanner(profile: profile, reason: reason)
                }
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Overdue Tasks
                        if !appState.getOverdueTasks().isEmpty {
                            TaskSection(
                                title: "Overdue",
                                tasks: appState.getOverdueTasks(),
                                color: .red
                            )
                        }
                        
                        // Due Today Tasks
                        if !appState.getTasksDueToday().isEmpty {
                            TaskSection(
                                title: "Due Today",
                                tasks: appState.getTasksDueToday(),
                                color: .blue
                            )
                        }
                        
                        // Active Tasks
                        if !appState.getActiveTasks().isEmpty {
                            TaskSection(
                                title: "Active",
                                tasks: appState.getActiveTasks(),
                                color: .orange
                            )
                        }
                        
                        // Empty State
                        if appState.getOverdueTasks().isEmpty && 
                           appState.getTasksDueToday().isEmpty && 
                           appState.getActiveTasks().isEmpty {
                            EmptyStateView(
                                icon: "checkmark.circle",
                                title: "All caught up!",
                                subtitle: "No tasks due today"
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingQuickAdd = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddView()
            }
        }
    }
}

// MARK: - Task Section
struct TaskSection: View {
    let title: String
    let tasks: [Task]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(tasks, id: \.id) { task in
                TaskRowView(task: task)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    @EnvironmentObject var appState: AppState
    let task: Task
    @State private var isCompleted: Bool
    
    init(task: Task) {
        self.task = task
        self._isCompleted = State(initialValue: task.isCompleted)
    }
    
    var body: some View {
        HStack {
            Button(action: {
                isCompleted.toggle()
                if isCompleted {
                    appState.completeTask(task)
                } else {
                    // In a real implementation, you'd have an uncomplete method
                    appState.updateTask(task)
                }
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(isCompleted)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(task.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                    
                    Text(task.priority.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.2))
                        .foregroundColor(priorityColor)
                        .cornerRadius(4)
                    
                    if let dueDate = task.dueDate {
                        Text(dueDate.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Blocking Status Banner
struct BlockingStatusBanner: View {
    @EnvironmentObject var appState: AppState
    let profile: BlockingProfile
    let reason: String
    
    var body: some View {
        HStack {
            Image(systemName: "shield.fill")
                .foregroundColor(.red)
            
            VStack(alignment: .leading) {
                Text("Blocking Active")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Stop") {
                Task {
                    await appState.attemptDisableBlocking()
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Upcoming View
struct UpcomingView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingQuickAdd = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(groupedUpcomingTasks.keys.sorted(), id: \.self) { date in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(groupedUpcomingTasks[date]?.count ?? 0)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            ForEach(groupedUpcomingTasks[date] ?? [], id: \.id) { task in
                                TaskRowView(task: task)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Upcoming")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingQuickAdd = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingQuickAdd) {
                QuickAddView()
            }
        }
    }
    
    private var groupedUpcomingTasks: [Date: [Task]] {
        let upcomingTasks = appState.getUpcomingTasks(days: 7)
        return Dictionary(grouping: upcomingTasks) { task in
            Calendar.current.startOfDay(for: task.dueDate ?? Date())
        }
    }
}

// MARK: - Categories View
struct CategoriesView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(appState.categories, id: \.id) { category in
                        CategoryCard(category: category)
                    }
                }
                .padding()
            }
            .navigationTitle("Categories")
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    @EnvironmentObject var appState: AppState
    let category: Category
    
    var body: some View {
        NavigationLink(destination: CategoryDetailView(category: category)) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 32))
                    .foregroundColor(Color(category.color))
                
                Text(category.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text("\(tasksInCategory.count) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var tasksInCategory: [Task] {
        appState.getTasksByCategory(category.name)
    }
}

// MARK: - Category Detail View
struct CategoryDetailView: View {
    @EnvironmentObject var appState: AppState
    let category: Category
    
    var body: some View {
        List {
            ForEach(tasksInCategory, id: \.id) { task in
                TaskRowView(task: task)
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var tasksInCategory: [Task] {
        appState.getTasksByCategory(category.name)
    }
}

// MARK: - Stats View
struct StatsView: View {
    @EnvironmentObject var analyticsManager: AnalyticsManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Summary Cards
                    SummaryCardsView()
                    
                    // Completion Rate Chart
                    CompletionRateChart()
                    
                    // Category Breakdown
                    CategoryBreakdownChart()
                    
                    // Focus Time Chart
                    FocusTimeChart()
                    
                    // Heatmap
                    HeatmapView()
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .onAppear {
                analyticsManager.updateAnalytics()
            }
        }
    }
}

// MARK: - Summary Cards
struct SummaryCardsView: View {
    @EnvironmentObject var analyticsManager: AnalyticsManager
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            SummaryCard(
                title: "Focus Time",
                value: "\(analyticsManager.getTotalFocusTimeSaved())m",
                icon: "clock.fill",
                color: .blue
            )
            
            SummaryCard(
                title: "Streak",
                value: "\(analyticsManager.getStreakDays()) days",
                icon: "flame.fill",
                color: .orange
            )
            
            SummaryCard(
                title: "Avg Tasks/Day",
                value: String(format: "%.1f", analyticsManager.getAverageTasksPerDay()),
                icon: "chart.bar.fill",
                color: .green
            )
            
            SummaryCard(
                title: "On-Time Rate",
                value: String(format: "%.1f%%", analyticsManager.getOnTimeCompletionRate()),
                icon: "checkmark.circle.fill",
                color: .purple
            )
        }
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
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
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Completion Rate Chart
struct CompletionRateChart: View {
    @EnvironmentObject var analyticsManager: AnalyticsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completion Rate")
                .font(.headline)
            
            Chart(analyticsManager.completionChartData) { data in
                LineMark(
                    x: .value("Date", data.date),
                    y: .value("On-Time %", data.onTimePercentage)
                )
                .foregroundStyle(.blue)
                
                BarMark(
                    x: .value("Date", data.date),
                    y: .value("Completed", data.completed)
                )
                .foregroundStyle(.green.opacity(0.3))
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Category Breakdown Chart
struct CategoryBreakdownChart: View {
    @EnvironmentObject var analyticsManager: AnalyticsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .font(.headline)
            
            Chart(analyticsManager.categoryBreakdown) { data in
                SectorMark(
                    angle: .value("Percentage", data.percentage),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Category", data.category))
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Focus Time Chart
struct FocusTimeChart: View {
    @EnvironmentObject var analyticsManager: AnalyticsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Time")
                .font(.headline)
            
            Chart(analyticsManager.focusTimeData) { data in
                BarMark(
                    x: .value("Date", data.date),
                    y: .value("Minutes", data.focusTimeMinutes)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Heatmap View
struct HeatmapView: View {
    @EnvironmentObject var analyticsManager: AnalyticsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Heatmap")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 2) {
                ForEach(analyticsManager.heatmapData) { data in
                    Rectangle()
                        .fill(heatmapColor(for: data.tasksCompleted))
                        .frame(width: 20, height: 20)
                        .cornerRadius(2)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func heatmapColor(for tasksCompleted: Int) -> Color {
        switch tasksCompleted {
        case 0: return Color(.systemGray5)
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.6)
        case 3: return Color.green.opacity(0.8)
        default: return Color.green
        }
    }
}

// MARK: - Quick Add View
struct QuickAddView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var selectedCategory = "Personal"
    @State private var selectedPriority = TaskPriority.medium
    @State private var estimateMinutes = 30
    @State private var hasDueDate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task title", text: $title)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section("Category & Priority") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(appState.categories, id: \.name) { category in
                            Text(category.name).tag(category.name)
                        }
                    }
                    
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                }
                
                Section("Estimate") {
                    Stepper("\(estimateMinutes) minutes", value: $estimateMinutes, in: 5...480, step: 5)
                }
                
                Section("Presets") {
                    ForEach(appState.presets, id: \.id) { preset in
                        Button(action: {
                            applyPreset(preset)
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(preset.title)
                                        .foregroundColor(.primary)
                                    if let notes = preset.notes {
                                        Text(notes)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Text("\(preset.estimateMinutes)m")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func applyPreset(_ preset: TaskPreset) {
        title = preset.title
        notes = preset.notes ?? ""
        selectedCategory = preset.category
        selectedPriority = preset.priority
        estimateMinutes = Int(preset.estimateMinutes)
    }
    
    private func addTask() {
        appState.createTask(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            dueDate: hasDueDate ? dueDate : nil,
            category: selectedCategory,
            priority: selectedPriority,
            estimateMinutes: Int32(estimateMinutes)
        )
        dismiss()
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAuthorizationAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Authorization Section
                Section {
                    HStack {
                        Image(systemName: appState.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(appState.isAuthorized ? .green : .orange)
                        
                        VStack(alignment: .leading) {
                            Text("Family Controls")
                                .font(.headline)
                            Text(appState.isAuthorized ? "Authorized" : "Authorization Required")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !appState.isAuthorized {
                            Button("Authorize") {
                                Task {
                                    await appState.requestAuthorization()
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                } header: {
                    Text("Blocking")
                }
                
                // Blocking Profiles Section
                Section {
                    ForEach(appState.blockingProfiles, id: \.id) { profile in
                        NavigationLink(destination: ProfileDetailView(profile: profile)) {
                            VStack(alignment: .leading) {
                                Text(profile.name)
                                    .font(.headline)
                                Text(profile.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Profiles")
                }
                
                // Data Management Section
                Section {
                    Button("Export Tasks") {
                        // Export functionality
                    }
                    
                    Button("Export Analytics") {
                        // Export functionality
                    }
                    
                    Button("Reset All Data") {
                        // Reset functionality
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("Data Management")
                }
                
                // Demo Mode Section
                Section {
                    Button("Enable Demo Mode") {
                        appState.enableDemoMode()
                    }
                    
                    Button("Disable Demo Mode") {
                        appState.disableDemoMode()
                    }
                } header: {
                    Text("Demo Mode")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Profile Detail View
struct ProfileDetailView: View {
    @EnvironmentObject var appState: AppState
    let profile: BlockingProfile
    
    var body: some View {
        Form {
            Section("Profile Info") {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(profile.name)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Description")
                    Spacer()
                    Text(profile.description)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Blocking Settings") {
                HStack {
                    Text("Task Conditional")
                    Spacer()
                    Text(profile.isTaskConditional ? "Yes" : "No")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Condition Type")
                    Spacer()
                    Text(profile.conditionType.displayName)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Grace Period")
                    Spacer()
                    Text("\(profile.gracePeriodMinutes) minutes")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Completion Policy")
                    Spacer()
                    Text(profile.completionPolicy.displayName)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Security") {
                HStack {
                    Text("Strict Mode")
                    Spacer()
                    Text(profile.isStrictMode ? "Enabled" : "Disabled")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Physical Unlock")
                    Spacer()
                    Text(profile.requiresPhysicalUnlock ? "Required" : "Not Required")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(profile.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MainTabView()
}
