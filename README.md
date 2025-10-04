# TaskLock - Task-Driven Blocking iOS App

TaskLock is a comprehensive iOS app that combines task management with intelligent app blocking. Built on top of the Foqos blocking engine, it automatically blocks distracting apps when you have incomplete tasks, helping you stay focused and productive.

## Features

### 🎯 Task Management
- **Complete Task System**: Create, edit, and track tasks with due dates, priorities, categories, and time estimates
- **Smart Views**: Today view shows overdue and due tasks, Upcoming view groups tasks by day
- **Categories**: Organize tasks with customizable categories (School, Work, Personal, Health)
- **Quick Add**: Fast task creation with presets and keyboard shortcuts (Cmd-N)
- **Reminders**: Local notifications with snooze and complete actions

### 🛡️ Task-Conditional Blocking
- **Intelligent Blocking**: Automatically blocks apps when you have incomplete tasks due today
- **Flexible Conditions**: Choose from multiple blocking conditions:
  - Any task due today
  - All tasks due today
  - Only high-priority tasks due today
  - Active tasks only
- **Grace Periods**: Configurable delay before blocking activates (0-15 minutes)
- **Completion Policies**: Unblock when current task is done or when all triggering tasks are complete
- **Allowed Apps**: Whitelist essential apps (Calendar, Notes, Safari)

### 🔒 Security & Control
- **Strict Mode**: Prevents disabling blocking during active sessions
- **Physical Unlock**: NFC and QR code bailout options for emergency access
- **Profile Management**: Multiple blocking profiles with different settings
- **Manual Overrides**: Emergency disable with physical verification

### 📊 Analytics & Insights
- **Completion Tracking**: Monitor on-time completion rates and streaks
- **Focus Time**: Track estimated focus time saved through blocking
- **Category Breakdown**: See productivity patterns by category
- **Activity Heatmap**: Visual representation of daily task completion
- **Data Export**: Export tasks, completions, and analytics to CSV

### 🎨 Modern UI/UX
- **SwiftUI Interface**: Clean, minimal design with SF Symbols
- **Dark/Light Mode**: Automatic theme switching
- **Accessibility**: Dynamic Type and VoiceOver support
- **Smooth Animations**: Polished interactions throughout
- **Empty States**: Helpful guidance when no tasks exist

## Architecture

TaskLock is built with a modular architecture for maintainability and extensibility:

### Core Modules

- **TasksKit**: CoreData models, CRUD operations, and reminder scheduling
- **BlockingKit**: FamilyControls/ManagedSettings integration and profile management
- **PolicyEngine**: Task-conditional blocking logic with comprehensive unit tests
- **AnalyticsKit**: Data aggregation, chart generation, and CSV export
- **AppUI**: SwiftUI views, theming, and navigation
- **PhysicalUnlock**: NFC/QR code integration for emergency access

### Key Components

- **AppState**: ObservableObject coordinating task changes and blocking policies
- **TaskManager**: CoreData operations and reminder management
- **BlockingManager**: Screen Time API integration and profile management
- **AnalyticsManager**: Statistics calculation and data visualization
- **PhysicalUnlockManager**: NFC/QR code scanning and validation

## Requirements

- **iOS 17.0+**
- **Xcode 15.0+**
- **Swift 5.9+**
- **Apple Developer Account** (for Family Controls capability)

## Setup Instructions

### 1. Enable Family Controls Capability

**Important**: The Family Controls capability requires special entitlements from Apple and is only available for App Store distribution or with a special development provisioning profile.

1. Open your project in Xcode
2. Select your app target
3. Go to "Signing & Capabilities"
4. Click "+" and add "Family Controls"
5. This will add the `com.apple.developer.family-controls` entitlement

**Note**: For development builds, you may need to:
- Use a development provisioning profile that includes Family Controls
- Contact Apple Developer Support for special entitlements
- Test with TestFlight or App Store distribution

### 2. Build Configuration

1. Set deployment target to iOS 17.0
2. Ensure Swift version is 5.9+
3. Add required frameworks:
   - FamilyControls
   - ManagedSettings
   - DeviceActivity
   - UserNotifications
   - CoreNFC (for NFC unlock)
   - AVFoundation (for QR code scanning)

