import SwiftUI
import Foundation

// MARK: - Main Tab View
struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Today")
                }
            
            UpcomingView()
                .tabItem {
                    Image(systemName: "calendar.badge.clock")
                    Text("Upcoming")
                }
            
            CategoriesView()
                .tabItem {
                    Image(systemName: "folder")
                    Text("Categories")
                }
            
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Stats")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}

// MARK: - Today View
struct TodayView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Today")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Task management coming soon...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Today")
        }
    }
}

// MARK: - Upcoming View
struct UpcomingView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Upcoming")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Upcoming tasks view coming soon...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Upcoming")
        }
    }
}

// MARK: - Categories View
struct CategoriesView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Categories")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Categories view coming soon...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Categories")
        }
    }
}

// MARK: - Stats View
struct StatsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Statistics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Analytics view coming soon...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Statistics")
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Settings view coming soon...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    MainTabView()
}