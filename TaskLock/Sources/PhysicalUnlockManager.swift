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
    
    private var nfcSession: NFCNDEFReaderSession?
    private var qrCaptureSession: AVCaptureSession?
    private var qrPreviewLayer: AVCaptureVideoPreviewLayer?
    
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
    
    // MARK: - Availability Check
    
    private func checkAvailability() {
        isNFCAvailable = NFCNDEFReaderSession.readingAvailable
        isCameraAvailable = AVCaptureDevice.authorizationStatus(for: .video) != .denied
    }
    
    // MARK: - NFC Unlock
    
    public func startNFCUnlock() {
        guard isNFCAvailable else {
            unlockStatus = .failed("NFC not available on this device")
            return
        }
        
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        nfcSession?.alertMessage = "Hold your device near the NFC tag to unlock"
        nfcSession?.begin()
        
        unlockStatus = .scanning
    }
    
    public func stopNFCUnlock() {
        nfcSession?.invalidate()
        nfcSession = nil
        unlockStatus = .idle
    }
    
    // MARK: - QR Code Unlock
    
    public func startQRUnlock() -> AVCaptureVideoPreviewLayer? {
        guard isCameraAvailable else {
            unlockStatus = .failed("Camera not available")
            return nil
        }
        
        qrCaptureSession = AVCaptureSession()
        
        guard let captureSession = qrCaptureSession else {
            unlockStatus = .failed("Failed to create capture session")
            return nil
        }
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            unlockStatus = .failed("No video capture device available")
            return nil
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                unlockStatus = .failed("Cannot add video input")
                return nil
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                unlockStatus = .failed("Cannot add metadata output")
                return nil
            }
            
            qrPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            qrPreviewLayer?.videoGravity = .resizeAspectFill
            
            captureSession.startRunning()
            unlockStatus = .scanning
            
            return qrPreviewLayer
        } catch {
            unlockStatus = .failed("Error setting up camera: \(error.localizedDescription)")
            return nil
        }
    }
    
    public func stopQRUnlock() {
        qrCaptureSession?.stopRunning()
        qrCaptureSession = nil
        qrPreviewLayer = nil
        unlockStatus = .idle
    }
    
    // MARK: - Unlock Validation
    
    private func validateUnlockCode(_ code: String) -> Bool {
        // In a real implementation, this would validate against stored codes
        // For demo purposes, we'll accept any code that starts with "UNLOCK"
        return code.hasPrefix("UNLOCK")
    }
    
    private func processUnlockCode(_ code: String) {
        lastUnlockAttempt = Date()
        
        if validateUnlockCode(code) {
            unlockStatus = .success
            // Notify the blocking manager that physical unlock was successful
            NotificationCenter.default.post(name: .physicalUnlockSuccess, object: nil)
        } else {
            unlockStatus = .failed("Invalid unlock code")
        }
    }
    
    // MARK: - Generate QR Code
    
    public func generateUnlockQRCode() -> UIImage? {
        let unlockCode = "UNLOCK-\(UUID().uuidString.prefix(8))"
        
        guard let data = unlockCode.data(using: .utf8) else { return nil }
        
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let ciImage = filter?.outputImage else { return nil }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - NFC Delegate
extension PhysicalUnlockManager: NFCNDEFReaderSessionDelegate {
    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            if let nfcError = error as? NFCReaderError {
                switch nfcError.code {
                case .readerSessionInvalidationErrorUserCanceled:
                    self.unlockStatus = .idle
                case .readerSessionInvalidationErrorSessionTimeout:
                    self.unlockStatus = .failed("NFC session timed out")
                default:
                    self.unlockStatus = .failed("NFC error: \(nfcError.localizedDescription)")
                }
            } else {
                self.unlockStatus = .failed("NFC error: \(error.localizedDescription)")
            }
        }
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        DispatchQueue.main.async {
            guard let message = messages.first,
                  let payload = message.records.first?.payload,
                  let code = String(data: payload, encoding: .utf8) else {
                self.unlockStatus = .failed("Invalid NFC data")
                return
            }
            
            self.processUnlockCode(code)
        }
    }
}

// MARK: - QR Code Delegate
extension PhysicalUnlockManager: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let code = readableObject.stringValue else {
            return
        }
        
        processUnlockCode(code)
        stopQRUnlock()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let physicalUnlockSuccess = Notification.Name("physicalUnlockSuccess")
}

// MARK: - Strict Mode Manager
public class StrictModeManager: ObservableObject {
    @Published public var isStrictModeEnabled: Bool = false
    @Published public var requiresPhysicalUnlock: Bool = false
    @Published public var strictModeStartTime: Date?
    @Published public var strictModeReason: String = ""
    
    private var physicalUnlockManager = PhysicalUnlockManager()
    
    public init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePhysicalUnlockSuccess),
            name: .physicalUnlockSuccess,
            object: nil
        )
    }
    
    @objc private func handlePhysicalUnlockSuccess() {
        if isStrictModeEnabled {
            disableStrictMode()
        }
    }
    
    public func enableStrictMode(reason: String, requiresPhysicalUnlock: Bool = true) {
        isStrictModeEnabled = true
        self.requiresPhysicalUnlock = requiresPhysicalUnlock
        strictModeStartTime = Date()
        strictModeReason = reason
    }
    
    public func disableStrictMode() {
        isStrictModeEnabled = false
        requiresPhysicalUnlock = false
        strictModeStartTime = nil
        strictModeReason = ""
    }
    
    public func canDisableBlocking() -> Bool {
        return !isStrictModeEnabled
    }
    
    public func attemptDisableBlocking() -> Bool {
        if canDisableBlocking() {
            return true
        } else if requiresPhysicalUnlock {
            // Start physical unlock process
            if physicalUnlockManager.isNFCAvailable {
                physicalUnlockManager.startNFCUnlock()
            } else if physicalUnlockManager.isCameraAvailable {
                _ = physicalUnlockManager.startQRUnlock()
            } else {
                return false
            }
            return false
        } else {
            return false
        }
    }
    
    public func getStrictModeDuration() -> TimeInterval? {
        guard let startTime = strictModeStartTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }
    
    public func getStrictModeDurationString() -> String? {
        guard let duration = getStrictModeDuration() else { return nil }
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
