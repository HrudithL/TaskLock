import Foundation

// MARK: - Sample Data Seeder
public class SampleDataSeeder {
    private let taskManager: TaskManager
    private let blockingManager: BlockingManager
    
    public init(taskManager: TaskManager, blockingManager: BlockingManager) {
        self.taskManager = taskManager
        self.blockingManager = blockingManager
    }
    
    public func seedAllData() {
        seedCategories()
        seedPresets()
        seedSampleTasks()
        seedBlockingProfiles()
    }
    
    private func seedCategories() {
        let categories = [
            ("School", "blue", "graduationcap"),
            ("Work", "green", "briefcase"),
            ("Personal", "purple", "person"),
            ("Health", "red", "heart")
        ]
        
        for (name, color, icon) in categories {
            if taskManager.fetchCategories().first(where: { $0.name == name }) == nil {
                taskManager.createCategory(name: name, color: color, icon: icon)
            }
        }
    }
    
    private func seedPresets() {
        let presets = [
            ("Homework Assignment", "Complete math homework", "School", TaskPriority.medium, 60),
            ("Workout Session", "45-minute gym workout", "Health", TaskPriority.high, 45),
            ("Deep Work Block", "Focused work session", "Work", TaskPriority.high, 90)
        ]
        
        for (title, notes, category, priority, minutes) in presets {
            if taskManager.fetchPresets().first(where: { $0.title == title }) == nil {
                taskManager.createPreset(
                    title: title,
                    notes: notes,
                    category: category,
                    priority: priority,
                    estimateMinutes: Int32(minutes)
                )
            }
        }
    }
    
    private func seedSampleTasks() {
        // Stub implementation
    }
    
    private func seedBlockingProfiles() {
        // Stub implementation
    }
    
    public func clearAllData() {
        // Stub implementation
    }
    
    public func enableDemoMode() {
        clearAllData()
        seedAllData()
    }
    
    public func disableDemoMode() {
        clearAllData()
        seedAllData()
    }
}