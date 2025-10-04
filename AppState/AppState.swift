import Foundation
import Combine
import SwiftUI
import TasksKit
import BlockingKit
import PolicyEngine

// MARK: - App State
@MainActor
public class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published public var tasks: [Task] = []
    @Published public var categories: [Category] = []
    @Published public var presets: [TaskPreset] = []
    @Published public var blockingProfiles: [BlockingProfile] = []
    @Published public var currentBlockingStatus: BlockingStatus = .inactive
    @Published public var isAuthorized: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    // MARK: - Dependencies
    private let taskManager: TaskManager
    private let blockingManager: BlockingManager
    private let policyEngine: PolicyEngine
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var taskUpdateTimer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: - Initialization
    public init() {
        let persistenceController = PersistenceController.shared
        self.taskManager = TaskManager(persistenceController: persistenceController)
        self.blockingManager = BlockingManager()
        self.policyEngine = PolicyEngine(taskManager: taskManager, blockingManager: blockingManager)
        
        setupBindings()
        setupBackgroundTasks()
        loadInitialData()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind blocking manager status
        blockingManager.$currentStatus
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentBlockingStatus, on: self)
            .store(in: &cancellables)
        
        blockingManager.$isAuthorized
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAuthorized, on: self)
            .store(in: &cancellables)
        
        // Setup task update timer
        taskUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateTaskBasedBlocking()
            }
        }
    }
    
    private func setupBackgroundTasks() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // MARK: - Data Loading
    private func loadInitialData() {
        isLoading = true
        
        Task {
            await loadTasks()
            await loadCategories()
            await loadPresets()
            await loadBlockingProfiles()
            await checkAuthorization()
            
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
        // In a real implementation, this would load from persistent storage
        blockingProfiles = blockingManager.createDefaultProfiles()
    }
    
    private func checkAuthorization() async {
        isAuthorized = blockingManager.isAuthorized
    }
    
    // MARK: - Task Management
    public func createTask(
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        reminders: [Date] = [],
        category: String = "Personal",
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
        Task {
            await updateTaskBasedBlocking()
        }
    }
    
    public func updateTask(_ task: Task) {
        taskManager.updateTask(task)
        Task {
            await loadTasks()
            await updateTaskBasedBlocking()
        }
    }
    
    public func completeTask(_ task: Task) {
        taskManager.completeTask(task)
        Task {
            await loadTasks()
            await updateTaskBasedBlocking()
        }
    }
    
    public func deleteTask(_ task: Task) {
        taskManager.deleteTask(task)
        tasks.removeAll { $0.id == task.id }
        Task {
            await updateTaskBasedBlocking()
        }
    }
    
    // MARK: - Category Management
    public func createCategory(name: String, color: String = "blue", icon: String = "folder") {
        let category = taskManager.createCategory(name: name, color: color, icon: icon)
        categories.append(category)
    }
    
    public func deleteCategory(_ category: Category) {
        taskManager.deleteCategory(category)
        categories.removeAll { $0.id == category.id }
    }
    
    // MARK: - Preset Management
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
    
    // MARK: - Blocking Management
    public func requestAuthorization() async {
        do {
            try await blockingManager.requestAuthorization()
            isAuthorized = blockingManager.isAuthorized
        } catch {
            errorMessage = "Failed to request authorization: \(error.localizedDescription)"
        }
    }
    
    public func startBlocking(profile: BlockingProfile) async {
        await blockingManager.startBlocking(profile: profile)
    }
    
    public func stopBlocking() async {
        await blockingManager.stopBlocking()
    }
    
    public func attemptDisableBlocking() async -> Bool {
        return await blockingManager.attemptDisableBlocking()
    }
    
    // MARK: - Policy Engine Integration
    private func updateTaskBasedBlocking() async {
        guard isAuthorized else { return }
        
        // Find the most restrictive blocking profile that should be active
        var mostRestrictiveDecision: PolicyDecision?
        
        for profile in blockingProfiles {
            let decision = policyEngine.evaluatePolicy(for: profile)
            if decision.shouldBlock {
                if mostRestrictiveDecision == nil || 
                   decision.triggeringTasks.count > mostRestrictiveDecision!.triggeringTasks.count {
                    mostRestrictiveDecision = decision
                }
            }
        }
        
        // Apply or remove blocking based on the decision
        if let decision = mostRestrictiveDecision, decision.shouldBlock {
            if case .inactive = currentBlockingStatus {
                await startBlocking(profile: decision.profile!)
            }
        } else {
            if case .active = currentBlockingStatus {
                await stopBlocking()
            }
        }
    }
    
    // MARK: - Task Filtering
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
    
    public func getUpcomingTasks(days: Int = 7) -> [Task] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: days, to: startOfDay)!
        
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= startOfDay && dueDate <= endDate && !task.isCompleted
        }.sorted { $0.dueDate! < $1.dueDate! }
    }
    
    // MARK: - Background Handling
    @objc private func appDidEnterBackground() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "TaskLockBackground") {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        }
        
        Task {
            await updateTaskBasedBlocking()
        }
    }
    
    @objc private func appWillEnterForeground() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        Task {
            await loadTasks()
            await updateTaskBasedBlocking()
        }
    }
    
    // MARK: - Error Handling
    public func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Demo Mode
    public func enableDemoMode() {
        // Create demo tasks for testing
        let demoTasks = [
            ("Complete project proposal", "Finish the quarterly project proposal", Date(), "Work", TaskPriority.high, 120),
            ("Grocery shopping", "Buy ingredients for dinner", Calendar.current.date(byAdding: .hour, value: 2, to: Date())!, "Personal", TaskPriority.medium, 45),
            ("Study for exam", "Review chapters 5-8", Calendar.current.date(byAdding: .day, value: 1, to: Date())!, "School", TaskPriority.high, 90)
        ]
        
        for (title, notes, dueDate, category, priority, minutes) in demoTasks {
            createTask(
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
        // Remove demo tasks
        let demoTaskTitles = ["Complete project proposal", "Grocery shopping", "Study for exam"]
        let tasksToDelete = tasks.filter { demoTaskTitles.contains($0.title) }
        
        for task in tasksToDelete {
            deleteTask(task)
        }
    }
}
