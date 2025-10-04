import Foundation
import SwiftUI

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
public struct Task: Identifiable, Hashable {
    public let id: UUID
    public var title: String
    public var notes: String?
    public var dueDate: Date?
    public var priority: TaskPriority
    public var estimateMinutes: Int32
    public var isCompleted: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var categoryName: String?
    
    public init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        priority: TaskPriority = .medium,
        estimateMinutes: Int32 = 30,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        categoryName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.priority = priority
        self.estimateMinutes = estimateMinutes
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.categoryName = categoryName
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
public struct Category: Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var color: String
    public var icon: String
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        color: String = "blue",
        icon: String = "folder",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.createdAt = createdAt
    }
}

// MARK: - Task Preset Model
public struct TaskPreset: Identifiable, Hashable {
    public let id: UUID
    public var title: String
    public var notes: String?
    public var category: String
    public var priority: TaskPriority
    public var estimateMinutes: Int32
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        category: String = "Personal",
        priority: TaskPriority = .medium,
        estimateMinutes: Int32 = 30,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.category = category
        self.priority = priority
        self.estimateMinutes = estimateMinutes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Daily Aggregate Model
public struct DailyAggregate: Identifiable, Hashable {
    public let id: UUID
    public var date: Date
    public var tasksCompleted: Int32
    public var tasksDue: Int32
    public var focusTimeMinutes: Int32
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        date: Date,
        tasksCompleted: Int32 = 0,
        tasksDue: Int32 = 0,
        focusTimeMinutes: Int32 = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.tasksCompleted = tasksCompleted
        self.tasksDue = tasksDue
        self.focusTimeMinutes = focusTimeMinutes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public var completionRate: Double {
        guard tasksDue > 0 else { return 0.0 }
        return Double(tasksCompleted) / Double(tasksDue)
    }
}