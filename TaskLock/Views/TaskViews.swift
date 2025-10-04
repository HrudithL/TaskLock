import SwiftUI

// MARK: - Stub TaskViews
struct TaskListView: View {
    let tasks: [TaskItem]
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List {
            ForEach(tasks, id: \.id) { task in
                TaskRowView(task: task)
            }
        }
    }
}

#Preview {
    TaskListView(tasks: [])
        .environmentObject(AppState())
}