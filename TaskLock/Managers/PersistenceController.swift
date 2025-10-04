import Foundation
import SwiftUI

// MARK: - Simple Data Store
public class SimpleDataStore: ObservableObject {
    @Published public var tasks: [Task] = []
    @Published public var categories: [Category] = []
    @Published public var presets: [TaskPreset] = []
    @Published public var dailyAggregates: [DailyAggregate] = []
    
    public init() {
        loadDefaultData()
    }
    
    private func loadDefaultData() {
        // Create default categories
        categories = [
            Category(name: "School", color: "blue", icon: "graduationcap"),
            Category(name: "Work", color: "green", icon: "briefcase"),
            Category(name: "Personal", color: "purple", icon: "person"),
            Category(name: "Health", color: "red", icon: "heart")
        ]
        
        // Create default presets
        presets = [
            TaskPreset(title: "Homework", notes: "Complete assignment", category: "School", priority: .medium, estimateMinutes: 60),
            TaskPreset(title: "Workout", notes: "Exercise session", category: "Health", priority: .high, estimateMinutes: 45),
            TaskPreset(title: "Deep Work", notes: "Focused work session", category: "Work", priority: .high, estimateMinutes: 90),
            TaskPreset(title: "Read", notes: "Reading time", category: "Personal", priority: .low, estimateMinutes: 30)
        ]
        
        // Create some sample tasks
        tasks = [
            Task(title: "Complete project proposal", notes: "Finish the quarterly project proposal", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), priority: .high, estimateMinutes: 120, categoryName: "Work"),
            Task(title: "Grocery shopping", notes: "Buy ingredients for dinner", dueDate: Date(), priority: .medium, estimateMinutes: 30, categoryName: "Personal"),
            Task(title: "Study for exam", notes: "Review chapters 5-8", dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()), priority: .high, estimateMinutes: 180, categoryName: "School")
        ]
    }
    
    public func save() {
        // In a real app, this would save to UserDefaults or a file
        // For now, we'll just keep everything in memory
    }
}

// MARK: - Persistence Controller (Simplified)
public class PersistenceController {
    public static let shared = PersistenceController()
    
    public static var preview: PersistenceController = {
        let result = PersistenceController()
        return result
    }()
    
    public let dataStore: SimpleDataStore
    
    public init() {
        self.dataStore = SimpleDataStore()
    }
    
    public func save() {
        dataStore.save()
    }
    
    public func saveContext() {
        save()
    }
}