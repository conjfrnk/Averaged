//
//  NotificationManager.swift
//  Averaged
//
//  Created by Connor Frank on 2/17/26.
//

import Foundation
import os.log
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private static let logger = Logger(subsystem: "com.conjfrnk.Averaged", category: "Notifications")

    @AppStorage("screenTimeReminderEnabled") var reminderEnabled: Bool = false
    @AppStorage("screenTimeReminderHour") var reminderHour: Int = 20  // 8 PM

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { granted, error in
            if let error = error {
                Self.logger.error("Failed to request notification permission: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func scheduleReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["screenTimeReminder"])

        guard reminderEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Check Your Progress"
        content.body = "See how your wake time and screen time are tracking today!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "screenTimeReminder", content: content,
            trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Self.logger.error("Failed to schedule reminder: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func cancelReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["screenTimeReminder"])
    }
}
