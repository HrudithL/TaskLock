import SwiftUI

// MARK: - Task List View
struct TaskListView: View {
    let tasks: [TaskItem]
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List {
            ForEach(tasks, id: \.id) { task in
                TaskRowView(task: task)
            }
            .onDelete(perform: deleteTasks)
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        for index in offsets {
            let task = tasks[index]
            appState.deleteTask(task)
        }
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    let task: TaskItem
    @EnvironmentObject var appState: AppState
    @State private var showingEditTask = false
    
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
                        .lineLimit(2)
                }
                
                HStack {
                    if let dueDate = task.dueDate {
                        Label(formatDate(dueDate), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(task.isOverdue ? .red : .secondary)
                    }
                    
                    Spacer()
                    
                    Label(task.categoryName ?? "Uncategorized", systemImage: "folder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    PriorityBadge(priority: task.priority)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditTask = true
        }
        .sheet(isPresented: $showingEditTask) {
            EditTaskView(task: task)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Priority Badge
struct PriorityBadge: View {
    let priority: TaskPriority
    
    var body: some View {
        Text(priority.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(priority.color).opacity(0.2))
            .foregroundColor(Color(priority.color))
            .cornerRadius(4)
    }
}

// MARK: - Empty State Views
struct EmptyTodayView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("No tasks due today!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("You're all caught up. Great job!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct EmptyUpcomingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("No upcoming tasks")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add some tasks to stay organized")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct EmptyCategoriesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("No categories yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create categories to organize your tasks")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct EmptyAllTasksView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("No tasks yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first task to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    TaskListView(tasks: [])
        .environmentObject(AppState())
}
