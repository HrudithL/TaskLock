import Foundation
import Combine
import SwiftUI

// MARK: - App State
@MainActor
public class AppState: ObservableObject {
    @Published public var tasks: [TaskItem] = []
    @Published public var categories: [Category] = []
    @Published public var presets: [TaskPreset] = []
    @Published public var blockingProfiles: [BlockingProfile] = []
    @Published public var currentBlockingStatus: BlockingStatus = .inactive
    @Published public var isAuthorized: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var selectedTab: Int = 0
    @Published public var isBlocking: Bool = false
    
    private let persistenceController: PersistenceController
    public let taskManager: TaskManager
    private let blockingManager: BlockingManager
    private let policyEngine: PolicyEngine
    public let analyticsManager: AnalyticsManager
    private let physicalUnlockManager: PhysicalUnlockManager
    private let notificationManager: NotificationManager
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        self.persistenceController = PersistenceController.shared
        self.taskManager = TaskManager(dataStore: persistenceController.dataStore)
        self.blockingManager = BlockingManager()
        self.policyEngine = PolicyEngine(taskManager: taskManager, blockingManager: blockingManager)
        self.analyticsManager = AnalyticsManager(dataStore: persistenceController.dataStore, taskManager: taskManager)
        self.physicalUnlockManager = PhysicalUnlockManager()
        self.notificationManager = NotificationManager.shared
        
        setupObservers()
        loadInitialData()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe blocking status changes
        blockingManager.$currentStatus
            .assign(to: \.currentBlockingStatus, on: self)
            .store(in: &cancellables)
        
        // Observe authorization status
        blockingManager.$isAuthorized
            .assign(to: \.isAuthorized, on: self)
            .store(in: &cancellables)
        
        // Observe physical unlock success
        NotificationCenter.default.publisher(for: .physicalUnlockSuccess)
            .sink { [weak self] _ in
                self?.handlePhysicalUnlock()
            }
            .store(in: &cancellables)
        
        // Observe task completion from notifications
        NotificationCenter.default.publisher(for: .taskCompletedFromNotification)
            .sink { [weak self] notification in
                if let taskId = notification.object as? String {
                    self?.handleTaskCompletionFromNotification(taskId: taskId)
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        isLoading = true
        
        Task { @MainActor in
            await loadTasks()
            await loadCategories()
            await loadPresets()
            await loadBlockingProfiles()
            
            // Create default data if needed
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
            
            // Request permissions
            await requestPermissions()
            
            isLoading = false
        }
    }
    
    // MARK: - Data Loading
    
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
    
    // MARK: - Permissions
    
    private func requestPermissions() async {
        // Request Family Controls authorization
        await blockingManager.requestAuthorization()
        
        // Request notification authorization
        do {
            try await notificationManager.requestAuthorization()
            notificationManager.setupNotificationCategories()
        } catch {
            print("Notification authorization failed: \(error)")
        }
    }
    
    // MARK: - Task Operations
    
    public func createTask(
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        reminders: [Date] = [],
        category: Category? = nil,
        priority: TaskPriority = .medium,
        estimateMinutes: Int32 = 30
    ) {
        let task = taskManager.createTask(
            title: title,
            notes: notes,
            dueDate: dueDate,
            reminders: reminders,
            category: category,
            priority: priority,
            estimateMinutes: estimateMinutes
        )
        
        tasks.append(task)
        
        // Re-evaluate blocking policy
        if case .active(let profile, _) = currentBlockingStatus {
            policyEngine.evaluateAndApplyPolicy(for: profile)
        }
    }
    
    public func updateTask(_ task: TaskItem) {
        taskManager.updateTask(task)
        
        // Re-evaluate blocking policy
        if case .active(let profile, _) = currentBlockingStatus {
            policyEngine.evaluateAndApplyPolicy(for: profile)
        }
    }
    
    public func completeTask(_ task: TaskItem) {
        taskManager.completeTask(task)
        
        // Update analytics
        analyticsManager.updateAnalytics()
        
        // Re-evaluate blocking policy
        if case .active(let profile, _) = currentBlockingStatus {
            policyEngine.evaluateAndApplyPolicy(for: profile)
        }
    }
    
    public func deleteTask(_ task: TaskItem) {
        taskManager.deleteTask(task)
        tasks.removeAll { $0.id == task.id }
        
        // Re-evaluate blocking policy
        if case .active(let profile, _) = currentBlockingStatus {
            policyEngine.evaluateAndApplyPolicy(for: profile)
        }
    }
    
    // MARK: - Category Operations
    
    public func createCategory(name: String, color: String = "blue", icon: String = "folder") {
        let category = taskManager.createCategory(name: name, color: color, icon: icon)
        categories.append(category)
    }
    
    public func deleteCategory(_ category: Category) {
        taskManager.deleteCategory(category)
        categories.removeAll { $0.id == category.id }
    }
    
    // MARK: - Preset Operations
    
    public func createPreset(
        title: String,
        notes: String? = nil,
        category: String = "Personal",
        priority: TaskPriority = .medium,
        estimateMinutes: Int32 = 30
    ) {
        let preset = taskManager.createPreset(
            title: title,
            notes: notes,
            category: category,
            priority: priority,
            estimateMinutes: estimateMinutes
        )
        presets.append(preset)
    }
    
    public func deletePreset(_ preset: TaskPreset) {
        taskManager.deletePreset(preset)
        presets.removeAll { $0.id == preset.id }
    }
    
    // MARK: - Blocking Operations
    
    public func startBlocking(profile: BlockingProfile) {
        policyEngine.evaluateAndApplyPolicy(for: profile)
    }
    
    public func stopBlocking() {
        blockingManager.stopBlocking()
    }
    
    public func emergencyUnlock() {
        policyEngine.emergencyOverride()
        blockingManager.stopBlocking()
    }
    
    // MARK: - Filtered Task Lists
    
    public func getTasksDueToday() -> [TaskItem] {
        return taskManager.fetchTasksDueToday()
    }
    
    public func getOverdueTasks() -> [TaskItem] {
        return taskManager.fetchOverdueTasks()
    }
    
    public func getActiveTasks() -> [TaskItem] {
        return taskManager.fetchActiveTasks()
    }
    
    public func getTasksByCategory(_ category: Category) -> [TaskItem] {
        return taskManager.fetchTasksByCategory(category)
    }
    
    public func getCompletedTasks() -> [TaskItem] {
        return taskManager.fetchCompletedTasks()
    }
    
    // MARK: - Event Handlers
    
    private func handlePhysicalUnlock() {
        // Handle successful physical unlock
        emergencyUnlock()
    }
    
    private func handleTaskCompletionFromNotification(taskId: String) {
        // Find and complete the task
        if let task = tasks.first(where: { $0.id.uuidString == taskId }) {
            completeTask(task)
        }
    }
    
    // MARK: - Refresh Data
    
    public func refreshData() {
        Task { @MainActor in
            await loadTasks()
            await loadCategories()
            await loadPresets()
            analyticsManager.updateAnalytics()
        }
    }
}
