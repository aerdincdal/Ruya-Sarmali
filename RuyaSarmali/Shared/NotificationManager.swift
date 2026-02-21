import Foundation
import UserNotifications
import UIKit

/// Manages notification permissions and scheduling
final class NotificationManager: ObservableObject {
    
    static let shared = NotificationManager()
    
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var isAuthorized: Bool = false
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Permission Request
    
    /// Request notification permission from user
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Notification permission request failed: \(error)")
            return false
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    // MARK: - Daily Dream Reminder
    
    /// Schedule daily dream reminder at specified time
    func scheduleDailyReminder(at hour: Int, minute: Int) async {
        // Remove existing reminders first
        center.removePendingNotificationRequests(withIdentifiers: ["daily_dream_reminder"])
        
        guard isAuthorized else {
            print("Notifications not authorized")
            return
        }
        
        let isEnglish = LocalizationManager.shared.currentLanguage == .english
        
        let content = UNMutableNotificationContent()
        content.title = isEnglish ? "🌙 What did you dream?" : "🌙 Ne rüya gördün?"
        content.body = isEnglish 
            ? "Record your dream before it fades. Turn it into a cinematic video!" 
            : "Rüyanı unutmadan kaydet. Sinematik videoya dönüştür!"
        content.sound = .default
        content.badge = 1
        
        // Create daily trigger
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_dream_reminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("Daily reminder scheduled for \(hour):\(minute)")
        } catch {
            print("Failed to schedule daily reminder: \(error)")
        }
    }
    
    /// Cancel daily reminder
    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["daily_dream_reminder"])
    }
    
    // MARK: - Interpretation Ready Notification
    
    /// Send notification when interpretation is ready (local notification)
    func sendInterpretationReady() async {
        guard isAuthorized else { return }
        
        let isEnglish = LocalizationManager.shared.currentLanguage == .english
        
        let content = UNMutableNotificationContent()
        content.title = isEnglish ? "✨ Your interpretation is ready!" : "✨ Yorumun hazır!"
        content.body = isEnglish 
            ? "Open the app to see your dream interpretation." 
            : "Uygulamayı aç ve rüya yorumunu gör."
        content.sound = .default
        
        // Fire immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "interpretation_ready_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to send interpretation notification: \(error)")
        }
    }
    
    /// Send notification when video is ready
    func sendVideoReady() async {
        guard isAuthorized else { return }
        
        let isEnglish = LocalizationManager.shared.currentLanguage == .english
        
        let content = UNMutableNotificationContent()
        content.title = isEnglish ? "🎬 Your dream video is ready!" : "🎬 Rüya videon hazır!"
        content.body = isEnglish 
            ? "Your cinematic dream video has been created." 
            : "Sinematik rüya videon oluşturuldu."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "video_ready_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to send video notification: \(error)")
        }
    }
    
    // MARK: - Badge Management
    
    /// Clear notification badge
    func clearBadge() {
        center.setBadgeCount(0) { error in
            if let error = error {
                print("Failed to clear badge: \(error)")
            }
        }
    }
    
    // MARK: - Settings Deep Link
    
    /// Open system Settings for this app
    @MainActor
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
