import Foundation
import CoreNFC
import AVFoundation
import UIKit
import Combine

// MARK: - Unlock Status
public enum UnlockStatus {
    case idle
    case scanning
    case success
    case failed(String)
}

// MARK: - Physical Unlock Manager
public class PhysicalUnlockManager: NSObject, ObservableObject {
    @Published public var isNFCAvailable: Bool = false
    @Published public var isCameraAvailable: Bool = false
    @Published public var lastUnlockAttempt: Date?
    @Published public var unlockStatus: UnlockStatus = .idle
    @Published public var qrCodeImage: UIImage?
    
    private var nfcSession: NFCNDEFReaderSession?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    public override init() {
        super.init()
        checkAvailability()
        generateQRCode()
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
        
        unlockStatus = .scanning
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        nfcSession?.alertMessage = "Hold your iPhone near the NFC tag to unlock"
        nfcSession?.begin()
    }
    
    public func stopNFCUnlock() {
        nfcSession?.invalidate()
        nfcSession = nil
        unlockStatus = .idle
    }
    
    // MARK: - QR Code Unlock
    
    public func generateQRCode() {
        let unlockData = generateUnlockData()
        qrCodeImage = createQRCode(from: unlockData)
    }
    
    private func generateUnlockData() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let data = "tasklock:unlock:\(deviceId):\(timestamp)"
        return data
    }
    
    private func createQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        
        let context = CIContext()
        let filter = CIFilter(name: "CIQRCodeGenerator")!
        filter.setValue(data, forKey: "inputMessage")
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scaleX = 200 / outputImage.extent.size.width
        let scaleY = 200 / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    public func startQRCodeScanning() {
        guard isCameraAvailable else {
            unlockStatus = .failed("Camera not available")
            return
        }
        
        unlockStatus = .scanning
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else { return }
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            unlockStatus = .failed("Camera setup failed")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            unlockStatus = .failed("Cannot add video input")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            unlockStatus = .failed("Cannot add metadata output")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        
        captureSession.startRunning()
    }
    
    public func stopQRCodeScanning() {
        captureSession?.stopRunning()
        captureSession = nil
        previewLayer = nil
        unlockStatus = .idle
    }
    
    // MARK: - Unlock Validation
    
    private func validateUnlockData(_ data: String) -> Bool {
        let components = data.components(separatedBy: ":")
        guard components.count == 4,
              components[0] == "tasklock",
              components[1] == "unlock" else {
            return false
        }
        
        let deviceId = components[2]
        let timestamp = Int(components[3]) ?? 0
        
        // Check if it's for this device
        let currentDeviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        guard deviceId == currentDeviceId else { return false }
        
        // Check if timestamp is recent (within 5 minutes)
        let currentTime = Int(Date().timeIntervalSince1970)
        let timeDifference = currentTime - timestamp
        guard timeDifference <= 300 else { return false } // 5 minutes
        
        return true
    }
    
    private func handleSuccessfulUnlock() {
        DispatchQueue.main.async {
            self.unlockStatus = .success
            self.lastUnlockAttempt = Date()
        }
        
        // Notify that unlock was successful
        NotificationCenter.default.post(name: .physicalUnlockSuccess, object: nil)
        
        // Reset status after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.unlockStatus = .idle
        }
    }
}

// MARK: - NFCNDEFReaderSessionDelegate
extension PhysicalUnlockManager: NFCNDEFReaderSessionDelegate {
    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            if let nfcError = error as? NFCReaderError {
                switch nfcError.code {
                case .readerSessionInvalidationErrorUserCanceled:
                    self.unlockStatus = .idle
                default:
                    self.unlockStatus = .failed("NFC error: \(error.localizedDescription)")
                }
            } else {
                self.unlockStatus = .failed("NFC error: \(error.localizedDescription)")
            }
        }
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            for record in message.records {
                if let payload = String(data: record.payload, encoding: .utf8) {
                    if validateUnlockData(payload) {
                        handleSuccessfulUnlock()
                        return
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.unlockStatus = .failed("Invalid NFC tag")
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension PhysicalUnlockManager: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            if validateUnlockData(stringValue) {
                stopQRCodeScanning()
                handleSuccessfulUnlock()
            } else {
                DispatchQueue.main.async {
                    self.unlockStatus = .failed("Invalid QR code")
                }
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let physicalUnlockSuccess = Notification.Name("physicalUnlockSuccess")
}
