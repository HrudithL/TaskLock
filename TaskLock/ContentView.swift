import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        if appState.isLoading {
            LoadingView()
        } else {
            MainTabView()
                .environmentObject(appState)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading TaskLock...")
                .font(.headline)
                .padding(.top)
        }
    }
}

#Preview {
    ContentView()
}