//
//  AveragedApp.swift
//  Averaged
//
//  Created by Connor Frank on 12/27/24.
//

import SwiftUI

@main
struct AveragedApp: App {
    @StateObject private var healthDataManager = HealthDataManager()
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthDataManager)
                .onAppear {
                    if notificationManager.reminderEnabled {
                        notificationManager.scheduleReminder()
                    }
                }
        }
    }
}
