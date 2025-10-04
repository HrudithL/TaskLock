import Foundation
import UserNotifications

// MARK: - Notification Manager
public class NotificationManager: NSObject, ObservableObject {
    public static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    @Published public var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    public override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    public func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        try await notificationCenter.requestAuthorization(options: options)
        await MainActor.run {
            checkAuthorizationStatus()
        }
    }
    
    private func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Task Reminders
    
    public func scheduleTaskReminder(for task: Task) {
        guard let dueDate = task.dueDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = .default
        content.userInfo = [
            "taskId": task.id.uuidString,
            "taskTitle": task.title
        ]
        
        // Add actions
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Mark Done",
            options: []
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 10m",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([category])
        content.categoryIdentifier = "TASK_REMINDER"
        
        // Schedule notification
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "task-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling reminder: \(error)")
            }
        }
    }
    
    public func cancelTaskReminder(for task: Task) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["task-\(task.id.uuidString)"])
    }
    
    // MARK: - Blocking Notifications
    
    public func scheduleBlockingStartNotification(profile: BlockingProfile, reason: String) {
        let content = UNMutableNotificationContent()
        content.title = "Blocking Started"
        content.body = "\(profile.name): \(reason)"
        content.sound = .default
        content.userInfo = [
            "profileId": profile.id.uuidString,
            "profileName": profile.name
        ]
        
        let request = UNNotificationRequest(
            identifier: "blocking-start-\(profile.id.uuidString)",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling blocking notification: \(error)")
            }
        }
    }
    
    public func scheduleBlockingEndNotification(profile: BlockingProfile) {
        let content = UNMutableNotificationContent()
        content.title = "Blocking Ended"
        content.body = "\(profile.name) blocking has been disabled"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "blocking-end-\(profile.id.uuidString)",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling blocking end notification: \(error)")
            }
        }
    }
    
    // MARK: - Daily Summary
    
    public func scheduleDailySummary() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Summary"
        content.body = "Check your task progress and plan for tomorrow"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 21 // 9 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "daily-summary",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling daily summary: \(error)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "COMPLETE_ACTION":
            if let taskIdString = userInfo["taskId"] as? String,
               let taskId = UUID(uuidString: taskIdString) {
                // Handle task completion
                NotificationCenter.default.post(
                    name: .taskCompletedFromNotification,
                    object: nil,
                    userInfo: ["taskId": taskId]
                )
            }
            
        case "SNOOZE_ACTION":
            if let taskIdString = userInfo["taskId"] as? String,
               let taskId = UUID(uuidString: taskIdString) {
                // Handle snooze
                NotificationCenter.default.post(
                    name: .taskSnoozedFromNotification,
                    object: nil,
                    userInfo: ["taskId": taskId]
                )
            }
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            NotificationCenter.default.post(
                name: .notificationTapped,
                object: nil,
                userInfo: userInfo
            )
            
        default:
            break
        }
        
        completionHandler()
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .sound, .badge])
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let taskCompletedFromNotification = Notification.Name("taskCompletedFromNotification")
    static let taskSnoozedFromNotification = Notification.Name("taskSnoozedFromNotification")
    static let notificationTapped = Notification.Name("notificationTapped")
}
