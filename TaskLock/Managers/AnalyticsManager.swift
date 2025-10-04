import Foundation
import CoreData
import Charts

// MARK: - Analytics Data Models
public struct CompletionData: Identifiable {
    public let id = UUID()
    public let date: Date
    public let tasksCompleted: Int
    public let tasksDue: Int
    public let completionRate: Double
}

public struct CategoryBreakdown: Identifiable {
    public let id = UUID()
    public let category: String
    public let count: Int
    public let color: String
}

public struct FocusTimeData: Identifiable {
    public let id = UUID()
    public let date: Date
    public let minutes: Int
}

// MARK: - Analytics Manager
public class AnalyticsManager: ObservableObject {
    private let persistenceController: PersistenceController
    private let taskManager: TaskManager
    
    @Published public var completionData: [CompletionData] = []
    @Published public var categoryBreakdown: [CategoryBreakdown] = []
    @Published public var focusTimeData: [FocusTimeData] = []
    @Published public var totalFocusTimeSaved: Int = 0
    @Published public var averageTasksPerDay: Double = 0.0
    @Published public var onTimeCompletionRate: Double = 0.0
    @Published public var streakDays: Int = 0
    
    public init(persistenceController: PersistenceController, taskManager: TaskManager) {
        self.persistenceController = persistenceController
        self.taskManager = taskManager
        updateAnalytics()
    }
    
    // MARK: - Analytics Updates
    
    public func updateAnalytics() {
        updateCompletionData()
        updateCategoryBreakdown()
        updateFocusTimeData()
        updateSummaryStats()
    }
    
    private func updateCompletionData() {
        let request: NSFetchRequest<DailyAggregate> = DailyAggregate.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyAggregate.date, ascending: true)]
        
        do {
            let aggregates = try persistenceController.container.viewContext.fetch(request)
            completionData = aggregates.map { aggregate in
                CompletionData(
                    date: aggregate.date,
                    tasksCompleted: Int(aggregate.tasksCompleted),
                    tasksDue: Int(aggregate.tasksDue),
                    completionRate: aggregate.completionRate
                )
            }
        } catch {
            print("Error fetching completion data: \(error)")
            completionData = []
        }
    }
    
    private func updateCategoryBreakdown() {
        let categories = taskManager.fetchCategories()
        var breakdown: [String: Int] = [:]
        
        for category in categories {
            let tasks = taskManager.fetchTasksByCategory(category)
            breakdown[category.name] = tasks.count
        }
        
        categoryBreakdown = breakdown.map { (category, count) in
            let categoryObj = categories.first { $0.name == category }
            return CategoryBreakdown(
                category: category,
                count: count,
                color: categoryObj?.color ?? "gray"
            )
        }.sorted { $0.count > $1.count }
    }
    
    private func updateFocusTimeData() {
        let request: NSFetchRequest<DailyAggregate> = DailyAggregate.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyAggregate.date, ascending: true)]
        
        do {
            let aggregates = try persistenceController.container.viewContext.fetch(request)
            focusTimeData = aggregates.map { aggregate in
                FocusTimeData(
                    date: aggregate.date,
                    minutes: Int(aggregate.focusTimeMinutes)
                )
            }
        } catch {
            print("Error fetching focus time data: \(error)")
            focusTimeData = []
        }
    }
    
    private func updateSummaryStats() {
        // Total focus time saved
        totalFocusTimeSaved = focusTimeData.reduce(0) { $0 + $1.minutes }
        
        // Average tasks per day
        let totalDays = max(completionData.count, 1)
        let totalTasks = completionData.reduce(0) { $0 + $1.tasksCompleted }
        averageTasksPerDay = Double(totalTasks) / Double(totalDays)
        
        // On-time completion rate
        let totalDue = completionData.reduce(0) { $0 + $1.tasksDue }
        let totalCompleted = completionData.reduce(0) { $0 + $1.tasksCompleted }
        onTimeCompletionRate = totalDue > 0 ? Double(totalCompleted) / Double(totalDue) : 0.0
        
        // Streak days
        streakDays = calculateStreakDays()
    }
    
    private func calculateStreakDays() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        
        for i in 0..<30 { // Check last 30 days
            let checkDate = calendar.date(byAdding: .day, value: -i, to: today)!
            let dayData = completionData.first { calendar.isDate($0.date, inSameDayAs: checkDate) }
            
            if let data = dayData, data.tasksCompleted > 0 {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Chart Data
    
    public func getCompletionChartData() -> [CompletionData] {
        return completionData.suffix(30) // Last 30 days
    }
    
    public func getHeatmapData() -> [CompletionData] {
        return completionData
    }
    
    public func getFocusTimeChartData() -> [FocusTimeData] {
        return focusTimeData.suffix(30) // Last 30 days
    }
    
    // MARK: - CSV Export
    
    public func exportToCSV() -> String {
        var csv = "Date,Tasks Completed,Tasks Due,Completion Rate,Focus Time (minutes)\n"
        
        for data in completionData {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: data.date)
            
            csv += "\(dateString),\(data.tasksCompleted),\(data.tasksDue),\(String(format: "%.2f", data.completionRate)),\(data.focusTimeData?.minutes ?? 0)\n"
        }
        
        return csv
    }
    
    public func exportCategoryBreakdownToCSV() -> String {
        var csv = "Category,Tasks Count,Color\n"
        
        for breakdown in categoryBreakdown {
            csv += "\(breakdown.category),\(breakdown.count),\(breakdown.color)\n"
        }
        
        return csv
    }
    
    // MARK: - Insights
    
    public func getInsights() -> [String] {
        var insights: [String] = []
        
        // Completion rate insight
        if onTimeCompletionRate >= 0.8 {
            insights.append("Great job! You're completing 80%+ of your tasks on time.")
        } else if onTimeCompletionRate >= 0.6 {
            insights.append("Good progress! You're completing 60%+ of your tasks on time.")
        } else {
            insights.append("Consider breaking down large tasks into smaller, manageable pieces.")
        }
        
        // Streak insight
        if streakDays >= 7 {
            insights.append("Amazing! You've been productive for \(streakDays) days in a row.")
        } else if streakDays >= 3 {
            insights.append("Nice streak! You've been productive for \(streakDays) days.")
        }
        
        // Focus time insight
        if totalFocusTimeSaved >= 1000 {
            insights.append("You've saved over \(totalFocusTimeSaved / 60) hours of focused time!")
        }
        
        // Category insight
        if let topCategory = categoryBreakdown.first {
            insights.append("Your most active category is \(topCategory.category) with \(topCategory.count) tasks.")
        }
        
        return insights
    }
    
    // MARK: - Helper Methods
    
    private func getFocusTimeData(for completionData: CompletionData) -> FocusTimeData? {
        return focusTimeData.first { Calendar.current.isDate($0.date, inSameDayAs: completionData.date) }
    }
}

// MARK: - Extensions for Chart Data
extension CompletionData {
    var focusTimeData: FocusTimeData? {
        // This would be populated by the analytics manager
        return nil
    }
}
