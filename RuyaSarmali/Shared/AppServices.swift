import Foundation
import SwiftUI
import UIKit
import StoreKit

/// Uygulama genelinde kullanilan yardimci servisler
struct AppServices {
    
    // MARK: - Haptic Feedback
    
    /// Haptic geri bildirim yoneticisi
    static let haptic = HapticManager.shared
    
    // MARK: - Feedback
    
    /// Geri bildirim servisi
    static let feedback = FeedbackService.shared
    
    // MARK: - Sound
    
    /// Ses efektleri yoneticisi
    static let sound = SoundManager.shared
}

// MARK: - Haptic Manager

final class HapticManager {
    static let shared = HapticManager()
    private init() {}
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    @AppStorage("hapticEnabled") private var isEnabled = true
    
    func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    func light() {
        guard isEnabled else { return }
        lightGenerator.impactOccurred()
    }
    
    func medium() {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred()
    }
    
    func heavy() {
        guard isEnabled else { return }
        heavyGenerator.impactOccurred()
    }
    
    func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
    }
    
    func success() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    func warning() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
    }
    
    func error() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }
}

// MARK: - Sound Manager

final class SoundManager {
    static let shared = SoundManager()
    private init() {}
    
    @AppStorage("soundEnabled") private var isEnabled = true
    
    func playTap() {
        guard isEnabled else { return }
        // Sistem sesi cal
        AudioServicesPlaySystemSound(1104)
    }
    
    func playSuccess() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1057)
    }
    
    func playError() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1073)
    }
}

import AudioToolbox

// MARK: - Feedback Service

final class FeedbackService {
    static let shared = FeedbackService()
    private init() {}
    
    /// Geri bildirimi Supabase'e gonder
    func sendFeedback(_ text: String, email: String?) async throws {
        guard let urlString = Secrets.value(for: .supabaseURL),
              let anonKey = Secrets.value(for: .supabaseAnonKey),
              let url = URL(string: urlString)?.appendingPathComponent("rest/v1/feedback") else {
            throw NSError(domain: "FeedbackService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase yapilandirmasi eksik"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.addValue(anonKey, forHTTPHeaderField: "apikey")
        request.addValue("return=minimal", forHTTPHeaderField: "Prefer")
        
        struct FeedbackPayload: Encodable {
            let message: String
            let email: String?
            let app_version: String
            let device_model: String
            let os_version: String
            let created_at: String
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let payload = FeedbackPayload(
            message: text,
            email: email,
            app_version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            device_model: UIDevice.current.model,
            os_version: UIDevice.current.systemVersion,
            created_at: dateFormatter.string(from: Date())
        )
        
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw NSError(domain: "FeedbackService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geri bildirim gonderilemedi"])
        }
        
        print("Geri bildirim basariyla gonderildi")
    }
}

// MARK: - Notification Manager

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }
    
    func scheduleDailyReminder(at hour: Int, minute: Int) {
        // Onceki bildirimleri temizle
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "Ruyanizi kaydedin"
        content.body = "Bugun nasil bir ruya gordunuz? Kaydetmeyi unutmayin."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_dream_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Bildirim zamanlama hatasi: \(error.localizedDescription)")
            } else {
                print("Gunluk hatirlama ayarlandi: \(hour):\(minute)")
            }
        }
    }
    
    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_dream_reminder"])
    }
}

import UserNotifications

// MARK: - Review Request Helper

struct ReviewHelper {
    static func requestReviewIfAppropriate() {
        let launchCount = UserDefaults.standard.integer(forKey: "app_launch_count")
        let lastReviewRequest = UserDefaults.standard.object(forKey: "last_review_request") as? Date
        
        // 5 acilistan sonra ve son istekten 30 gun gecmisse sor
        if launchCount >= 5 {
            if let lastRequest = lastReviewRequest {
                let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequest, to: Date()).day ?? 0
                if daysSinceLastRequest >= 30 {
                    requestReview()
                }
            } else {
                requestReview()
            }
        }
    }
    
    static func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
            UserDefaults.standard.set(Date(), forKey: "last_review_request")
        }
    }
}
