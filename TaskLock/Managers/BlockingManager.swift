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
    public let allowedApps: Set<String>
    public let gracePeriodMinutes: Int
    public let strictMode: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        isTaskConditional: Bool = false,
        allowedApps: Set<String> = [],
        gracePeriodMinutes: Int = 0,
        strictMode: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isTaskConditional = isTaskConditional
        self.allowedApps = allowedApps
        self.gracePeriodMinutes = gracePeriodMinutes
        self.strictMode = strictMode
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
    @Published public var currentStatus: BlockingStatus = .inactive
    @Published public var isBlocking: Bool = false
    @Published public var isAuthorized: Bool = false
    @Published public var selectedApps: Set<ApplicationToken> = []
    
    private let managedSettingsStore = ManagedSettingsStore()
    private let deviceActivityCenter = DeviceActivityCenter()
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        checkAuthorizationStatus()
        setupNotificationObservers()
    }
    
    // MARK: - Authorization
    
    public func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            await MainActor.run {
                self.isAuthorized = true
            }
        } catch {
            await MainActor.run {
                self.isAuthorized = false
                self.currentStatus = .error("Authorization failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }
    
    // MARK: - Blocking Operations
    
    public func startBlocking(profile: BlockingProfile) {
        guard isAuthorized else {
            currentStatus = .error("Not authorized for Family Controls")
            return
        }
        
        Task {
            await MainActor.run {
                self.currentStatus = .active(profile: profile, reason: "Blocking activated")
                self.isBlocking = true
            }
            
            // Configure managed settings
            configureManagedSettings(for: profile)
            
            // Start device activity monitoring
            startDeviceActivityMonitoring(for: profile)
        }
    }
    
    public func stopBlocking() {
        Task {
            await MainActor.run {
                self.currentStatus = .inactive
                self.isBlocking = false
            }
            
            // Clear managed settings
            clearManagedSettings()
            
            // Stop device activity monitoring
            stopDeviceActivityMonitoring()
        }
    }
    
    // MARK: - Managed Settings Configuration
    
    private func configureManagedSettings(for profile: BlockingProfile) {
        // Block all apps except allowed ones
        if !profile.allowedApps.isEmpty {
            let blockedApps = ApplicationToken.all.filter { app in
                !profile.allowedApps.contains(app.localizedDisplayName ?? "")
            }
            managedSettingsStore.application.blockedApplications = Set(blockedApps)
        } else {
            managedSettingsStore.application.blockedApplications = Set(ApplicationToken.all)
        }
        
        // Block websites if needed
        managedSettingsStore.webContent.blockedByFilter = .all
        
        // Block app installation
        managedSettingsStore.application.denyAppInstallation = true
        
        // Block app removal
        managedSettingsStore.application.denyAppRemoval = true
    }
    
    private func clearManagedSettings() {
        managedSettingsStore.application.blockedApplications = Set()
        managedSettingsStore.webContent.blockedByFilter = .none
        managedSettingsStore.application.denyAppInstallation = false
        managedSettingsStore.application.denyAppRemoval = false
    }
    
    // MARK: - Device Activity Monitoring
    
    private func startDeviceActivityMonitoring(for profile: BlockingProfile) {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let activityName = DeviceActivityName("TaskLockBlocking")
        
        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule)
        } catch {
            print("Error starting device activity monitoring: \(error)")
        }
    }
    
    private func stopDeviceActivityMonitoring() {
        let activityName = DeviceActivityName("TaskLockBlocking")
        deviceActivityCenter.stopMonitoring([activityName])
    }
    
    // MARK: - App Selection
    
    public func selectApps(_ apps: Set<ApplicationToken>) {
        selectedApps = apps
    }
    
    public func getAllApps() -> [ApplicationToken] {
        return ApplicationToken.all
    }
    
    // MARK: - Default Profiles
    
    public func createDefaultProfiles() -> [BlockingProfile] {
        return [
            BlockingProfile(
                name: "Focus Mode",
                description: "Blocks distracting apps during focus sessions",
                isTaskConditional: true,
                allowedApps: ["Messages", "Phone", "Settings"],
                gracePeriodMinutes: 5,
                strictMode: false
            ),
            BlockingProfile(
                name: "Study Mode",
                description: "Blocks all non-essential apps during study time",
                isTaskConditional: true,
                allowedApps: ["Safari", "Notes", "Calculator"],
                gracePeriodMinutes: 0,
                strictMode: true
            ),
            BlockingProfile(
                name: "Work Mode",
                description: "Blocks social media and entertainment apps",
                isTaskConditional: true,
                allowedApps: ["Mail", "Calendar", "Safari", "Messages"],
                gracePeriodMinutes: 10,
                strictMode: false
            )
        ]
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .taskCompletedFromNotification)
            .sink { [weak self] notification in
                // Handle task completion - potentially stop blocking
                self?.handleTaskCompletion()
            }
            .store(in: &cancellables)
    }
    
    private func handleTaskCompletion() {
        // Check if all tasks are completed and stop blocking if needed
        // This would integrate with the PolicyEngine
    }
}
