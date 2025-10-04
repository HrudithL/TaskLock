import Foundation

// MARK: - Policy Decision
public struct PolicyDecision {
    public let shouldBlock: Bool
    public let profile: BlockingProfile?
    public let reason: String
    public let triggeringTasks: [Task]
    
    public init(shouldBlock: Bool, profile: BlockingProfile? = nil, reason: String, triggeringTasks: [Task] = []) {
        self.shouldBlock = shouldBlock
        self.profile = profile
        self.reason = reason
        self.triggeringTasks = triggeringTasks
    }
}

// MARK: - Policy Engine
public class PolicyEngine {
    private let taskManager: TaskManager
    private let blockingManager: BlockingManager
    
    public init(taskManager: TaskManager, blockingManager: BlockingManager) {
        self.taskManager = taskManager
        self.blockingManager = blockingManager
    }
    
    public func evaluatePolicy(for profile: BlockingProfile) -> PolicyDecision {
        guard profile.isTaskConditional else {
            return PolicyDecision(shouldBlock: false, reason: "Profile is not task-conditional")
        }
        
        let activeTasks = taskManager.fetchActiveTasks()
        
        if activeTasks.isEmpty {
            return PolicyDecision(
                shouldBlock: false,
                reason: "No tasks meet the blocking condition"
            )
        }
        
        return PolicyDecision(
            shouldBlock: true,
            profile: profile,
            reason: "\(activeTasks.count) task(s) meet the blocking condition",
            triggeringTasks: activeTasks
        )
    }
}