import Foundation
import CoreData
import Charts
import TasksKit

// MARK: - Analytics Data Models
public struct TaskCompletionData {
    public let date: Date
    public let tasksCompleted: Int
    public let tasksDue: Int
    public let onTimePercentage: Double
    public let averageLateness: TimeInterval
    
    public init(date: Date, tasksCompleted: Int, tasksDue: Int, onTimePercentage: Double, averageLateness: TimeInterval) {
        self.date = date
        self.tasksCompleted = tasksCompleted
        self.tasksDue = tasksDue
        self.onTimePercentage = onTimePercentage
        self.averageLateness = averageLateness
    }
}

public struct CategoryBreakdown {
    public let category: String
    public let completedTasks: Int
    public let totalTasks: Int
    public let percentage: Double
    
    public init(category: String, completedTasks: Int, totalTasks: Int, percentage: Double) {
        self.category = category
        self.completedTasks = completedTasks
        self.totalTasks = totalTasks
        self.percentage = percentage
    }
}

public struct FocusTimeData {
    public let date: Date
    public let focusTimeMinutes: Int
    public let tasksCompleted: Int
    
    public init(date: Date, focusTimeMinutes: Int, tasksCompleted: Int) {
        self.date = date
        self.focusTimeMinutes = focusTimeMinutes
        self.tasksCompleted = tasksCompleted
    }
}

// MARK: - Chart Data Models
public struct HeatmapDataPoint: Identifiable {
    public let id = UUID()
    public let week: Int
    public let day: Int
    public let tasksCompleted: Int
    public let date: Date
    
    public init(week: Int, day: Int, tasksCompleted: Int, date: Date) {
        self.week = week
        self.day = day
        self.tasksCompleted = tasksCompleted
        self.date = date
    }
}

public struct CompletionChartDataPoint: Identifiable {
    public let id = UUID()
    public let date: Date
    public let completed: Int
    public let due: Int
    public let onTimePercentage: Double
    
    public init(date: Date, completed: Int, due: Int, onTimePercentage: Double) {
        self.date = date
        self.completed = completed
        self.due = due
        self.onTimePercentage = onTimePercentage
    }
}

// MARK: - Analytics Manager
public class AnalyticsManager: ObservableObject {
    private let persistenceController: PersistenceController
    private let taskManager: TaskManager
    
    @Published public var taskCompletionData: [TaskCompletionData] = []
    @Published public var categoryBreakdown: [CategoryBreakdown] = []
    @Published public var focusTimeData: [FocusTimeData] = []
    @Published public var heatmapData: [HeatmapDataPoint] = []
    @Published public var completionChartData: [CompletionChartDataPoint] = []
    
    public init(persistenceController: PersistenceController, taskManager: TaskManager) {
        self.persistenceController = persistenceController
        self.taskManager = taskManager
    }
    
    // MARK: - Data Aggregation
    
    public func updateAnalytics() {
        Task {
            await loadTaskCompletionData()
            await loadCategoryBreakdown()
            await loadFocusTimeData()
            await generateHeatmapData()
            await generateCompletionChartData()
        }
    }
    
    private func loadTaskCompletionData() async {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        
        var data: [TaskCompletionData] = []
        
        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
            
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let tasksDue = taskManager.fetchTasks(predicate: NSPredicate(format: "dueDate >= %@ AND dueDate < %@", dayStart as NSDate, dayEnd as NSDate))
            let tasksCompleted = tasksDue.filter { $0.isCompleted }
            
            let onTimeTasks = tasksCompleted.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return task.updatedAt <= dueDate
            }
            
            let onTimePercentage = tasksDue.isEmpty ? 0.0 : Double(onTimeTasks.count) / Double(tasksDue.count) * 100.0
            
