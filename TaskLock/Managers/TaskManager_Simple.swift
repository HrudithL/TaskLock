import Foundation
import SwiftUI

// MARK: - Simplified TaskManager (No UserNotifications dependency)
public class TaskManager: ObservableObject {
    private let dataStore: SimpleDataStore
    
    public init(dataStore: SimpleDataStore) {
        self.dataStore = dataStore
    }
    
    // MARK: - Task CRUD Operations
    
    public func createTask(
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        reminders: [Date] = [],
        category: Category? = nil,
        priority: TaskPriority = .medium,
        estimateMinutes: Int32 = 30
    ) -> TaskItem {
        let task = TaskItem(
            title: title,
            notes: notes,
            dueDate: dueDate,
            priority: priority,
            estimateMinutes: estimateMinutes,
            categoryName: category?.name
        )
        
        dataStore.tasks.append(task)
        dataStore.save()
        
        return task
    }
    
    public func updateTask(_ task: TaskItem) {
        if let index = dataStore.tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            updatedTask.updatedAt = Date()
            dataStore.tasks[index] = updatedTask
            dataStore.save()
        }
    }
    
    public func completeTask(_ task: TaskItem) {
        if let index = dataStore.tasks.firstIndex(where: { $0.id == task.id }) {
            var completedTask = task
            completedTask.isCompleted = true
            completedTask.updatedAt = Date()
            dataStore.tasks[index] = completedTask
            dataStore.save()
        }
    }
    
    public func deleteTask(_ task: TaskItem) {
        dataStore.tasks.removeAll { $0.id == task.id }
        dataStore.save()
    }
    
    // MARK: - Fetch Operations
    
    public func fetchTasks() -> [TaskItem] {
        return dataStore.tasks
    }
    
    public func fetchTasksDueToday() -> [TaskItem] {
        return dataStore.tasks.filter { $0.isDueToday && !$0.isCompleted }
    }
    
    public func fetchOverdueTasks() -> [TaskItem] {
        return dataStore.tasks.filter { $0.isOverdue }
    }
    
    public func fetchActiveTasks() -> [TaskItem] {
        return dataStore.tasks.filter { $0.isActive }
    }
    
    public func fetchTasksByCategory(_ category: Category) -> [TaskItem] {
        return dataStore.tasks.filter { $0.categoryName == category.name }
    }
    
    public func fetchCompletedTasks() -> [TaskItem] {
        return dataStore.tasks.filter { $0.isCompleted }
    }
    
    // MARK: - Category Operations
    
    public func createCategory(name: String, color: String = "blue", icon: String = "folder") -> Category {
        let category = Category(name: name, color: color, icon: icon)
        dataStore.categories.append(category)
        dataStore.save()
        return category
    }
    
    public func deleteCategory(_ category: Category) {
        dataStore.categories.removeAll { $0.id == category.id }
        dataStore.save()
    }
    
    public func fetchCategories() -> [Category] {
        return dataStore.categories
    }
    
    // MARK: - Preset Operations
    
    public func createPreset(
        title: String,
        notes: String? = nil,
        category: String = "Personal",
        priority: TaskPriority = .medium,
        estimateMinutes: Int32 = 30
    ) -> TaskPreset {
        let preset = TaskPreset(
            title: title,
            notes: notes,
            category: category,
            priority: priority,
            estimateMinutes: estimateMinutes
        )
        dataStore.presets.append(preset)
        dataStore.save()
        return preset
    }
    
    public func deletePreset(_ preset: TaskPreset) {
        dataStore.presets.removeAll { $0.id == preset.id }
        dataStore.save()
    }
    
    public func fetchPresets() -> [TaskPreset] {
        return dataStore.presets
    }
    
    // MARK: - Default Data
    
    public func createDefaultCategories() {
        if dataStore.categories.isEmpty {
            _ = createCategory(name: "School", color: "blue", icon: "graduationcap")
            _ = createCategory(name: "Work", color: "green", icon: "briefcase")
            _ = createCategory(name: "Personal", color: "purple", icon: "person")
            _ = createCategory(name: "Health", color: "red", icon: "heart")
        }
    }
    
    public func createDefaultPresets() {
        if dataStore.presets.isEmpty {
            _ = createPreset(title: "Homework", notes: "Complete assignment", category: "School", priority: .medium, estimateMinutes: 60)
            _ = createPreset(title: "Workout", notes: "Exercise session", category: "Health", priority: .high, estimateMinutes: 45)
            _ = createPreset(title: "Deep Work", notes: "Focused work session", category: "Work", priority: .high, estimateMinutes: 90)
            _ = createPreset(title: "Read", notes: "Reading time", category: "Personal", priority: .low, estimateMinutes: 30)
        }
    }
}
