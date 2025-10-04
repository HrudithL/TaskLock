import Foundation
import Combine

// MARK: - Blocking Profile
public struct BlockingProfile: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let isTaskConditional: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        isTaskConditional: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isTaskConditional = isTaskConditional
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
    
    public init() {
        // Initialize
    }
    
    public func createDefaultProfiles() -> [BlockingProfile] {
        return [
            BlockingProfile(
                name: "Focus Mode",
                description: "Blocks distracting apps during focus sessions",
                isTaskConditional: true
            ),
            BlockingProfile(
                name: "Study Mode",
                description: "Blocks all non-essential apps during study time",
                isTaskConditional: true
            )
        ]
    }
}