            let lateTasks = tasksCompleted.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return task.updatedAt > dueDate
            }
            
            let averageLateness = lateTasks.isEmpty ? 0 : lateTasks.reduce(0) { sum, task in
                guard let dueDate = task.dueDate else { return sum }
                return sum + task.updatedAt.timeIntervalSince(dueDate)
            } / Double(lateTasks.count)
            
            let completionData = TaskCompletionData(
                date: date,
                tasksCompleted: tasksCompleted.count,
                tasksDue: tasksDue.count,
                onTimePercentage: onTimePercentage,
                averageLateness: averageLateness
            )
            
            data.append(completionData)
        }
        
        await MainActor.run {
            self.taskCompletionData = data
        }
    }
    
    private func loadCategoryBreakdown() async {
        let categories = taskManager.fetchCategories()
        var breakdown: [CategoryBreakdown] = []
        
        for category in categories {
            let tasks = taskManager.fetchTasksByCategory(category.name)
            let completedTasks = tasks.filter { $0.isCompleted }.count
            let totalTasks = tasks.count
            let percentage = totalTasks == 0 ? 0.0 : Double(completedTasks) / Double(totalTasks) * 100.0
            
            let categoryData = CategoryBreakdown(
                category: category.name,
                completedTasks: completedTasks,
                totalTasks: totalTasks,
                percentage: percentage
            )
            
            breakdown.append(categoryData)
        }
        
        await MainActor.run {
            self.categoryBreakdown = breakdown
        }
    }
    
    private func loadFocusTimeData() async {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        
        var data: [FocusTimeData] = []
        
        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
            
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let tasksCompleted = taskManager.fetchTasks(predicate: NSPredicate(format: "updatedAt >= %@ AND updatedAt < %@ AND isCompleted == YES", dayStart as NSDate, dayEnd as NSDate))
            
            let totalFocusTime = tasksCompleted.reduce(0) { sum, task in
                return sum + Int(task.estimateMinutes)
            }
            
            let focusData = FocusTimeData(
                date: date,
                focusTimeMinutes: totalFocusTime,
                tasksCompleted: tasksCompleted.count
            )
            
            data.append(focusData)
        }
        
        await MainActor.run {
            self.focusTimeData = data
        }
    }
    
    private func generateHeatmapData() async {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -84, to: endDate)! // 12 weeks
        
        var data: [HeatmapDataPoint] = []
        
        for i in 0..<84 {
            guard let date = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
            
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let tasksCompleted = taskManager.fetchTasks(predicate: NSPredicate(format: "updatedAt >= %@ AND updatedAt < %@ AND isCompleted == YES", dayStart as NSDate, dayEnd as NSDate))
            
            let week = i / 7
            let day = i % 7
            
            let heatmapPoint = HeatmapDataPoint(
                week: week,
                day: day,
                tasksCompleted: tasksCompleted.count,
                date: date
            )
            
            data.append(heatmapPoint)
        }
        
        await MainActor.run {
            self.heatmapData = data
        }
    }
    
    private func generateCompletionChartData() async {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        
        var data: [CompletionChartDataPoint] = []
        
        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
            
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let tasksDue = taskManager.fetchTasks(predicate: NSPredicate(format: "dueDate >= %@ AND dueDate < %@", dayStart as NSDate, dayEnd as NSDate))
            let tasksCompleted = tasksDue.filter { $0.isCompleted }
            
            let onTimeTasks = tasksCompleted.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return task.updatedAt <= dueDate
            }
            
            let onTimePercentage = tasksDue.isEmpty ? 0.0 : Double(onTimeTasks.count) / Double(tasksDue.count) * 100.0
            
            let chartPoint = CompletionChartDataPoint(
                date: date,
                completed: tasksCompleted.count,
                due: tasksDue.count,
                onTimePercentage: onTimePercentage
            )
            
            data.append(chartPoint)
        }
        
        await MainActor.run {
            self.completionChartData = data
        }
    }
    
    // MARK: - Statistics Calculation
    
    public func getTotalFocusTimeSaved() -> Int {
        return focusTimeData.reduce(0) { sum, data in
            return sum + data.focusTimeMinutes
        }
    }
    
    public func getAverageTasksPerDay() -> Double {
        guard !taskCompletionData.isEmpty else { return 0.0 }
        let totalTasks = taskCompletionData.reduce(0) { sum, data in
            return sum + data.tasksCompleted
        }
        return Double(totalTasks) / Double(taskCompletionData.count)
    }
    
    public func getOnTimeCompletionRate() -> Double {
        guard !taskCompletionData.isEmpty else { return 0.0 }
        let totalOnTime = taskCompletionData.reduce(0.0) { sum, data in
            return sum + data.onTimePercentage
        }
        return totalOnTime / Double(taskCompletionData.count)
    }
    
    public func getStreakDays() -> Int {
        var streak = 0
        let calendar = Calendar.current
        
        for data in taskCompletionData.reversed() {
            if data.tasksCompleted > 0 {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - CSV Export
    
    public func exportTasksToCSV() -> String {
        let tasks = taskManager.fetchTasks()
        var csv = "Title,Notes,Due Date,Category,Priority,Estimate Minutes,Completed,Created At,Updated At\n"
        
        for task in tasks {
            let title = escapeCSVField(task.title)
            let notes = escapeCSVField(task.notes ?? "")
            let dueDate = task.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? ""
            let category = escapeCSVField(task.category)
            let priority = task.priority.displayName
            let estimateMinutes = String(task.estimateMinutes)
            let completed = task.isCompleted ? "Yes" : "No"
            let createdAt = task.createdAt.formatted(date: .abbreviated, time: .shortened)
            let updatedAt = task.updatedAt.formatted(date: .abbreviated, time: .shortened)
            
            csv += "\(title),\(notes),\(dueDate),\(category),\(priority),\(estimateMinutes),\(completed),\(createdAt),\(updatedAt)\n"
        }
        
        return csv
    }
    
    public func exportCompletionsToCSV() -> String {
        var csv = "Date,Tasks Completed,Tasks Due,On Time Percentage,Average Lateness\n"
        
        for data in taskCompletionData {
            let date = data.date.formatted(date: .abbreviated, time: .omitted)
            let completed = String(data.tasksCompleted)
            let due = String(data.tasksDue)
            let onTimePercentage = String(format: "%.1f", data.onTimePercentage)
            let averageLateness = String(format: "%.0f", data.averageLateness)
            
            csv += "\(date),\(completed),\(due),\(onTimePercentage),\(averageLateness)\n"
        }
        
        return csv
    }
    
    public func exportDailyAggregatesToCSV() -> String {
        var csv = "Date,Tasks Completed,Focus Time Minutes\n"
        
        for data in focusTimeData {
            let date = data.date.formatted(date: .abbreviated, time: .omitted)
            let completed = String(data.tasksCompleted)
            let focusTime = String(data.focusTimeMinutes)
            
            csv += "\(date),\(completed),\(focusTime)\n"
        }
        
        return csv
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
    
    // MARK: - Daily Aggregate Management
    
    public func createDailyAggregate(for date: Date) -> DailyAggregate {
        let context = persistenceController.container.viewContext
        let aggregate = DailyAggregate(context: context)
        
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        let tasksDue = taskManager.fetchTasks(predicate: NSPredicate(format: "dueDate >= %@ AND dueDate < %@", dayStart as NSDate, dayEnd as NSDate))
        let tasksCompleted = tasksDue.filter { $0.isCompleted }
        
        var categoryBreakdown: [String: Int32] = [:]
        for task in tasksCompleted {
            categoryBreakdown[task.category, default: 0] += 1
        }
        
        let totalFocusTime = tasksCompleted.reduce(0) { sum, task in
            return sum + Int(task.estimateMinutes)
        }
        
        aggregate.id = UUID()
        aggregate.date = date
        aggregate.tasksCompleted = Int32(tasksCompleted.count)
        aggregate.tasksDue = Int32(tasksDue.count)
        aggregate.focusTimeMinutes = Int32(totalFocusTime)
        aggregate.categoryBreakdown = categoryBreakdown
        aggregate.createdAt = Date()
        aggregate.updatedAt = Date()
        
        do {
            try context.save()
        } catch {
            print("Error saving daily aggregate: \(error)")
        }
        
        return aggregate
    }
}
