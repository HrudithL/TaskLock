import SwiftUI

// MARK: - Simplified Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            TasksView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Tasks")
                }
                .tag(0)
            
            CategoriesView()
                .tabItem {
                    Image(systemName: "folder")
                    Text("Categories")
                }
                .tag(1)
            
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Stats")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
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

// MARK: - Simple Tasks View
struct TasksView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            VStack {
                if appState.tasks.isEmpty {
                    EmptyTasksView()
                } else {
                    List {
                        ForEach(appState.tasks, id: \.id) { task in
                            TaskRowView(task: task)
                        }
                        .onDelete(perform: deleteTasks)
                    }
                }
            }
            .navigationTitle("Tasks")
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
    
    private func deleteTasks(offsets: IndexSet) {
        for index in offsets {
            let task = appState.tasks[index]
            appState.deleteTask(task)
        }
    }
}

// MARK: - Simple Task Row View
struct TaskRowView: View {
    let task: TaskItem
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            Button(action: {
                appState.completeTask(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption2)
                            .foregroundColor(task.isOverdue ? .red : .secondary)
                    }
                    
                    Spacer()
                    
                    Text(task.priority.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
    }
}

// MARK: - Simple Categories View
struct CategoriesView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddCategory = false
    
    var body: some View {
        NavigationView {
            VStack {
                if appState.categories.isEmpty {
                    EmptyCategoriesView()
                } else {
                    List {
                        ForEach(appState.categories, id: \.id) { category in
                            CategoryRowView(category: category)
                        }
                        .onDelete(perform: deleteCategories)
                    }
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
    
    private func deleteCategories(offsets: IndexSet) {
        for index in offsets {
            let category = appState.categories[index]
            appState.deleteCategory(category)
        }
    }
}

// MARK: - Simple Category Row View
struct CategoryRowView: View {
    let category: Category
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(.blue)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(category.name)
                    .font(.headline)
                
                Text("Created: \(category.createdAt, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Simple Stats View
struct StatsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    VStack(spacing: 16) {
                        StatCard(title: "Total Tasks", value: "\(appState.tasks.count)", color: .blue)
                        StatCard(title: "Completed", value: "\(appState.getCompletedTasks().count)", color: .green)
                        StatCard(title: "Active", value: "\(appState.getActiveTasks().count)", color: .orange)
                        StatCard(title: "Categories", value: "\(appState.categories.count)", color: .purple)
                    }
                    .padding()
                }
            }
            .navigationTitle("Statistics")
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(value)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Simple Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            List {
                Section("Blocking") {
                    HStack {
                        Text("Task-Conditional Blocking")
                        Spacer()
                        Toggle("", isOn: .constant(false))
                    }
                }
                
                Section("Data") {
                    Button("Reset All Data") {
                        // Reset data
                    }
                    .foregroundColor(.red)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Empty State Views
struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Tasks Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the + button to add your first task")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct EmptyCategoriesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Categories Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the + button to add your first category")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Views are defined in separate files
// AddTaskView is defined in AddEditTaskViews.swift
// AddCategoryView is defined in CategoryViews.swift  
// BlockingOverlay is defined in BlockingOverlay.swift

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
