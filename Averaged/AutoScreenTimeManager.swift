//
//  AutoScreenTimeManager.swift
//  Averaged
//
//  Created by Connor Frank on 2/16/26.
//

import FamilyControls
import Foundation
import SwiftUI

class AutoScreenTimeManager: ObservableObject {
    static let shared = AutoScreenTimeManager()
    private let appGroupID = "group.com.conjfrnk.Averaged"

    @Published var isAuthorized = false
    @Published var todayMinutes: Double?

    private init() {
        checkAuthorization()
        loadTodayData()
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(
                for: .individual)
            await MainActor.run {
                self.isAuthorized = true
            }
        } catch {
            await MainActor.run {
                self.isAuthorized = false
            }
        }
    }

    func checkAuthorization() {
        isAuthorized =
            AuthorizationCenter.shared.authorizationStatus == .approved
    }

    func loadTodayData() {
        guard
            let defaults = UserDefaults(suiteName: appGroupID)
        else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let key = "screenTime_\(today.timeIntervalSince1970)"
        let minutes = defaults.double(forKey: key)
        if minutes > 0 {
            todayMinutes = minutes
        }
    }

    func screenTimeMinutes(for date: Date) -> Double? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return nil
        }
        let dayStart = Calendar.current.startOfDay(for: date)
        let key = "screenTime_\(dayStart.timeIntervalSince1970)"
        let minutes = defaults.double(forKey: key)
        return minutes > 0 ? minutes : nil
    }
}
