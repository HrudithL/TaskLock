import SwiftUI
import Charts

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            TodayView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Today")
                }
                .tag(0)
            
            UpcomingView()
                .tabItem {
                    Image(systemName: "calendar.badge.clock")
                    Text("Upcoming")
                }
                .tag(1)
            
            CategoriesView()
                .tabItem {
                    Image(systemName: "folder")
                    Text("Categories")
                }
                .tag(2)
            
            AllTasksView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("All Tasks")
                }
                .tag(3)
            
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Stats")
                }
                .tag(4)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(5)
        }
        .overlay(
            // Blocking overlay
            Group {
                if case .active(let profile, let reason) = appState.currentBlockingStatus {
                    BlockingOverlay(profile: profile, reason: reason)
                }
            }
        )
    }
}

// MARK: - Today View
struct TodayView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            VStack {
                if appState.getTasksDueToday().isEmpty {
                    EmptyTodayView()
                } else {
                    TaskListView(tasks: appState.getTasksDueToday())
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
    }
}

// MARK: - Upcoming View
struct UpcomingView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            VStack {
                if appState.getOverdueTasks().isEmpty && appState.tasks.filter({ !$0.isCompleted && $0.dueDate != nil && !$0.isDueToday }).isEmpty {
                    EmptyUpcomingView()
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        if !appState.getOverdueTasks().isEmpty {
                            VStack(alignment: .leading) {
                                Text("Overdue")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                TaskListView(tasks: appState.getOverdueTasks())
                            }
                        }
                        
                        let upcomingTasks = appState.tasks.filter { !$0.isCompleted && $0.dueDate != nil && !$0.isDueToday }
                        if !upcomingTasks.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Upcoming")
                                    .font(.headline)
                                TaskListView(tasks: upcomingTasks)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Upcoming")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
    }
}

// MARK: - Categories View
struct CategoriesView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddCategory = false
    
    var body: some View {
        NavigationView {
            VStack {
                if appState.categories.isEmpty {
                    EmptyCategoriesView()
                } else {
                    CategoryGridView(categories: appState.categories)
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCategory = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
            }
        }
    }
}

// MARK: - All Tasks View
struct AllTasksView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddTask = false
    @State private var selectedFilter: TaskFilter = .all
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
    }
    
    var filteredTasks: [TaskItem] {
        switch selectedFilter {
        case .all:
            return appState.tasks
        case .active:
            return appState.tasks.filter { !$0.isCompleted }
        case .completed:
            return appState.getCompletedTasks()
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if filteredTasks.isEmpty {
                    EmptyAllTasksView()
                } else {
                    TaskListView(tasks: filteredTasks)
                }
            }
            .navigationTitle("All Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
    }
}

// MARK: - Stats View
struct StatsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    SummaryCardsView()
                    
                    // Completion Chart
                    CompletionChartView()
                    
                    // Category Breakdown
                    CategoryBreakdownView()
                    
                    // Focus Time Chart
                    FocusTimeChartView()
                    
                    // Insights
                    InsightsView()
                }
                .padding()
            }
            .navigationTitle("Statistics")
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            List {
                Section("Blocking") {
                    BlockingSettingsView()
                }
                
                Section("Notifications") {
                    NotificationSettingsView()
                }
                
                Section("Data") {
                    DataSettingsView()
                }
                
                Section("About") {
                    AboutSettingsView()
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
