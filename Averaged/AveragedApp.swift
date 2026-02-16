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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthDataManager)
        }
    }
}
