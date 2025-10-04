import XCTest
import Foundation
@testable import PolicyEngine
@testable import TasksKit
@testable import BlockingKit

class PolicyEngineTests: XCTestCase {
    var policyEngine: PolicyEngine!
    var taskManager: TaskManager!
    var blockingManager: BlockingManager!
    
    override func setUp() {
        super.setUp()
        // Use in-memory CoreData for testing
        let persistenceController = PersistenceController(inMemory: true)
        taskManager = TaskManager(persistenceController: persistenceController)
        blockingManager = BlockingManager()
        policyEngine = PolicyEngine(taskManager: taskManager, blockingManager: blockingManager)
    }
    
    override func tearDown() {
        policyEngine = nil
        taskManager = nil
        blockingManager = nil
        super.tearDown()
    }
    
    // MARK: - Test Any Due Today Condition
    
    func testAnyDueTodayCondition_WithTasksDueToday_ShouldBlock() {
        // Given
        let profile = BlockingProfile(
            name: "Test Profile",
            description: "Test",
            isTaskConditional: true,
            conditionType: .anyDueToday
        )
        
        let task = taskManager.createTask(
            title: "Test Task",
            dueDate: Date(),
            category: "Test",
            priority: .medium
        )
        
        // When
        let decision = policyEngine.evaluatePolicy(for: profile)
        
        // Then
        XCTAssertTrue(decision.shouldBlock)
        XCTAssertEqual(decision.triggeringTasks.count, 1)
        XCTAssertEqual(decision.triggeringTasks.first?.id, task.id)
    }
    
    func testAnyDueTodayCondition_WithNoTasksDueToday_ShouldNotBlock() {
        // Given
        let profile = BlockingProfile(
            name: "Test Profile",
            description: "Test",
            isTaskConditional: true,
            conditionType: .anyDueToday
        )
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        taskManager.createTask(
            title: "Future Task",
            dueDate: tomorrow,
            category: "Test",
            priority: .medium
        )
        
        // When
        let decision = policyEngine.evaluatePolicy(for: profile)
        
        // Then
        XCTAssertFalse(decision.shouldBlock)
        XCTAssertTrue(decision.triggeringTasks.isEmpty)
    }
    
    // MARK: - Test High Priority Only Condition
    
    func testOnlyHighPriorityDueToday_WithHighPriorityTask_ShouldBlock() {
        // Given
        let profile = BlockingProfile(
            name: "Test Profile",
            description: "Test",
            isTaskConditional: true,
            conditionType: .onlyHighPriorityDueToday
        )
        
        let highPriorityTask = taskManager.createTask(
            title: "High Priority Task",
            dueDate: Date(),
            category: "Test",
            priority: .high
        )
        
        let lowPriorityTask = taskManager.createTask(
            title: "Low Priority Task",
            dueDate: Date(),
            category: "Test",
            priority: .low
        )
        
        // When
        let decision = policyEngine.evaluatePolicy(for: profile)
        
        // Then
        XCTAssertTrue(decision.shouldBlock)
        XCTAssertEqual(decision.triggeringTasks.count, 1)
        XCTAssertEqual(decision.triggeringTasks.first?.id, highPriorityTask.id)
        XCTAssertNotEqual(decision.triggeringTasks.first?.id, lowPriorityTask.id)
    }
    
    func testOnlyHighPriorityDueToday_WithNoHighPriorityTasks_ShouldNotBlock() {
        // Given
        let profile = BlockingProfile(
            name: "Test Profile",
            description: "Test",
            isTaskConditional: true,
            conditionType: .onlyHighPriorityDueToday
        )
        
        taskManager.createTask(
            title: "Low Priority Task",
            dueDate: Date(),
            category: "Test",
            priority: .low
        )
        
        // When
        let decision = policyEngine.evaluatePolicy(for: profile)
        
        // Then
        XCTAssertFalse(decision.shouldBlock)
        XCTAssertTrue(decision.triggeringTasks.isEmpty)
    }
    
    // MARK: - Test Grace Period
    
