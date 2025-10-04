# TaskLock Project Structure

This document outlines the complete project structure for the TaskLock iOS app.

## Project Overview

TaskLock is a modular iOS app built with SwiftUI that combines task management with intelligent app blocking using Apple's Family Controls framework.

## Directory Structure

```
TaskLock/
├── TaskLock.xcodeproj/              # Xcode project file
├── TaskLock/                        # Main app target
│   ├── TaskLockApp.swift           # App entry point
│   ├── ContentView.swift           # Main content view
│   ├── Info.plist                  # App configuration
│   ├── TaskLock.entitlements       # App entitlements
│   └── Assets.xcassets/           # App assets
├── TasksKit/                       # CoreData and task management
│   ├── Models.swift                # CoreData models
│   ├── TaskManager.swift           # Task CRUD operations
│   ├── PersistenceController.swift # CoreData stack
│   └── TaskLockModel.xcdatamodeld/ # CoreData model
├── BlockingKit/                    # FamilyControls integration
│   └── BlockingManager.swift       # Blocking operations
├── PolicyEngine/                   # Task-conditional blocking logic
│   └── PolicyEngine.swift          # Policy evaluation
├── PolicyEngineTests/              # Unit tests
│   └── PolicyEngineTests.swift     # Policy engine tests
├── AppState/                       # State management
│   └── AppState.swift              # ObservableObject coordinator
├── AnalyticsKit/                  # Data aggregation and charts
│   └── AnalyticsManager.swift      # Analytics operations
├── AppUI/                          # SwiftUI views
│   └── Views.swift                 # All SwiftUI views
├── PhysicalUnlock/                 # NFC/QR integration
│   └── PhysicalUnlockManager.swift # Physical unlock
├── NotificationManager/            # Local notifications
│   └── NotificationManager.swift   # Notification handling
├── SampleData/                     # Sample data seeder
│   └── SampleDataSeeder.swift      # Data seeding
└── README.md                       # Project documentation
```

## Module Descriptions

### TaskLock (Main App)
- **TaskLockApp.swift**: SwiftUI app entry point with CoreData environment
- **ContentView.swift**: Main content view that loads the tab interface
- **Info.plist**: App configuration with required permissions
- **TaskLock.entitlements**: Family Controls and Device Activity entitlements

### TasksKit
Core task management functionality:
- **Models.swift**: CoreData entities (Task, Category, TaskPreset, DailyAggregate)
- **TaskManager.swift**: CRUD operations, reminder scheduling, data fetching
- **PersistenceController.swift**: CoreData stack with in-memory option for testing
- **TaskLockModel.xcdatamodeld**: CoreData model definition

### BlockingKit
Family Controls framework integration:
- **BlockingManager.swift**: Screen Time API wrapper, profile management, authorization

### PolicyEngine
Task-conditional blocking logic:
- **PolicyEngine.swift**: Policy evaluation, condition checking, grace period handling
- **PolicyEngineTests.swift**: Comprehensive unit tests for edge cases

### AppState
Centralized state management:
- **AppState.swift**: ObservableObject coordinating all app state, task changes, and blocking

### AnalyticsKit
Data aggregation and visualization:
- **AnalyticsManager.swift**: Statistics calculation, chart data generation, CSV export

### AppUI
SwiftUI user interface:
- **Views.swift**: All SwiftUI views including Today, Upcoming, Categories, Stats, Settings

### PhysicalUnlock
Emergency access functionality:
- **PhysicalUnlockManager.swift**: NFC and QR code scanning for emergency unlock

### NotificationManager
Local notification handling:
- **NotificationManager.swift**: Task reminders, blocking notifications, user actions

### SampleData
Development and demo data:
- **SampleDataSeeder.swift**: Sample tasks, categories, presets for testing

## Key Features Implementation

### Task Management
- Complete CRUD operations with CoreData
- Categories with colors and icons
- Task presets for quick creation
- Local notifications with actions
- Due date and priority handling

### Blocking System
- Family Controls framework integration
- Multiple blocking conditions
- Grace periods and completion policies
- Profile management
- Strict mode with physical unlock

### Analytics
- Daily task completion tracking
- Focus time estimation
- Category breakdown
- Activity heatmap
- CSV export functionality

### User Interface
- Tab-based navigation
- SwiftUI with Charts framework
- Dark/light mode support
- Accessibility features
- Empty states and loading indicators

## Dependencies

### Apple Frameworks
- **FamilyControls**: App blocking functionality
- **ManagedSettings**: Screen Time settings management
- **DeviceActivity**: Device activity monitoring
- **UserNotifications**: Local notifications
- **CoreData**: Data persistence
- **CoreNFC**: NFC tag reading
- **AVFoundation**: QR code scanning
- **Charts**: Data visualization

### External Libraries
- None (pure Swift/SwiftUI implementation)

## Build Configuration

### Target Settings
- **Deployment Target**: iOS 17.0
- **Swift Version**: 5.9
- **Bundle Identifier**: com.tasklock.app
- **Display Name**: TaskLock

### Required Capabilities
- **Family Controls**: com.apple.developer.family-controls
- **Device Activity**: com.apple.developer.deviceactivity
- **Background Modes**: background-fetch, background-processing

### Permissions
- **NSUserNotificationsUsageDescription**: Task reminders
- **NSCameraUsageDescription**: QR code scanning
- **NFCReaderUsageDescription**: NFC tag reading
- **NSFamilyControlsUsageDescription**: App blocking

## Testing Strategy

### Unit Tests
- Policy Engine logic with edge cases
- Time zone and DST handling
- Grace period calculations
- Completion policy evaluation

### UI Tests
- Task creation and completion
- Blocking activation/deactivation
- Navigation between views
- Quick add functionality

### Integration Tests
- CoreData operations
- Notification scheduling
- Analytics data generation
- CSV export functionality

## Deployment

### Development
- Requires Apple Developer account
- Family Controls capability requires special entitlements
- Test on physical device (not simulator)

### Distribution
- App Store distribution recommended
- AltStore sideloading supported
- TestFlight for beta testing

## Security Considerations

- All data stored locally
- No cloud synchronization
- Physical unlock codes generated locally
- No external data transmission

## Performance Considerations

- CoreData with lightweight migrations
- Background task handling
- Efficient chart rendering
- Memory management for large datasets

## Future Enhancements

- CloudKit integration (optional)
- Widget support
- Apple Watch companion
- Siri Shortcuts integration
- Advanced analytics
- Team collaboration features
