import SwiftUI
import Charts

// MARK: - Summary Cards View
struct SummaryCardsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            SummaryCard(
                title: "Focus Time Saved",
                value: "\(appState.analyticsManager.totalFocusTimeSaved / 60)h",
                icon: "clock",
                color: .blue
            )
            
            SummaryCard(
                title: "Tasks Completed",
                value: "\(appState.getCompletedTasks().count)",
                icon: "checkmark.circle",
                color: .green
            )
            
            SummaryCard(
                title: "Completion Rate",
                value: "\(Int(appState.analyticsManager.onTimeCompletionRate * 100))%",
                icon: "chart.line.uptrend.xyaxis",
                color: .orange
            )
            
            SummaryCard(
                title: "Streak Days",
                value: "\(appState.analyticsManager.streakDays)",
                icon: "flame",
                color: .red
            )
        }
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Completion Chart View
struct CompletionChartView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Completion Rate")
                .font(.headline)
            
            if appState.analyticsManager.completionData.isEmpty {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            } else {
                Chart(appState.analyticsManager.getCompletionChartData(), id: \.date) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Rate", data.completionRate)
                    )
                    .foregroundStyle(.blue)
                    
                    AreaMark(
                        x: .value("Date", data.date),
                        y: .value("Rate", data.completionRate)
                    )
                    .foregroundStyle(.blue.opacity(0.2))
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Category Breakdown View
struct CategoryBreakdownView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tasks by Category")
                .font(.headline)
            
            if appState.analyticsManager.categoryBreakdown.isEmpty {
                Text("No categories yet")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            } else {
                Chart(appState.analyticsManager.categoryBreakdown, id: \.category) { data in
                    BarMark(
                        x: .value("Count", data.count),
                        y: .value("Category", data.category)
                    )
                    .foregroundStyle(Color(data.color))
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Focus Time Chart View
struct FocusTimeChartView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Focus Time")
                .font(.headline)
            
            if appState.analyticsManager.focusTimeData.isEmpty {
                Text("No focus time data")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            } else {
                Chart(appState.analyticsManager.getFocusTimeChartData(), id: \.date) { data in
                    BarMark(
                        x: .value("Date", data.date),
                        y: .value("Minutes", data.minutes)
                    )
                    .foregroundStyle(.green)
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Insights View
struct InsightsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.headline)
            
            let insights = appState.analyticsManager.getInsights()
            
            if insights.isEmpty {
                Text("Keep using TaskLock to see insights!")
                    .foregroundColor(.secondary)
            } else {
                ForEach(insights, id: \.self) { insight in
                    HStack(alignment: .top) {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.yellow)
                            .padding(.top, 2)
                        
                        Text(insight)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    SummaryCardsView()
        .environmentObject(AppState())
}
