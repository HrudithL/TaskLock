import Foundation
import SwiftUI

// MARK: - Stub PhysicalUnlockManager
public class PhysicalUnlockManager: ObservableObject {
    @Published public var isNFCEnabled: Bool = false
    @Published public var isQREnabled: Bool = false
    
    public init() {}
    
    public func startNFCScanning() {
        // Stub implementation
        isNFCEnabled = true
    }
    
    public func stopNFCScanning() {
        // Stub implementation
        isNFCEnabled = false
    }
    
    public func generateQRCode() -> String {
        // Stub implementation
        return "EMERGENCY_UNLOCK_QR_CODE"
    }
}