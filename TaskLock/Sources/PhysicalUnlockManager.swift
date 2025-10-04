import Foundation
import CoreNFC
import AVFoundation
import UIKit

// MARK: - Physical Unlock Manager
public class PhysicalUnlockManager: NSObject, ObservableObject {
    @Published public var isNFCAvailable: Bool = false
    @Published public var isCameraAvailable: Bool = false
    @Published public var lastUnlockAttempt: Date?
    @Published public var unlockStatus: UnlockStatus = .idle
    
    public enum UnlockStatus {
        case idle
        case scanning
        case success
        case failed(String)
    }
    
    public override init() {
        super.init()
        checkAvailability()
    }
    
    private func checkAvailability() {
        isNFCAvailable = NFCNDEFReaderSession.readingAvailable
        isCameraAvailable = AVCaptureDevice.authorizationStatus(for: .video) != .denied
    }
    
    public func startNFCUnlock() {
        guard isNFCAvailable else {
            unlockStatus = .failed("NFC not available on this device")
            return
        }
        unlockStatus = .scanning
    }
    
    public func stopNFCUnlock() {
        unlockStatus = .idle
    }
    
    public func generateUnlockQRCode() -> UIImage? {
        return nil
    }
}

extension PhysicalUnlockManager: NFCNDEFReaderSessionDelegate {
    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.unlockStatus = .failed("NFC error: \(error.localizedDescription)")
        }
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        DispatchQueue.main.async {
            self.unlockStatus = .success
        }
    }
}