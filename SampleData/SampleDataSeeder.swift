import Foundation
import TasksKit
import BlockingKit

// MARK: - Sample Data Seeder
public class SampleDataSeeder {
    private let taskManager: TaskManager
    private let blockingManager: BlockingManager
    
    public init(taskManager: TaskManager, blockingManager: BlockingManager) {
        self.taskManager = taskManager
        self.blockingManager = blockingManager
    }
    
    // MARK: - Seed All Data
    
    public func seedAllData() {
        seedCategories()
        seedPresets()
        seedSampleTasks()
        seedBlockingProfiles()
    }
    
    // MARK: - Seed Categories
    
    private func seedCategories() {
        let categories = [
            ("School", "blue", "graduationcap"),
            ("Work", "green", "briefcase"),
            ("Personal", "purple", "person"),
            ("Health", "red", "heart"),
            ("Finance", "yellow", "dollarsign.circle"),
            ("Hobbies", "orange", "paintbrush"),
            ("Family", "pink", "house"),
            ("Learning", "indigo", "book")
        ]
        
        for (name, color, icon) in categories {
            if taskManager.fetchCategories().first(where: { $0.name == name }) == nil {
                taskManager.createCategory(name: name, color: color, icon: icon)
            }
        }
    }
    
    // MARK: - Seed Presets
    
