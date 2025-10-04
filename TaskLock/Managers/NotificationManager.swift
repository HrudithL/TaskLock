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
    
    // MARK: - Task Notifications
    
    public func scheduleTaskReminder(taskId: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder: \(title)"
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // Add custom data
        content.userInfo = [
            "taskId": taskId,
            "type": "taskReminder"
        ]
        
        // Add action buttons
        content.categoryIdentifier = "TASK_REMINDER"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "task_\(taskId)_\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    public func cancelTaskNotifications(taskId: String) {
        notificationCenter.getPendingNotificationRequests { requests in
            let taskNotifications = requests.filter { request in
                request.identifier.contains("task_\(taskId)_")
            }
            
            let identifiers = taskNotifications.map { $0.identifier }
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    public func scheduleSnoozeNotification(taskId: String, title: String, body: String, snoozeMinutes: Int = 15) {
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder: \(title)"
        content.body = body
        content.sound = .default
        content.badge = 1
        
        content.userInfo = [
            "taskId": taskId,
            "type": "taskReminder"
        ]
        
        content.categoryIdentifier = "TASK_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(snoozeMinutes * 60), repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "snooze_\(taskId)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling snooze notification: \(error)")
            }
        }
    }
    
    // MARK: - Setup Notification Categories
    
    public func setupNotificationCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 15 min",
            options: []
        )
        
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Mark Done",
            options: [.foreground]
        )
        
        let taskReminderCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [snoozeAction, completeAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([taskReminderCategory])
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let taskId = userInfo["taskId"] as? String {
            switch response.actionIdentifier {
            case "SNOOZE_ACTION":
                if let title = userInfo["title"] as? String,
                   let body = userInfo["body"] as? String {
                    scheduleSnoozeNotification(taskId: taskId, title: title, body: body)
                }
            case "COMPLETE_ACTION":
                // Handle task completion
                NotificationCenter.default.post(name: .taskCompletedFromNotification, object: taskId)
            default:
                break
            }
        }
        
        completionHandler()
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let taskCompletedFromNotification = Notification.Name("taskCompletedFromNotification")
}
