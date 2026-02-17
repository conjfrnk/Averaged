//
//  NotificationManager.swift
//  Averaged
//
//  Created by Connor Frank on 2/17/26.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @AppStorage("screenTimeReminderEnabled") var reminderEnabled: Bool = false
    @AppStorage("screenTimeReminderHour") var reminderHour: Int = 20  // 8 PM

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { granted, error in
            if let error = error {
                print(
                    "Notifications: Failed to request permission: \(error)")
            }
        }
    }

    func scheduleReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["screenTimeReminder"])

        guard reminderEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Log Screen Time"
        content.body = "Don't forget to log today's screen time!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "screenTimeReminder", content: content,
            trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["screenTimeReminder"])
    }
}
