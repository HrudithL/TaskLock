import Foundation
import Combine

// MARK: - Policy Decision
public struct PolicyDecision {
    public let shouldBlock: Bool
    public let profile: BlockingProfile?
    public let reason: String
    public let triggeringTasks: [TaskItem]
    public let gracePeriodEnds: Date?
    
    public init(shouldBlock: Bool, profile: BlockingProfile? = nil, reason: String, triggeringTasks: [TaskItem] = [], gracePeriodEnds: Date? = nil) {
        self.shouldBlock = shouldBlock
        self.profile = profile
        self.reason = reason
        self.triggeringTasks = triggeringTasks
        self.gracePeriodEnds = gracePeriodEnds
    }
}

// MARK: - Policy Configuration
public struct PolicyConfiguration {
    public let conditionType: ConditionType
    public let gracePeriodMinutes: Int
    public let completionPolicy: CompletionPolicy
    public let allowedApps: Set<String>
    public let strictMode: Bool
    
    public init(
        conditionType: ConditionType = .dueTodayOrOverdue,
        gracePeriodMinutes: Int = 5,
        completionPolicy: CompletionPolicy = .allTasks,
        allowedApps: Set<String> = [],
        strictMode: Bool = false
    ) {
        self.conditionType = conditionType
        self.gracePeriodMinutes = gracePeriodMinutes
        self.completionPolicy = completionPolicy
        self.allowedApps = allowedApps
        self.strictMode = strictMode
    }
}

public enum ConditionType {
    case dueTodayOrOverdue
    case overdueOnly
    case dueTodayOnly
    case custom(NSPredicate)
}

public enum CompletionPolicy {
    case allTasks
    case highPriorityOnly
    case custom(NSPredicate)
}

// MARK: - Policy Engine
public class PolicyEngine: ObservableObject {
    private let taskManager: TaskManager
    private let blockingManager: BlockingManager
    private var cancellables = Set<AnyCancellable>()
    
    @Published public var currentDecision: PolicyDecision = PolicyDecision(shouldBlock: false, reason: "No policy evaluation")
    @Published public var configuration: PolicyConfiguration = PolicyConfiguration()
    
    public init(taskManager: TaskManager, blockingManager: BlockingManager) {
        self.taskManager = taskManager
        self.blockingManager = blockingManager
        
        setupNotificationObservers()
    }
    
    // MARK: - Policy Evaluation
    
    public func evaluatePolicy(for profile: BlockingProfile) -> PolicyDecision {
        guard profile.isTaskConditional else {
            return PolicyDecision(shouldBlock: false, reason: "Profile is not task-conditional")
        }
        
        let tasks = getTasksForCondition()
        
        if tasks.isEmpty {
            return PolicyDecision(
                shouldBlock: false,
                reason: "No tasks meet the blocking condition"
            )
        }
        
        let gracePeriodEnds = configuration.gracePeriodMinutes > 0 ? 
            Date().addingTimeInterval(TimeInterval(configuration.gracePeriodMinutes * 60)) : nil
        
        return PolicyDecision(
            shouldBlock: true,
            profile: profile,
            reason: "\(tasks.count) task(s) meet the blocking condition",
            triggeringTasks: tasks,
            gracePeriodEnds: gracePeriodEnds
        )
    }
    
    public func evaluateAndApplyPolicy(for profile: BlockingProfile) {
        let decision = evaluatePolicy(for: profile)
        
        DispatchQueue.main.async {
            self.currentDecision = decision
        }
        
        if decision.shouldBlock {
            blockingManager.startBlocking(profile: profile)
        } else {
            blockingManager.stopBlocking()
        }
    }
    
    // MARK: - Task Filtering
    
    private func getTasksForCondition() -> [TaskItem] {
        switch configuration.conditionType {
        case .dueTodayOrOverdue:
            return taskManager.fetchActiveTasks()
        case .overdueOnly:
            return taskManager.fetchOverdueTasks()
        case .dueTodayOnly:
            return taskManager.fetchTasksDueToday()
        case .custom(let predicate):
            return taskManager.fetchTasks { task in
                return task.isActive
            }
        }
    }
    
    private func filterTasksByCompletionPolicy(_ tasks: [TaskItem]) -> [TaskItem] {
        switch configuration.completionPolicy {
        case .allTasks:
            return tasks
        case .highPriorityOnly:
            return tasks.filter { $0.priority == .high }
        case .custom(let _):
            // For custom predicates, we'll just return all tasks for now
            // A real implementation would parse the predicate string
            return tasks
        }
    }
    
    // MARK: - Configuration Updates
    
    public func updateConfiguration(_ newConfiguration: PolicyConfiguration) {
        configuration = newConfiguration
        
        // Re-evaluate policy if currently blocking
        if case .active(let profile, _) = blockingManager.currentStatus {
            evaluateAndApplyPolicy(for: profile)
        }
    }
    
    // MARK: - Real-time Updates
    
    private func setupNotificationObservers() {
        // Listen for task changes
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                self?.handleTaskChange()
            }
            .store(in: &cancellables)
        
        // Listen for task completion from notifications
        NotificationCenter.default.publisher(for: .taskCompletedFromNotification)
            .sink { [weak self] _ in
                self?.handleTaskCompletion()
            }
            .store(in: &cancellables)
    }
    
    private func handleTaskChange() {
        // Re-evaluate policy when tasks change
        if case .active(let profile, _) = blockingManager.currentStatus {
            evaluateAndApplyPolicy(for: profile)
        }
    }
    
    private func handleTaskCompletion() {
        // Check if all blocking tasks are now completed
        if case .active(let profile, _) = blockingManager.currentStatus {
            let decision = evaluatePolicy(for: profile)
            
            if !decision.shouldBlock {
                blockingManager.stopBlocking()
            }
        }
    }
    
    // MARK: - Grace Period Management
    
    public func isInGracePeriod() -> Bool {
        guard let gracePeriodEnds = currentDecision.gracePeriodEnds else { return false }
        return Date() < gracePeriodEnds
    }
    
    public func getGracePeriodRemaining() -> TimeInterval? {
        guard let gracePeriodEnds = currentDecision.gracePeriodEnds else { return nil }
        let remaining = gracePeriodEnds.timeIntervalSince(Date())
        return remaining > 0 ? remaining : 0
    }
    
    // MARK: - Emergency Override
    
    public func emergencyOverride() {
        blockingManager.stopBlocking()
        
        DispatchQueue.main.async {
            self.currentDecision = PolicyDecision(
                shouldBlock: false,
                reason: "Emergency override activated"
            )
        }
    }
    
    // MARK: - Analytics
    
    public func getBlockingStats() -> (totalBlockingTime: TimeInterval, tasksBlocked: Int, sessionsCount: Int) {
        // This would integrate with analytics to track blocking statistics
        return (0, 0, 0)
    }
}
