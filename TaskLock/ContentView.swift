import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "lock.shield")
                .font(.system(size: 100))
                .foregroundColor(.blue)
            
            Text("TaskLock")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Task-driven blocking app")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Build Test - v1.1 - Simplified")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}