    private func seedPresets() {
        let presets = [
            ("Homework Assignment", "Complete math homework", "School", TaskPriority.medium, 60),
            ("Workout Session", "45-minute gym workout", "Health", TaskPriority.high, 45),
            ("Deep Work Block", "Focused work session", "Work", TaskPriority.high, 90),
            ("Grocery Shopping", "Buy ingredients for dinner", "Personal", TaskPriority.medium, 30),
            ("Read Book", "Read 30 pages of current book", "Learning", TaskPriority.low, 30),
            ("Budget Review", "Review monthly expenses", "Finance", TaskPriority.medium, 45),
            ("Call Family", "Weekly check-in with parents", "Family", TaskPriority.medium, 20),
            ("Practice Guitar", "30-minute practice session", "Hobbies", TaskPriority.low, 30),
            ("Project Planning", "Plan next week's tasks", "Work", TaskPriority.high, 60),
            ("Meal Prep", "Prepare lunches for the week", "Personal", TaskPriority.medium, 90)
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
    
    // MARK: - Seed Sample Tasks
    
    private func seedSampleTasks() {
        let calendar = Calendar.current
        let today = Date()
        
        let sampleTasks = [
            // Overdue tasks
            ("Complete project proposal", "Finish the quarterly project proposal", calendar.date(byAdding: .day, value: -2, to: today)!, "Work", TaskPriority.high, 120),
            ("Submit expense report", "Submit monthly expense report", calendar.date(byAdding: .day, value: -1, to: today)!, "Work", TaskPriority.medium, 30),
            
            // Due today
            ("Team meeting prep", "Prepare agenda for team meeting", calendar.date(byAdding: .hour, value: 2, to: today)!, "Work", TaskPriority.high, 45),
            ("Grocery shopping", "Buy ingredients for dinner", calendar.date(byAdding: .hour, value: 4, to: today)!, "Personal", TaskPriority.medium, 30),
            ("Gym workout", "Evening workout session", calendar.date(byAdding: .hour, value: 6, to: today)!, "Health", TaskPriority.medium, 60),
            
            // Due tomorrow
            ("Review code changes", "Code review for pull request", calendar.date(byAdding: .day, value: 1, to: today)!, "Work", TaskPriority.high, 60),
            ("Doctor appointment", "Annual checkup", calendar.date(byAdding: .day, value: 1, to: today)!, "Health", TaskPriority.high, 90),
            ("Book club reading", "Read assigned chapters", calendar.date(byAdding: .day, value: 1, to: today)!, "Learning", TaskPriority.low, 45),
            
            // Due this week
            ("Plan weekend trip", "Research and book accommodations", calendar.date(byAdding: .day, value: 3, to: today)!, "Personal", TaskPriority.medium, 60),
            ("Update resume", "Add recent projects and skills", calendar.date(byAdding: .day, value: 4, to: today)!, "Work", TaskPriority.medium, 90),
            ("Learn new language", "Practice Spanish for 30 minutes", calendar.date(byAdding: .day, value: 5, to: today)!, "Learning", TaskPriority.low, 30),
            
            // Completed tasks (for analytics)
            ("Morning meditation", "10-minute meditation session", calendar.date(byAdding: .day, value: -1, to: today)!, "Health", TaskPriority.low, 10),
            ("Email cleanup", "Organize inbox and respond to emails", calendar.date(byAdding: .day, value: -1, to: today)!, "Work", TaskPriority.medium, 45),
            ("Walk the dog", "Evening walk with the dog", calendar.date(byAdding: .day, value: -2, to: today)!, "Personal", TaskPriority.low, 20)
        ]
        
        for (title, notes, dueDate, category, priority, minutes) in sampleTasks {
            if taskManager.fetchTasks().first(where: { $0.title == title }) == nil {
                let task = taskManager.createTask(
                    title: title,
                    notes: notes,
                    dueDate: dueDate,
                    category: category,
                    priority: priority,
                    estimateMinutes: Int32(minutes)
                )
                
                // Mark some tasks as completed for analytics
                if title.contains("Morning meditation") || title.contains("Email cleanup") || title.contains("Walk the dog") {
                    taskManager.completeTask(task)
                }
            }
        }
    }
    
    // MARK: - Seed Blocking Profiles
    
    private func seedBlockingProfiles() {
        let profiles = [
            BlockingProfile(
                name: "Focus Mode",
                description: "Blocks distracting apps during focus sessions",
                isTaskConditional: true,
                conditionType: .activeTaskOnly,
                gracePeriodMinutes: 5,
                completionPolicy: .currentTaskDone,
                allowedApps: ["Calendar", "Notes", "Safari"],
                isStrictMode: false,
                requiresPhysicalUnlock: false
            ),
            BlockingProfile(
                name: "Study Mode",
                description: "Blocks all non-essential apps during study time",
                isTaskConditional: true,
                conditionType: .anyDueToday,
                gracePeriodMinutes: 10,
                completionPolicy: .allTriggeringTasksDone,
                allowedApps: ["Calendar", "Notes"],
                isStrictMode: true,
                requiresPhysicalUnlock: true
            ),
            BlockingProfile(
                name: "Work Mode",
                description: "Blocks social media and entertainment apps during work",
                isTaskConditional: true,
                conditionType: .onlyHighPriorityDueToday,
                gracePeriodMinutes: 0,
                completionPolicy: .currentTaskDone,
                allowedApps: ["Calendar", "Notes", "Mail", "Safari"],
                isStrictMode: false,
                requiresPhysicalUnlock: false
            ),
            BlockingProfile(
                name: "Deep Work",
                description: "Maximum focus mode with minimal distractions",
                isTaskConditional: true,
                conditionType: .allDueToday,
                gracePeriodMinutes: 15,
                completionPolicy: .allTriggeringTasksDone,
                allowedApps: ["Calendar"],
                isStrictMode: true,
                requiresPhysicalUnlock: true
            ),
            BlockingProfile(
                name: "Evening Wind-down",
                description: "Blocks work apps in the evening",
                isTaskConditional: false,
                conditionType: .anyDueToday,
                gracePeriodMinutes: 0,
                completionPolicy: .currentTaskDone,
                allowedApps: ["Calendar", "Notes", "Music", "Books"],
                isStrictMode: false,
                requiresPhysicalUnlock: false
            )
        ]
        
        // In a real implementation, these would be saved to persistent storage
        // For now, they're created dynamically by the BlockingManager
    }
    
    // MARK: - Clear All Data
    
    public func clearAllData() {
        // Clear tasks
        let tasks = taskManager.fetchTasks()
        for task in tasks {
            taskManager.deleteTask(task)
        }
        
        // Clear categories
        let categories = taskManager.fetchCategories()
        for category in categories {
            taskManager.deleteCategory(category)
        }
        
        // Clear presets
        let presets = taskManager.fetchPresets()
        for preset in presets {
            taskManager.deletePreset(preset)
        }
    }
    
    // MARK: - Demo Mode
    
    public func enableDemoMode() {
        clearAllData()
        seedAllData()
        
        // Add some additional demo-specific tasks
        let calendar = Calendar.current
        let today = Date()
        
        let demoTasks = [
            ("Demo Task 1", "This is a demo task for testing", calendar.date(byAdding: .hour, value: 1, to: today)!, "Work", TaskPriority.high, 30),
            ("Demo Task 2", "Another demo task", calendar.date(byAdding: .hour, value: 3, to: today)!, "Personal", TaskPriority.medium, 45),
            ("Demo Task 3", "Third demo task", calendar.date(byAdding: .day, value: 1, to: today)!, "School", TaskPriority.low, 60)
        ]
        
        for (title, notes, dueDate, category, priority, minutes) in demoTasks {
            taskManager.createTask(
                title: title,
                notes: notes,
                dueDate: dueDate,
                category: category,
                priority: priority,
                estimateMinutes: Int32(minutes)
            )
        }
    }
    
    public func disableDemoMode() {
        clearAllData()
        seedAllData()
    }
}
