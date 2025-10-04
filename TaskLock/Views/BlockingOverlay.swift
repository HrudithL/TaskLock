import SwiftUI

// MARK: - Blocking Overlay View
struct BlockingOverlay: View {
    let profile: BlockingProfile
    let reason: String
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                
                VStack(spacing: 16) {
                    Text("Focus Mode Active")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(profile.name)
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(reason)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 12) {
                    Button("Complete Tasks to Unlock") {
                        // This would navigate to tasks
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Emergency Unlock") {
                        // This would show emergency unlock options
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    BlockingOverlay(
        profile: BlockingProfile(
            name: "Focus Mode",
            description: "Blocks distracting apps"
        ),
        reason: "You have incomplete tasks due today"
    )
    .environmentObject(AppState())
}