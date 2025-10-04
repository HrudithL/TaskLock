import Foundation
import Combine
import SwiftUI

// MARK: - App State
@MainActor
public class AppState: ObservableObject {
    @Published public var tasks: [Task] = []
    @Published public var categories: [Category] = []
    @Published public var presets: [TaskPreset] = []
    @Published public var blockingProfiles: [BlockingProfile] = []
    @Published public var currentBlockingStatus: BlockingStatus = .inactive
    @Published public var isAuthorized: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    private let taskManager: TaskManager
    private let blockingManager: BlockingManager
    private let policyEngine: PolicyEngine
    
    public init() {
        let persistenceController = PersistenceController.shared
        self.taskManager = TaskManager(persistenceController: persistenceController)
        self.blockingManager = BlockingManager()
        self.policyEngine = PolicyEngine(taskManager: taskManager, blockingManager: blockingManager)
        
        loadInitialData()
    }
    
    private func loadInitialData() {
        isLoading = true
        
        Task {
            await loadTasks()
            await loadCategories()
            await loadPresets()
            await loadBlockingProfiles()
            
            if categories.isEmpty {
                taskManager.createDefaultCategories()
                await loadCategories()
            }
            
            if presets.isEmpty {
                taskManager.createDefaultPresets()
                await loadPresets()
            }
            
            if blockingProfiles.isEmpty {
                blockingProfiles = blockingManager.createDefaultProfiles()
            }
            
            isLoading = false
        }
    }
    
    private func loadTasks() async {
        tasks = taskManager.fetchTasks()
    }
    
    private func loadCategories() async {
        categories = taskManager.fetchCategories()
    }
    
    private func loadPresets() async {
        presets = taskManager.fetchPresets()
    }
    
    private func loadBlockingProfiles() async {
        blockingProfiles = blockingManager.createDefaultProfiles()
    }
    
    public func getTasksDueToday() -> [Task] {
        return taskManager.fetchTasksDueToday()
    }
    
    public func getOverdueTasks() -> [Task] {
        return taskManager.fetchOverdueTasks()
    }
    
    public func getActiveTasks() -> [Task] {
        return taskManager.fetchActiveTasks()
    }
    
    public func getTasksByCategory(_ category: String) -> [Task] {
        return taskManager.fetchTasksByCategory(category)
    }
}