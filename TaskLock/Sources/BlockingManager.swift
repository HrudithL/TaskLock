import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine

// MARK: - Blocking Profile
public struct BlockingProfile: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let isTaskConditional: Bool
    public let conditionType: BlockingCondition
    public let gracePeriodMinutes: Int
    public let completionPolicy: CompletionPolicy
    public let allowedApps: [String]
    public let isStrictMode: Bool
    public let requiresPhysicalUnlock: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        isTaskConditional: Bool = false,
        conditionType: BlockingCondition = .anyDueToday,
        gracePeriodMinutes: Int = 0,
        completionPolicy: CompletionPolicy = .currentTaskDone,
        allowedApps: [String] = [],
        isStrictMode: Bool = false,
        requiresPhysicalUnlock: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isTaskConditional = isTaskConditional
        self.conditionType = conditionType
        self.gracePeriodMinutes = gracePeriodMinutes
        self.completionPolicy = completionPolicy
        self.allowedApps = allowedApps
        self.isStrictMode = isStrictMode
        self.requiresPhysicalUnlock = requiresPhysicalUnlock
    }
}

// MARK: - Blocking Condition
public enum BlockingCondition: String, CaseIterable, Codable {
    case anyDueToday = "anyDueToday"
    case allDueToday = "allDueToday"
    case onlyHighPriorityDueToday = "onlyHighPriorityDueToday"
    case activeTaskOnly = "activeTaskOnly"
    
    public var displayName: String {
        switch self {
        case .anyDueToday: return "Any Due Today"
        case .allDueToday: return "All Due Today"
        case .onlyHighPriorityDueToday: return "Only High Priority Due Today"
        case .activeTaskOnly: return "Active Task Only"
        }
    }
}

// MARK: - Completion Policy
public enum CompletionPolicy: String, CaseIterable, Codable {
    case currentTaskDone = "currentTaskDone"
    case allTriggeringTasksDone = "allTriggeringTasksDone"
    
    public var displayName: String {
        switch self {
        case .currentTaskDone: return "Current Task Done"
        case .allTriggeringTasksDone: return "All Triggering Tasks Done"
        }
    }
}

// MARK: - Blocking Status
public enum BlockingStatus {
    case inactive
    case active(profile: BlockingProfile, reason: String)
    case error(String)
}

// MARK: - Blocking Manager
public class BlockingManager: ObservableObject {
    @Published public var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published public var currentStatus: BlockingStatus = .inactive
    @Published public var isBlocking: Bool = false
    
    private let store = ManagedSettingsStore()
    private let deviceActivityCenter = DeviceActivityCenter()
    private var currentProfile: BlockingProfile?
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    public func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        await MainActor.run {
            checkAuthorizationStatus()
        }
    }
    
    private func checkAuthorizationStatus() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }
    
    public var isAuthorized: Bool {
        authorizationStatus == .approved
    }
    
    // MARK: - Blocking Operations
    
    public func startBlocking(profile: BlockingProfile) async {
        guard isAuthorized else {
            await MainActor.run {
                currentStatus = .error("Family Controls authorization required")
            }
            return
        }
        
        await MainActor.run {
            currentProfile = profile
            isBlocking = true
            currentStatus = .active(profile: profile, reason: "Task-conditional blocking active")
        }
        
        // Configure blocking settings
        configureBlockingSettings(for: profile)
        
        // Start device activity monitoring
        await startDeviceActivityMonitoring(for: profile)
    }
    
    public func stopBlocking() async {
        await MainActor.run {
            currentProfile = nil
            isBlocking = false
            currentStatus = .inactive
        }
        
        // Clear blocking settings
        clearBlockingSettings()
        
        // Stop device activity monitoring
        await stopDeviceActivityMonitoring()
    }
    
    // MARK: - Settings Configuration
    
    private func configureBlockingSettings(for profile: BlockingProfile) {
        // Configure application blocking
        store.shield.applications = ShieldSettings.ApplicationsPolicy.all
        store.shield.applicationCategories = ShieldSettings.CategoryPolicy.all
        
        // Configure web content blocking
        store.shield.webContent = ShieldSettings.WebContentPolicy.all
        
        // Configure allowed apps if specified
        if !profile.allowedApps.isEmpty {
            // Note: In a real implementation, you would need to map app identifiers
            // to ApplicationTokens from FamilyControls
            // This is a simplified version
        }
    }
    
    private func clearBlockingSettings() {
        store.shield.applications = ShieldSettings.ApplicationsPolicy.none
        store.shield.applicationCategories = ShieldSettings.CategoryPolicy.none
        store.shield.webContent = ShieldSettings.WebContentPolicy.none
    }
    
    // MARK: - Device Activity Monitoring
    
    private func startDeviceActivityMonitoring(for profile: BlockingProfile) async {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let activityName = DeviceActivityName("TaskBlocking-\(profile.id.uuidString)")
        
        do {
            try await deviceActivityCenter.startMonitoring(activityName, during: schedule)
        } catch {
            await MainActor.run {
                currentStatus = .error("Failed to start device activity monitoring: \(error.localizedDescription)")
            }
        }
    }
    
    private func stopDeviceActivityMonitoring() async {
        let activityName = DeviceActivityName("TaskBlocking-\(currentProfile?.id.uuidString ?? "")")
        
        do {
            try await deviceActivityCenter.stopMonitoring([activityName])
        } catch {
            print("Error stopping device activity monitoring: \(error)")
        }
    }
    
    // MARK: - Profile Management
    
    public func createDefaultProfiles() -> [BlockingProfile] {
        return [
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
            )
        ]
    }
    
    // MARK: - Physical Unlock Support
    
    public func handlePhysicalUnlock() async {
        guard let profile = currentProfile,
              profile.requiresPhysicalUnlock else {
            return
        }
        
        // In a real implementation, this would verify NFC/QR code
        // For now, we'll just stop blocking
        await stopBlocking()
    }
    
    // MARK: - Strict Mode
    
    public func canDisableBlocking() -> Bool {
        guard let profile = currentProfile else { return true }
        return !profile.isStrictMode
    }
    
    public func attemptDisableBlocking() async -> Bool {
        if canDisableBlocking() {
            await stopBlocking()
            return true
        } else {
            await MainActor.run {
                currentStatus = .error("Strict mode is enabled. Physical unlock required.")
            }
            return false
        }
    }
}
