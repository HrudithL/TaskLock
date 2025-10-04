import SwiftUI

// MARK: - Add Task View
struct AddTaskView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var selectedCategory: Category?
    @State private var priority: TaskPriority = .medium
    @State private var estimateMinutes: Int32 = 30
    @State private var reminders: [Date] = []
    @State private var showingPresets = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task title", text: $title)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("No Category").tag(nil as Category?)
                        ForEach(appState.categories, id: \.id) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(Color(category.color))
                                Text(category.name)
                            }
                            .tag(category as Category?)
                        }
                    }
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(Color(priority.color))
                                    .frame(width: 12, height: 12)
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Estimate") {
                    Stepper("\(estimateMinutes) minutes", value: $estimateMinutes, in: 5...480, step: 5)
                }
                
                Section("Quick Add") {
                    Button("Use Preset") {
                        showingPresets = true
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingPresets) {
                PresetSelectionView { preset in
                    applyPreset(preset)
                }
            }
        }
    }
    
    private func saveTask() {
        appState.createTask(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            dueDate: hasDueDate ? dueDate : nil,
            reminders: reminders,
            category: selectedCategory,
            priority: priority,
            estimateMinutes: estimateMinutes
        )
        dismiss()
    }
    
    private func applyPreset(_ preset: TaskPreset) {
        title = preset.title
        notes = preset.notes ?? ""
        priority = preset.priority
        estimateMinutes = preset.estimateMinutes
        
        if let category = appState.categories.first(where: { $0.name == preset.category }) {
            selectedCategory = category
        }
    }
}

// MARK: - Edit Task View
struct EditTaskView: View {
    var task: TaskItem
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var notes: String
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var selectedCategory: Category?
    @State private var priority: TaskPriority
    @State private var estimateMinutes: Int32
    
    init(task: Task) {
        self.task = task
        self._title = State(initialValue: task.title)
        self._notes = State(initialValue: task.notes ?? "")
        self._dueDate = State(initialValue: task.dueDate ?? Date())
        self._hasDueDate = State(initialValue: task.dueDate != nil)
        self._selectedCategory = State(initialValue: appState.categories.first { $0.name == task.categoryName })
        self._priority = State(initialValue: task.priority)
        self._estimateMinutes = State(initialValue: task.estimateMinutes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task title", text: $title)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("No Category").tag(nil as Category?)
                        ForEach(appState.categories, id: \.id) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(Color(category.color))
                                Text(category.name)
                            }
                            .tag(category as Category?)
                        }
                    }
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(Color(priority.color))
                                    .frame(width: 12, height: 12)
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Estimate") {
                    Stepper("\(estimateMinutes) minutes", value: $estimateMinutes, in: 5...480, step: 5)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveTask() {
        var updatedTask = task
        updatedTask.title = title
        updatedTask.notes = notes.isEmpty ? nil : notes
        updatedTask.dueDate = hasDueDate ? dueDate : nil
        updatedTask.categoryName = selectedCategory?.name
        updatedTask.priority = priority
        updatedTask.estimateMinutes = estimateMinutes
        
        appState.updateTask(updatedTask)
        dismiss()
    }
}

// MARK: - Preset Selection View
struct PresetSelectionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let onPresetSelected: (TaskPreset) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(appState.presets, id: \.id) { preset in
                    Button(action: {
                        onPresetSelected(preset)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(preset.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if let notes = preset.notes {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    PriorityBadge(priority: preset.priority)
                                    Text("\(preset.estimateMinutes) min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Preset")
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

#Preview {
    AddTaskView()
        .environmentObject(AppState())
}
