import Foundation
import UserNotifications

// MARK: - Task Manager
public class TaskManager: ObservableObject {
    private let dataStore: SimpleDataStore
    private let notificationManager = NotificationManager.shared
    
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
        
        // Schedule notifications
        scheduleNotifications(for: task)
        
        return task
    }
    
    public func updateTask(_ task: TaskItem) {
        if let index = dataStore.tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            updatedTask.updatedAt = Date()
            dataStore.tasks[index] = updatedTask
            dataStore.save()
            
            // Reschedule notifications
            cancelNotifications(for: task)
            scheduleNotifications(for: updatedTask)
        }
    }
    
    public func completeTask(_ task: TaskItem) {
        if let index = dataStore.tasks.firstIndex(where: { $0.id == task.id }) {
            var completedTask = task
            completedTask.isCompleted = true
            completedTask.updatedAt = Date()
            dataStore.tasks[index] = completedTask
            dataStore.save()
            
            // Cancel notifications
            cancelNotifications(for: task)
            
            // Update analytics
            updateDailyAggregate(for: completedTask)
        }
    }
    
    public func deleteTask(_ task: TaskItem) {
        // Cancel notifications
        cancelNotifications(for: task)
        
        dataStore.tasks.removeAll { $0.id == task.id }
        dataStore.save()
    }
    
    // MARK: - Fetch Requests
    
    public func fetchTasks(predicate: ((TaskItem) -> Bool)? = nil, sortDescriptors: [((TaskItem, TaskItem) -> Bool)] = []) -> [TaskItem] {
        var tasks = dataStore.tasks
        
        if let predicate = predicate {
            tasks = tasks.filter(predicate)
        }
        
        if !sortDescriptors.isEmpty {
            tasks.sort { task1, task2 in
                for descriptor in sortDescriptors {
                    if descriptor(task1, task2) { return true }
                    if descriptor(task2, task1) { return false }
                }
                return false
            }
        } else {
            // Default sort by due date
            tasks.sort { task1, task2 in
                guard let date1 = task1.dueDate, let date2 = task2.dueDate else {
                    return task1.dueDate != nil
                }
                return date1 < date2
            }
        }
        
        return tasks
    }
    
    public func fetchTasksDueToday() -> [TaskItem] {
        return fetchTasks { task in
            task.isDueToday
        }
    }
    
    public func fetchOverdueTasks() -> [TaskItem] {
        return fetchTasks { task in
            task.isOverdue
        }
    }
    
    public func fetchActiveTasks() -> [TaskItem] {
        return fetchTasks { task in
            task.isActive
        }
    }
    
    public func fetchTasksByCategory(_ category: Category) -> [TaskItem] {
        return fetchTasks { task in
            task.categoryName == category.name
        }
    }
    
    public func fetchCompletedTasks() -> [TaskItem] {
        return fetchTasks { task in
            task.isCompleted
        }
    }
    
    // MARK: - Category Operations
    
    public func createCategory(name: String, color: String = "blue", icon: String = "folder") -> Category {
        let category = Category(name: name, color: color, icon: icon)
        dataStore.categories.append(category)
        dataStore.save()
        return category
    }
    
    public func fetchCategories() -> [Category] {
        return dataStore.categories.sorted { $0.name < $1.name }
    }
    
    public func updateCategory(_ category: Category) {
        if let index = dataStore.categories.firstIndex(where: { $0.id == category.id }) {
            dataStore.categories[index] = category
            dataStore.save()
        }
    }
    
    public func deleteCategory(_ category: Category) {
        dataStore.categories.removeAll { $0.id == category.id }
        dataStore.save()
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
    
    public func fetchPresets() -> [TaskPreset] {
        return dataStore.presets.sorted { $0.title < $1.title }
    }
    
    public func updatePreset(_ preset: TaskPreset) {
        if let index = dataStore.presets.firstIndex(where: { $0.id == preset.id }) {
            var updatedPreset = preset
            updatedPreset.updatedAt = Date()
            dataStore.presets[index] = updatedPreset
            dataStore.save()
        }
    }
    
    public func deletePreset(_ preset: TaskPreset) {
        dataStore.presets.removeAll { $0.id == preset.id }
        dataStore.save()
    }
    
    // MARK: - Helper Methods
    
    private func saveContext() {
        dataStore.save()
    }
    
    // MARK: - Notification Management
    
    private func scheduleNotifications(for task: TaskItem) {
        guard !task.isCompleted else { return }
        
        // For now, we'll skip reminders since we removed the reminders array
        // This can be implemented later with a separate Reminder entity if needed
    }
    
    private func cancelNotifications(for task: TaskItem) {
        notificationManager.cancelTaskNotifications(taskId: task.id.uuidString)
    }
    
    // MARK: - Analytics
    
    private func updateDailyAggregate(for task: TaskItem) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let index = dataStore.dailyAggregates.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            dataStore.dailyAggregates[index].tasksCompleted += 1
            dataStore.dailyAggregates[index].focusTimeMinutes += task.estimateMinutes
            dataStore.dailyAggregates[index].updatedAt = Date()
        } else {
            let aggregate = DailyAggregate(
                date: today,
                tasksCompleted: 1,
                tasksDue: 0,
                focusTimeMinutes: task.estimateMinutes
            )
            dataStore.dailyAggregates.append(aggregate)
        }
        
        dataStore.save()
    }
    
    // MARK: - Seed Data
    
    public func createDefaultCategories() {
        // Already created in SimpleDataStore.init()
    }
    
    public func createDefaultPresets() {
        // Already created in SimpleDataStore.init()
    }
}