import SwiftUI

// MARK: - Blocking Settings View
struct BlockingSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingBlockingProfiles = false
    @State private var showingEmergencyUnlock = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Status")
                Spacer()
                Text(appState.isBlocking ? "Active" : "Inactive")
                    .foregroundColor(appState.isBlocking ? .red : .green)
            }
            
            if appState.isBlocking {
                if case .active(let profile, let reason) = appState.currentBlockingStatus {
                    HStack {
                        Text("Profile")
                        Spacer()
                        Text(profile.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Reason")
                        Spacer()
                        Text(reason)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button("Manage Profiles") {
                showingBlockingProfiles = true
            }
            
            if appState.isBlocking {
                Button("Emergency Unlock") {
                    showingEmergencyUnlock = true
                }
                .foregroundColor(.red)
            }
        }
        .sheet(isPresented: $showingBlockingProfiles) {
            BlockingProfilesView()
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

// MARK: - Blocking Profiles View
struct BlockingProfilesView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(appState.blockingProfiles, id: \.id) { profile in
                    BlockingProfileRowView(profile: profile)
                }
            }
            .navigationTitle("Blocking Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Blocking Profile Row View
struct BlockingProfileRowView: View {
    let profile: BlockingProfile
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(profile.name)
                    .font(.headline)
                
                Text(profile.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if profile.isTaskConditional {
                    Label("Task-Conditional", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Button(appState.isBlocking ? "Stop" : "Start") {
                if appState.isBlocking {
                    appState.stopBlocking()
                } else {
                    appState.startBlocking(profile: profile)
                }
            }
            .buttonStyle(.bordered)
            .foregroundColor(appState.isBlocking ? .red : .blue)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var notificationsEnabled = true
    @State private var reminderTime = Date()
    
    var body: some View {
        VStack {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
            
            if notificationsEnabled {
                DatePicker("Default Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
            }
        }
    }
}

// MARK: - Data Settings View
struct DataSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingExportOptions = false
    @State private var showingResetAlert = false
    
    var body: some View {
        VStack {
            Button("Export Data") {
                showingExportOptions = true
            }
            
            Button("Reset All Data") {
                showingResetAlert = true
            }
            .foregroundColor(.red)
        }
        .actionSheet(isPresented: $showingExportOptions) {
            ActionSheet(
                title: Text("Export Data"),
                buttons: [
                    .default(Text("Export Tasks (CSV)")) {
                        exportTasks()
                    },
                    .default(Text("Export Analytics (CSV)")) {
                        exportAnalytics()
                    },
                    .cancel()
                ]
            )
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will permanently delete all tasks, categories, and analytics data. This action cannot be undone.")
        }
    }
    
    private func exportTasks() {
        // Implementation for exporting tasks
    }
    
    private func exportAnalytics() {
        // Implementation for exporting analytics
    }
    
    private func resetAllData() {
        // Implementation for resetting all data
    }
}

// MARK: - About Settings View
struct AboutSettingsView: View {
    var body: some View {
        VStack {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Build")
                Spacer()
                Text("1")
                    .foregroundColor(.secondary)
            }
            
            Button("Privacy Policy") {
                // Open privacy policy
            }
            
            Button("Terms of Service") {
                // Open terms of service
            }
        }
    }
}

#Preview {
    BlockingSettingsView()
        .environmentObject(AppState())
}