    func testGracePeriod_WithinGracePeriod_ShouldNotBlock() {
        // Given
        let profile = BlockingProfile(
            name: "Test Profile",
            description: "Test",
            isTaskConditional: true,
            conditionType: .anyDueToday,
            gracePeriodMinutes: 30
        )
        
        let futureDueDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        taskManager.createTask(
            title: "Future Task",
            dueDate: futureDueDate,
            category: "Test",
            priority: .medium
        )
        
        // When
        let decision = policyEngine.evaluatePolicy(for: profile)
        
        // Then
        XCTAssertFalse(decision.shouldBlock)
        XCTAssertEqual(decision.reason, "Grace period is still active")
    }
    
    func testGracePeriod_AfterGracePeriod_ShouldBlock() {
        // Given
        let profile = BlockingProfile(
            name: "Test Profile",
            description: "Test",
            isTaskConditional: true,
            conditionType: .anyDueToday,
            gracePeriodMinutes: 5
        )
        
        let pastDueDate = Calendar.current.date(byAdding: .minute, value: -10, to: Date())!
        taskManager.createTask(
            title: "Overdue Task",
            dueDate: pastDueDate,
            category: "Test",
            priority: .medium
        )
        
        // When
        let decision = policyEngine.evaluatePolicy(for: profile)
        
        // Then
        XCTAssertTrue(decision.shouldBlock)
        XCTAssertEqual(decision.triggeringTasks.count, 1)
    }
    
    // MARK: - Test Completion Policy
    
    func testCurrentTaskDoneCompletionPolicy_ShouldUnblock() {
        // Given
        let profile = BlockingProfile(
            name: "Test Profile",
            description: "Test",
            completionPolicy: .currentTaskDone
        )
        
        let task = taskManager.createTask(
            title: "Test Task",
            dueDate: Date(),
            category: "Test",
            priority: .medium
        )
        
        let triggeringTasks = [task]
        
        // When
        let shouldUnblock = policyEngine.shouldUnblockAfterCompletion(
            completedTask: task,
            profile: profile,
            currentTriggeringTasks: triggeringTasks
        )
        
        // Then
        XCTAssertTrue(shouldUnblock)
    }
    
    func testAllTriggeringTasksDoneCompletionPolicy_WithRemainingTasks_ShouldNotUnblock() {
        // Given
        let profile = BlockingProfile(
            name: "Test Profile",
            description: "Test",
            completionPolicy: .allTriggeringTasksDone
        )
        
        let task1 = taskManager.createTask(
            title: "Task 1",
            dueDate: Date(),
            category: "Test",
            priority: .medium
        )
        
        let task2 = taskManager.createTask(
            title: "Task 2",
            dueDate: Date(),
            category: "Test",
            priority: .medium
        )
        
        let triggeringTasks = [task1, task2]
        
        // When
        let shouldUnblock = policyEngine.shouldUnblockAfterCompletion(
            completedTask: task1,
            profile: profile,
            currentTriggeringTasks: triggeringTasks
        )
        
        // Then
        XCTAssertFalse(shouldUnblock)
    }
    
    func testAllTriggeringTasksDoneCompletionPolicy_WithAllTasksDone_ShouldUnblock() {
        // Given
        let profile = BlockingProfile(
            name: "Test Profile",
            description: "Test",
            completionPolicy: .allTriggeringTasksDone
        )
        
        let task1 = taskManager.createTask(
            title: "Task 1",
            dueDate: Date(),
            category: "Test",
            priority: .medium
        )
        
        let task2 = taskManager.createTask(
            title: "Task 2",
            dueDate: Date(),
            category: "Test",
            priority: .medium
        )
        
        taskManager.completeTask(task2)
        let triggeringTasks = [task1, task2]
        
        // When
        let shouldUnblock = policyEngine.shouldUnblockAfterCompletion(
            completedTask: task1,
            profile: profile,
            currentTriggeringTasks: triggeringTasks
        )
        
        // Then
        XCTAssertTrue(shouldUnblock)
    }
    
