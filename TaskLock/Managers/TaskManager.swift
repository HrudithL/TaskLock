import Foundation
import CoreData
import UserNotifications

// MARK: - Task Manager
public class TaskManager: ObservableObject {
    private let persistenceController: PersistenceController
    private let notificationManager = NotificationManager.shared
    
    public init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
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
    ) -> Task {
        let context = persistenceController.container.viewContext
        let task = Task(context: context)
        
        task.id = UUID()
        task.title = title
        task.notes = notes
        task.dueDate = dueDate
        task.reminders = reminders
        task.category = category
        task.priority = priority
        task.estimateMinutes = estimateMinutes
        task.isCompleted = false
        task.createdAt = Date()
        task.updatedAt = Date()
        
        saveContext()
        
        // Schedule notifications
        scheduleNotifications(for: task)
        
        return task
    }
    
    public func updateTask(_ task: Task) {
        task.updatedAt = Date()
        saveContext()
        
        // Reschedule notifications
        cancelNotifications(for: task)
        scheduleNotifications(for: task)
    }
    
    public func completeTask(_ task: Task) {
        task.isCompleted = true
        task.updatedAt = Date()
        saveContext()
        
        // Cancel notifications
        cancelNotifications(for: task)
        
        // Update analytics
        updateDailyAggregate(for: task)
    }
    
    public func deleteTask(_ task: Task) {
        // Cancel notifications
        cancelNotifications(for: task)
        
        persistenceController.container.viewContext.delete(task)
        saveContext()
    }
    
    // MARK: - Fetch Requests
    
    public func fetchTasks(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors.isEmpty ? [NSSortDescriptor(keyPath: \Task.dueDate, ascending: true)] : sortDescriptors
        
        do {
            return try persistenceController.container.viewContext.fetch(request)
        } catch {
            print("Error fetching tasks: \(error)")
            return []
        }
    }
    
    public func fetchTasksDueToday() -> [Task] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@ AND isCompleted == NO", startOfDay as NSDate, endOfDay as NSDate)
        return fetchTasks(predicate: predicate)
    }
    
    public func fetchOverdueTasks() -> [Task] {
        let predicate = NSPredicate(format: "dueDate < %@ AND isCompleted == NO", Date() as NSDate)
        return fetchTasks(predicate: predicate)
    }
    
    public func fetchActiveTasks() -> [Task] {
        let todayPredicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@ AND isCompleted == NO", 
                                       Calendar.current.startOfDay(for: Date()) as NSDate,
                                       Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))! as NSDate)
        let overduePredicate = NSPredicate(format: "dueDate < %@ AND isCompleted == NO", Date() as NSDate)
        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [todayPredicate, overduePredicate])
        
        return fetchTasks(predicate: compoundPredicate)
    }
    
    public func fetchTasksByCategory(_ category: Category) -> [Task] {
        let predicate = NSPredicate(format: "category == %@", category)
        return fetchTasks(predicate: predicate)
    }
    
    public func fetchCompletedTasks() -> [Task] {
        let predicate = NSPredicate(format: "isCompleted == YES")
        return fetchTasks(predicate: predicate, sortDescriptors: [NSSortDescriptor(keyPath: \Task.updatedAt, ascending: false)])
    }
    
    // MARK: - Category Operations
    
    public func createCategory(name: String, color: String = "blue", icon: String = "folder") -> Category {
        let context = persistenceController.container.viewContext
        let category = Category(context: context)
        
        category.id = UUID()
        category.name = name
        category.color = color
        category.icon = icon
        category.createdAt = Date()
        
        saveContext()
        return category
    }
    
    public func fetchCategories() -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        
        do {
            return try persistenceController.container.viewContext.fetch(request)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    public func updateCategory(_ category: Category) {
        saveContext()
    }
    
    public func deleteCategory(_ category: Category) {
        persistenceController.container.viewContext.delete(category)
        saveContext()
    }
    
    // MARK: - Preset Operations
    
    public func createPreset(
        title: String,
        notes: String? = nil,
        category: String = "Personal",
        priority: TaskPriority = .medium,
        estimateMinutes: Int32 = 30
    ) -> TaskPreset {
        let context = persistenceController.container.viewContext
        let preset = TaskPreset(context: context)
        
        preset.id = UUID()
        preset.title = title
        preset.notes = notes
        preset.category = category
        preset.priority = priority
        preset.estimateMinutes = estimateMinutes
        preset.createdAt = Date()
        preset.updatedAt = Date()
        
        saveContext()
        return preset
    }
    
    public func fetchPresets() -> [TaskPreset] {
        let request: NSFetchRequest<TaskPreset> = TaskPreset.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskPreset.title, ascending: true)]
        
        do {
            return try persistenceController.container.viewContext.fetch(request)
        } catch {
            print("Error fetching presets: \(error)")
            return []
        }
    }
    
    public func updatePreset(_ preset: TaskPreset) {
        preset.updatedAt = Date()
        saveContext()
    }
    
    public func deletePreset(_ preset: TaskPreset) {
        persistenceController.container.viewContext.delete(preset)
        saveContext()
    }
    
    // MARK: - Helper Methods
    
    private func saveContext() {
        persistenceController.saveContext()
    }
    
    // MARK: - Notification Management
    
    private func scheduleNotifications(for task: Task) {
        guard !task.isCompleted else { return }
        
        for reminderDate in task.reminders {
            notificationManager.scheduleTaskReminder(
                taskId: task.id.uuidString,
                title: task.title,
                body: task.notes ?? "Task reminder",
                date: reminderDate
            )
        }
    }
    
    private func cancelNotifications(for task: Task) {
        notificationManager.cancelTaskNotifications(taskId: task.id.uuidString)
    }
    
    // MARK: - Analytics
    
    private func updateDailyAggregate(for task: Task) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let request: NSFetchRequest<DailyAggregate> = DailyAggregate.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", today as NSDate)
        
        do {
            let aggregates = try persistenceController.container.viewContext.fetch(request)
            let aggregate = aggregates.first ?? DailyAggregate(context: persistenceController.container.viewContext)
            
            if aggregate.date == nil {
                aggregate.id = UUID()
                aggregate.date = today
                aggregate.createdAt = Date()
            }
            
            aggregate.tasksCompleted += 1
            aggregate.focusTimeMinutes += task.estimateMinutes
            aggregate.updatedAt = Date()
            
            // Update category breakdown
            var breakdown = aggregate.categoryBreakdown ?? [:]
            let categoryName = task.categoryName
            breakdown[categoryName] = (breakdown[categoryName] ?? 0) + 1
            aggregate.categoryBreakdown = breakdown
            
            saveContext()
        } catch {
            print("Error updating daily aggregate: \(error)")
        }
    }
    
    // MARK: - Seed Data
    
    public func createDefaultCategories() {
        let defaultCategories = [
            ("School", "blue", "graduationcap"),
            ("Work", "green", "briefcase"),
            ("Personal", "purple", "person"),
            ("Health", "red", "heart")
        ]
        
        for (name, color, icon) in defaultCategories {
            if fetchCategories().first(where: { $0.name == name }) == nil {
                createCategory(name: name, color: color, icon: icon)
            }
        }
    }
    
    public func createDefaultPresets() {
        let defaultPresets = [
            ("Homework", "Complete assignment", "School", TaskPriority.medium, 60),
            ("Workout", "Exercise session", "Health", TaskPriority.high, 45),
            ("Deep Work", "Focused work session", "Work", TaskPriority.high, 90),
            ("Read", "Reading time", "Personal", TaskPriority.low, 30)
        ]
        
        for (title, notes, category, priority, minutes) in defaultPresets {
            if fetchPresets().first(where: { $0.title == title }) == nil {
                createPreset(title: title, notes: notes, category: category, priority: priority, estimateMinutes: Int32(minutes))
            }
        }
    }
}
