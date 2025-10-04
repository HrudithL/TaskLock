import SwiftUI

// MARK: - Stub SettingsViews
struct BlockingSettingsView: View {
    var body: some View {
        VStack {
            Text("Blocking Settings")
                .font(.headline)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        VStack {
            Text("Notification Settings")
                .font(.headline)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DataSettingsView: View {
    var body: some View {
        VStack {
            Text("Data Settings")
                .font(.headline)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack {
            Text("About TaskLock")
                .font(.headline)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    VStack {
        BlockingSettingsView()
        NotificationSettingsView()
        DataSettingsView()
        AboutSettingsView()
    }
}