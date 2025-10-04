import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("TaskLock")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Task-driven app blocking")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            
            Text("Version 1.0")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}