### 3. Build and Install

#### Option A: Xcode Direct Install
1. Connect your iOS device
2. Select your device as the target
3. Build and run (⌘+R)

#### Option B: AltStore Sideloading
1. Build the project in Xcode
2. Archive the app (Product → Archive)
3. Export as .ipa file
4. Install via AltStore:
   ```bash
   # Install AltStore on your device first
   # Then use AltStore to install the .ipa file
   ```

### 4. First Launch Setup

1. **Grant Permissions**: The app will request Family Controls authorization
2. **Create Categories**: Default categories (School, Work, Personal, Health) are created automatically
3. **Add Presets**: Sample presets are available for quick task creation
4. **Configure Profiles**: Set up blocking profiles in Settings

## Usage Guide

### Creating Tasks

1. **Quick Add**: Tap the "+" button or use Cmd-N keyboard shortcut
2. **From Presets**: Select from common task templates
3. **Manual Entry**: Fill in title, notes, due date, category, priority, and time estimate

### Blocking Configuration

1. **Go to Settings** → **Profiles**
2. **Select a Profile** to configure:
   - Enable "Use task-conditional blocking"
   - Choose blocking condition type
   - Set grace period (0-15 minutes)
   - Configure completion policy
   - Add allowed apps to whitelist
   - Enable Strict Mode if needed

### Physical Unlock Setup

1. **Generate QR Code**: Settings → Generate Unlock QR Code
2. **Print or Save**: Keep the QR code accessible for emergencies
3. **NFC Tags**: Program NFC tags with unlock codes (format: "UNLOCK-XXXXXXXX")

### Analytics

1. **View Stats**: Check the Stats tab for insights
2. **Export Data**: Settings → Export Tasks/Analytics
3. **Track Progress**: Monitor completion rates and focus time

## Privacy & Security

- **Local Data Only**: All task data is stored locally on your device
- **No Cloud Sync**: CoreData with CloudKit is disabled by default
- **Secure Unlock**: Physical unlock codes are generated locally
- **No Tracking**: No analytics or data collection beyond local statistics

## Troubleshooting

### Common Issues

1. **Family Controls Not Working**
   - Ensure you have a valid Apple Developer account
   - Check that the capability is properly configured
   - Verify your provisioning profile includes Family Controls

2. **Blocking Not Activating**
   - Check that tasks have due dates set
   - Verify the blocking condition is met
   - Ensure Family Controls authorization is granted

3. **NFC/QR Not Working**
   - Check device compatibility (NFC requires iPhone 7+)
   - Ensure camera permissions are granted
   - Verify unlock codes are properly formatted

### Debug Mode

Enable Demo Mode in Settings to:
- Create sample tasks for testing
- Test blocking behavior without real tasks
- Generate sample analytics data

## Development

### Project Structure

```
TaskLock/
├── TaskLock/                 # Main app target
├── TasksKit/                 # CoreData models and CRUD
├── BlockingKit/              # FamilyControls integration
├── PolicyEngine/             # Blocking logic and tests
├── AnalyticsKit/             # Data aggregation and charts
├── AppUI/                    # SwiftUI views and navigation
├── AppState/                 # State management
└── PhysicalUnlock/           # NFC/QR integration
```

### Testing

Run the test suite:
```bash
# Unit tests for Policy Engine
xcodebuild test -scheme TaskLock -destination 'platform=iOS Simulator,name=iPhone 15'

# UI tests
xcodebuild test -scheme TaskLockUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Adding New Features

1. **New Task Fields**: Update CoreData model and TaskManager
2. **New Blocking Conditions**: Extend PolicyEngine and BlockingKit
3. **New Analytics**: Add to AnalyticsManager and chart views
4. **New UI Views**: Add to AppUI module

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is open source. Please check the LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Search existing GitHub issues
3. Create a new issue with detailed information

## Acknowledgments

- Built on the foundation of Foqos blocking engine
- Uses Apple's Family Controls framework
- Inspired by productivity and focus methodologies
- Community feedback and contributions

---

**Note**: This app requires iOS 17+ and a valid Apple Developer account with Family Controls capability. The blocking functionality is only available on physical devices, not in the iOS Simulator.
