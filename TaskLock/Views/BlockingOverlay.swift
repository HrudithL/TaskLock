import SwiftUI

// MARK: - Stub BlockingOverlay
struct BlockingOverlay: View {
    let profile: BlockingProfile
    let reason: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                
                Text("TaskLock Active")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(profile.name)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(reason)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Emergency Unlock") {
                    // Emergency unlock
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
            }
        }
    }
}

#Preview {
    BlockingOverlay(
        profile: BlockingProfile(name: "Work Focus", description: "Block distracting apps"),
        reason: "You have incomplete tasks due today"
    )
}