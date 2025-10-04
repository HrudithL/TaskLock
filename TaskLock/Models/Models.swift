import Foundation
import CoreData

// MARK: - Task Priority Enum
public enum TaskPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    public var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

// MARK: - Task Model
@objc(Task)
public class Task: NSManagedObject {
    
}

extension Task {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var notes: String?
    @NSManaged public var dueDate: Date?
    @NSManaged public var priorityRawValue: String
    @NSManaged public var estimateMinutes: Int32
    @NSManaged public var isCompleted: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var categoryName: String?
    
    public var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRawValue) ?? .medium }
        set { priorityRawValue = newValue.rawValue }
    }
    
    public var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }
    
    public var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    
    public var isActive: Bool {
        return !isCompleted && (isDueToday || isOverdue)
    }
    
    public var categoryDisplayName: String {
        return categoryName ?? "Uncategorized"
    }
}

// MARK: - Category Model
@objc(Category)
public class Category: NSManagedObject {
    
}

extension Category {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var color: String
    @NSManaged public var icon: String
    @NSManaged public var createdAt: Date
}

// MARK: - Task Preset Model
@objc(TaskPreset)
public class TaskPreset: NSManagedObject {
    
}

extension TaskPreset {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskPreset> {
        return NSFetchRequest<TaskPreset>(entityName: "TaskPreset")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var notes: String?
    @NSManaged public var category: String
    @NSManaged public var priorityRawValue: String
    @NSManaged public var estimateMinutes: Int32
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    public var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRawValue) ?? .medium }
        set { priorityRawValue = newValue.rawValue }
    }
}

// MARK: - Daily Aggregate Model
@objc(DailyAggregate)
public class DailyAggregate: NSManagedObject {
    
}

extension DailyAggregate {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyAggregate> {
        return NSFetchRequest<DailyAggregate>(entityName: "DailyAggregate")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var tasksCompleted: Int32
    @NSManaged public var tasksDue: Int32
    @NSManaged public var focusTimeMinutes: Int32
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    public var completionRate: Double {
        guard tasksDue > 0 else { return 0.0 }
        return Double(tasksCompleted) / Double(tasksDue)
    }
}
