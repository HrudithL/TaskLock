import SwiftUI

// MARK: - Stub AnalyticsViews
struct SummaryCardsView: View {
    var body: some View {
        VStack {
            Text("Summary Cards")
                .font(.headline)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CompletionChartView: View {
    var body: some View {
        VStack {
            Text("Completion Chart")
                .font(.headline)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CategoryBreakdownView: View {
    var body: some View {
        VStack {
            Text("Category Breakdown")
                .font(.headline)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FocusTimeChartView: View {
    var body: some View {
        VStack {
            Text("Focus Time Chart")
                .font(.headline)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct InsightsView: View {
    var body: some View {
        VStack {
            Text("Insights")
                .font(.headline)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    VStack {
        SummaryCardsView()
        CompletionChartView()
        CategoryBreakdownView()
        FocusTimeChartView()
        InsightsView()
    }
}