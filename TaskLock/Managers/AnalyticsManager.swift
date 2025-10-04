import Foundation
import SwiftUI

// MARK: - Stub AnalyticsManager
public class AnalyticsManager: ObservableObject {
    private let dataStore: SimpleDataStore
    private let taskManager: TaskManager
    
    public init(dataStore: SimpleDataStore, taskManager: TaskManager) {
        self.dataStore = dataStore
        self.taskManager = taskManager
    }
    
    public func updateAnalytics() {
        // Stub implementation
    }
    
    public func getCompletionRate() -> Double {
        let completedTasks = taskManager.fetchCompletedTasks().count
        let totalTasks = taskManager.fetchTasks().count
        return totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
    }
    
    public func getTasksCompletedToday() -> Int {
        return taskManager.fetchCompletedTasks().filter { task in
            Calendar.current.isDateInToday(task.updatedAt)
        }.count
    }
}