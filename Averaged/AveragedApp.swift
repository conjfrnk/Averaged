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
    @StateObject private var autoScreenTime = AutoScreenTimeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthDataManager)
                .environmentObject(autoScreenTime)
                .onAppear {
                    if notificationManager.reminderEnabled {
                        notificationManager.scheduleReminder()
                    }
                }
        }
    }
}
