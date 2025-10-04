import SwiftUI

// MARK: - Blocking Overlay
struct BlockingOverlay: View {
    let profile: BlockingProfile
    let reason: String
    @EnvironmentObject var appState: AppState
    @State private var showingPhysicalUnlock = false
    @State private var showingEmergencyUnlock = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Lock Icon
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                
                // Profile Info
                VStack(spacing: 16) {
                    Text(profile.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(profile.description)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Text(reason)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                
                // Active Tasks Info
                if !appState.getActiveTasks().isEmpty {
                    VStack(spacing: 8) {
                        Text("Active Tasks")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(appState.getActiveTasks().prefix(3), id: \.id) { task in
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundColor(.white.opacity(0.6))
                                Text(task.title)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                            }
                        }
                        
                        if appState.getActiveTasks().count > 3 {
                            Text("+ \(appState.getActiveTasks().count - 3) more tasks")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Unlock Options
                VStack(spacing: 16) {
                    if appState.physicalUnlockManager.isNFCAvailable || appState.physicalUnlockManager.isCameraAvailable {
                        Button("Physical Unlock") {
                            showingPhysicalUnlock = true
                        }
                        .buttonStyle(UnlockButtonStyle())
                    }
                    
                    Button("Emergency Unlock") {
                        showingEmergencyUnlock = true
                    }
                    .buttonStyle(EmergencyButtonStyle())
                }
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showingPhysicalUnlock) {
            PhysicalUnlockView()
        }
        .alert("Emergency Unlock", isPresented: $showingEmergencyUnlock) {
            Button("Cancel", role: .cancel) { }
            Button("Unlock", role: .destructive) {
                appState.emergencyUnlock()
            }
        } message: {
            Text("This will immediately stop all blocking. Are you sure?")
        }
    }
}

// MARK: - Physical Unlock View
struct PhysicalUnlockView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUnlockMethod: UnlockMethod = .nfc
    
    enum UnlockMethod: String, CaseIterable {
        case nfc = "NFC"
        case qr = "QR Code"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Physical Unlock")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Use NFC or QR code to unlock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Picker("Unlock Method", selection: $selectedUnlockMethod) {
                    ForEach(UnlockMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedUnlockMethod == .nfc {
                    NFCUnlockView()
                } else {
                    QRUnlockView()
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - NFC Unlock View
struct NFCUnlockView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wave.3.right")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Hold your iPhone near the NFC tag")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Button("Start NFC Scan") {
                appState.physicalUnlockManager.startNFCUnlock()
            }
            .buttonStyle(UnlockButtonStyle())
            
            if case .scanning = appState.physicalUnlockManager.unlockStatus {
                ProgressView("Scanning...")
                    .padding()
            }
            
            if case .success = appState.physicalUnlockManager.unlockStatus {
                Text("Unlock successful!")
                    .foregroundColor(.green)
                    .font(.headline)
            }
            
            if case .failed(let error) = appState.physicalUnlockManager.unlockStatus {
                Text("Unlock failed: \(error)")
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - QR Unlock View
struct QRUnlockView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            if let qrImage = appState.physicalUnlockManager.qrCodeImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
            
            Text("Scan this QR code with another device")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Button("Start QR Scan") {
                appState.physicalUnlockManager.startQRCodeScanning()
            }
            .buttonStyle(UnlockButtonStyle())
            
            if case .scanning = appState.physicalUnlockManager.unlockStatus {
                ProgressView("Scanning...")
                    .padding()
            }
            
            if case .success = appState.physicalUnlockManager.unlockStatus {
                Text("Unlock successful!")
                    .foregroundColor(.green)
                    .font(.headline)
            }
            
            if case .failed(let error) = appState.physicalUnlockManager.unlockStatus {
                Text("Unlock failed: \(error)")
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Button Styles
struct UnlockButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct EmergencyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    BlockingOverlay(
        profile: BlockingProfile(name: "Focus Mode", description: "Blocks distracting apps"),
        reason: "3 tasks are due today"
    )
    .environmentObject(AppState())
}