    // MARK: - Test Profile Validation
    
    func testProfileValidation_ValidProfile_ShouldPass() {
        // Given
        let profile = BlockingProfile(
            name: "Valid Profile",
            description: "Valid description",
            gracePeriodMinutes: 15
        )
        
        // When
        let errors = policyEngine.validateProfile(profile)
        
        // Then
        XCTAssertTrue(errors.isEmpty)
    }
    
    func testProfileValidation_EmptyName_ShouldFail() {
        // Given
        let profile = BlockingProfile(
            name: "",
            description: "Valid description"
        )
        
        // When
        let errors = policyEngine.validateProfile(profile)
        
        // Then
        XCTAssertFalse(errors.isEmpty)
        XCTAssertTrue(errors.contains("Profile name cannot be empty"))
    }
    
    func testProfileValidation_NegativeGracePeriod_ShouldFail() {
        // Given
        let profile = BlockingProfile(
            name: "Valid Profile",
            description: "Valid description",
            gracePeriodMinutes: -5
        )
        
        // When
        let errors = policyEngine.validateProfile(profile)
        
        // Then
        XCTAssertFalse(errors.isEmpty)
        XCTAssertTrue(errors.contains("Grace period cannot be negative"))
    }
    
    func testProfileValidation_ExcessiveGracePeriod_ShouldFail() {
        // Given
        let profile = BlockingProfile(
            name: "Valid Profile",
            description: "Valid description",
            gracePeriodMinutes: 1500 // 25 hours
        )
        
        // When
        let errors = policyEngine.validateProfile(profile)
        
        // Then
        XCTAssertFalse(errors.isEmpty)
        XCTAssertTrue(errors.contains("Grace period cannot exceed 24 hours"))
    }
    
    // MARK: - Test Non-Task Conditional Profile
    
    func testNonTaskConditionalProfile_ShouldNotBlock() {
        // Given
        let profile = BlockingProfile(
            name: "Non-Task Profile",
            description: "Not task conditional",
            isTaskConditional: false
        )
        
        taskManager.createTask(
            title: "Test Task",
            dueDate: Date(),
            category: "Test",
            priority: .medium
        )
        
        // When
        let decision = policyEngine.evaluatePolicy(for: profile)
        
        // Then
        XCTAssertFalse(decision.shouldBlock)
        XCTAssertEqual(decision.reason, "Profile is not task-conditional")
    }
    
    // MARK: - Test Completed Tasks
    
    func testCompletedTasks_ShouldNotTriggerBlocking() {
        // Given
        let profile = BlockingProfile(
            name: "Test Profile",
            description: "Test",
            isTaskConditional: true,
            conditionType: .anyDueToday
        )
        
        let task = taskManager.createTask(
            title: "Test Task",
            dueDate: Date(),
            category: "Test",
            priority: .medium
        )
        
        taskManager.completeTask(task)
        
        // When
        let decision = policyEngine.evaluatePolicy(for: profile)
        
        // Then
        XCTAssertFalse(decision.shouldBlock)
        XCTAssertTrue(decision.triggeringTasks.isEmpty)
    }
    
    // MARK: - Test Debug Info
    
    func testDebugInfo_ShouldReturnValidData() {
        // Given
        let profile = BlockingProfile(
            name: "Debug Profile",
            description: "For debugging",
            isTaskConditional: true,
            conditionType: .anyDueToday
        )
        
        taskManager.createTask(
            title: "Debug Task",
            dueDate: Date(),
            category: "Debug",
            priority: .high
        )
        
        // When
        let debugInfo = policyEngine.getDebugInfo(for: profile)
        
        // Then
        XCTAssertEqual(debugInfo["profile"] as? String, "Debug Profile")
        XCTAssertEqual(debugInfo["conditionType"] as? String, "anyDueToday")
        XCTAssertEqual(debugInfo["totalTasks"] as? Int, 1)
        XCTAssertEqual(debugInfo["isTaskConditional"] as? Bool, true)
    }
}
