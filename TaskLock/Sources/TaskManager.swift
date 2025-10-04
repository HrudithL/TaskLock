import Foundation
import CoreData
import UserNotifications

// MARK: - Task Manager
public class TaskManager: ObservableObject {
    private let persistenceController: PersistenceController
    private let notificationCenter = UNUserNotificationCenter.current()
    
    public init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - Task CRUD Operations
    
    public func createTask(
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        reminders: [Date] = [],
        category: String = "Personal",
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
        scheduleReminders(for: task)
        
        return task
    }
    
    public func updateTask(_ task: Task) {
        task.updatedAt = Date()
        saveContext()
        scheduleReminders(for: task)
    }
    
    public func completeTask(_ task: Task) {
        task.isCompleted = true
        task.updatedAt = Date()
        saveContext()
        cancelReminders(for: task)
    }
    
    public func deleteTask(_ task: Task) {
        cancelReminders(for: task)
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
    
    public func fetchTasksByCategory(_ category: String) -> [Task] {
        let predicate = NSPredicate(format: "category == %@", category)
        return fetchTasks(predicate: predicate)
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
    
    public func deletePreset(_ preset: TaskPreset) {
        persistenceController.container.viewContext.delete(preset)
        saveContext()
    }
    
    // MARK: - Reminder Management
    
    private func scheduleReminders(for task: Task) {
        cancelReminders(for: task)
        
        for (index, reminderDate) in task.reminders.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Task Reminder"
            content.body = task.title
            content.sound = .default
            content.userInfo = ["taskId": task.id.uuidString]
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate),
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "\(task.id.uuidString)-\(index)",
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Error scheduling reminder: \(error)")
                }
            }
        }
    }
    
    private func cancelReminders(for task: Task) {
        let identifiers = task.reminders.enumerated().map { "\(task.id.uuidString)-\($0.offset)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // MARK: - Helper Methods
    
    private func saveContext() {
        let context = persistenceController.container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
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
            ("Homework", "Complete assignment", "School", TaskPriority.medium, 30),
            ("Workout", "Exercise session", "Health", TaskPriority.high, 45),
            ("Deep Work", "Focused work session", "Work", TaskPriority.high, 90)
        ]
        
        for (title, notes, category, priority, minutes) in defaultPresets {
            if fetchPresets().first(where: { $0.title == title }) == nil {
                createPreset(title: title, notes: notes, category: category, priority: priority, estimateMinutes: Int32(minutes))
            }
        }
    }
}
