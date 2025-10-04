import Foundation
import TasksKit
import BlockingKit

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
    
    // MARK: - Main Policy Evaluation
    
    public func evaluatePolicy(for profile: BlockingProfile) -> PolicyDecision {
        guard profile.isTaskConditional else {
            return PolicyDecision(shouldBlock: false, reason: "Profile is not task-conditional")
        }
        
        let allTasks = taskManager.fetchTasks()
        let todayTasks = taskManager.fetchTasksDueToday()
        let overdueTasks = taskManager.fetchOverdueTasks()
        let activeTasks = taskManager.fetchActiveTasks()
        
        let triggeringTasks = getTriggeringTasks(
            profile: profile,
            allTasks: allTasks,
            todayTasks: todayTasks,
            overdueTasks: overdueTasks,
            activeTasks: activeTasks
        )
        
        if triggeringTasks.isEmpty {
            return PolicyDecision(
                shouldBlock: false,
                reason: "No tasks meet the blocking condition"
            )
        }
        
        // Check grace period
        if shouldApplyGracePeriod(for: profile, triggeringTasks: triggeringTasks) {
            return PolicyDecision(
                shouldBlock: false,
                reason: "Grace period is still active",
                triggeringTasks: triggeringTasks
            )
        }
        
        return PolicyDecision(
            shouldBlock: true,
            profile: profile,
            reason: "\(triggeringTasks.count) task(s) meet the blocking condition",
            triggeringTasks: triggeringTasks
        )
    }
    
    // MARK: - Condition Evaluation
    
    private func getTriggeringTasks(
        profile: BlockingProfile,
        allTasks: [Task],
        todayTasks: [Task],
        overdueTasks: [Task],
        activeTasks: [Task]
    ) -> [Task] {
        switch profile.conditionType {
        case .anyDueToday:
            return todayTasks.filter { !$0.isCompleted }
            
        case .allDueToday:
            return todayTasks.filter { !$0.isCompleted }
            
        case .onlyHighPriorityDueToday:
            return todayTasks.filter { !$0.isCompleted && $0.priority == .high }
            
        case .activeTaskOnly:
            return activeTasks.filter { !$0.isCompleted }
        }
    }
    
    // MARK: - Grace Period Logic
    
    private func shouldApplyGracePeriod(for profile: BlockingProfile, triggeringTasks: [Task]) -> Bool {
        guard profile.gracePeriodMinutes > 0 else { return false }
        
        let now = Date()
        let gracePeriodEnd = Calendar.current.date(byAdding: .minute, value: profile.gracePeriodMinutes, to: now)!
        
        // Check if any triggering task is within the grace period
        for task in triggeringTasks {
            guard let dueDate = task.dueDate else { continue }
            
            if dueDate <= gracePeriodEnd {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Completion Policy Evaluation
    
    public func shouldUnblockAfterCompletion(
        completedTask: Task,
        profile: BlockingProfile,
        currentTriggeringTasks: [Task]
    ) -> Bool {
        switch profile.completionPolicy {
        case .currentTaskDone:
            return true
            
        case .allTriggeringTasksDone:
            let remainingTasks = currentTriggeringTasks.filter { !$0.isCompleted }
            return remainingTasks.isEmpty
        }
    }
    
    // MARK: - Time Zone Handling
    
    public func adjustForTimeZone(_ date: Date, timeZone: TimeZone = TimeZone.current) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: timeZone, from: date)
        return calendar.date(from: components) ?? date
    }
    
    // MARK: - Edge Case Handling
    
    public func handleMidnightTransition() -> PolicyDecision {
        // Re-evaluate all profiles at midnight
        let profiles = blockingManager.createDefaultProfiles()
        var decisions: [PolicyDecision] = []
        
        for profile in profiles {
            if profile.isTaskConditional {
                let decision = evaluatePolicy(for: profile)
                decisions.append(decision)
            }
        }
        
        // Return the most restrictive decision
        let blockingDecisions = decisions.filter { $0.shouldBlock }
        if let mostRestrictive = blockingDecisions.max(by: { $0.triggeringTasks.count < $1.triggeringTasks.count }) {
            return mostRestrictive
        }
        
        return PolicyDecision(shouldBlock: false, reason: "No blocking conditions met after midnight transition")
    }
    
    // MARK: - Daylight Saving Time Handling
    
    public func handleDSTTransition() -> PolicyDecision {
        // Similar to midnight transition but with DST awareness
        let calendar = Calendar.current
        let now = Date()
        
        // Check if we're in a DST transition period
        let timeZone = TimeZone.current
        let isDST = timeZone.isDaylightSavingTime(for: now)
        
        // Re-evaluate policies with DST awareness
        return evaluatePolicy(for: blockingManager.createDefaultProfiles().first!)
    }
    
    // MARK: - Validation
    
    public func validateProfile(_ profile: BlockingProfile) -> [String] {
        var errors: [String] = []
        
        if profile.name.isEmpty {
            errors.append("Profile name cannot be empty")
        }
        
        if profile.gracePeriodMinutes < 0 {
            errors.append("Grace period cannot be negative")
        }
        
        if profile.gracePeriodMinutes > 1440 { // 24 hours
            errors.append("Grace period cannot exceed 24 hours")
        }
        
        return errors
    }
    
    // MARK: - Debug Information
    
    public func getDebugInfo(for profile: BlockingProfile) -> [String: Any] {
        let allTasks = taskManager.fetchTasks()
        let todayTasks = taskManager.fetchTasksDueToday()
        let overdueTasks = taskManager.fetchOverdueTasks()
        let activeTasks = taskManager.fetchActiveTasks()
        
        return [
            "profile": profile.name,
            "conditionType": profile.conditionType.rawValue,
            "gracePeriodMinutes": profile.gracePeriodMinutes,
            "completionPolicy": profile.completionPolicy.rawValue,
            "totalTasks": allTasks.count,
            "todayTasks": todayTasks.count,
            "overdueTasks": overdueTasks.count,
            "activeTasks": activeTasks.count,
            "isTaskConditional": profile.isTaskConditional,
            "isStrictMode": profile.isStrictMode,
            "requiresPhysicalUnlock": profile.requiresPhysicalUnlock
        ]
    }
}
