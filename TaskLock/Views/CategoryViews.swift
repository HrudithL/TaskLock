import SwiftUI

// MARK: - Category Grid View
struct CategoryGridView: View {
    let categories: [Category]
    @EnvironmentObject var appState: AppState
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(categories, id: \.id) { category in
                    CategoryCardView(category: category)
                }
            }
            .padding()
        }
    }
}

// MARK: - Category Card View
struct CategoryCardView: View {
    let category: Category
    @EnvironmentObject var appState: AppState
    @State private var showingCategoryTasks = false
    
    var body: some View {
        Button(action: {
            showingCategoryTasks = true
        }) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 30))
                    .foregroundColor(Color(category.color))
                
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(appState.taskManager.fetchTasksByCategory(category).count) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                let taskCount = appState.taskManager.fetchTasksByCategory(category).count
                let completedCount = appState.taskManager.fetchTasksByCategory(category).filter { $0.isCompleted }.count
                
                if taskCount > 0 {
                    ProgressView(value: Double(completedCount), total: Double(taskCount))
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(category.color)))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(category.color).opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(category.color).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingCategoryTasks) {
            CategoryTasksView(category: category)
        }
    }
}

// MARK: - Category Tasks View
struct CategoryTasksView: View {
    let category: Category
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddTask = false
    
    var categoryTasks: [Task] {
        appState.getTasksByCategory(category)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if categoryTasks.isEmpty {
                    EmptyCategoryTasksView(category: category)
                } else {
                    TaskListView(tasks: categoryTasks)
                }
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
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

// MARK: - Add Category View
struct AddCategoryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedColor = "blue"
    @State private var selectedIcon = "folder"
    
    let colors = ["blue", "green", "orange", "red", "purple", "pink", "yellow", "gray"]
    let icons = ["folder", "person", "briefcase", "graduationcap", "heart", "house", "car", "gamecontroller"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category Details") {
                    TextField("Category name", text: $name)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(Color(color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? Color(selectedColor) : .secondary)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(selectedIcon == icon ? Color(selectedColor).opacity(0.2) : Color.clear)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveCategory() {
        appState.createCategory(name: name, color: selectedColor, icon: selectedIcon)
        dismiss()
    }
}

// MARK: - Empty Category Tasks View
struct EmptyCategoryTasksView: View {
    let category: Category
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: category.icon)
                .font(.system(size: 60))
                .foregroundColor(Color(category.color))
            
            Text("No tasks in \(category.name)")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first task to this category")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    CategoryGridView(categories: [])
        .environmentObject(AppState())
}
