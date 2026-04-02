//
//  NotificationManager.swift
//  ClosetGenius
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func scheduleDailyOutfitReminder(enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        let id = "dailyOutfitReminder"
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to get dressed ✨"
        content.body = "Open ClosetGenius and log today's outfit!"
        content.sound = .default

        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    func scheduleAISuggestionNotification(enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        let id = "aiOutfitSuggestion"
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Nova has a style idea ✦"
        content.body = "Tap to see your AI outfit suggestion for today."
        content.sound = .default

        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
