//
//  AutoScreenTimeManager.swift
//  Averaged
//
//  Created by Connor Frank on 2/16/26.
//

import FamilyControls
import Foundation
import SwiftUI
import Combine

class AutoScreenTimeManager: ObservableObject {
    static let shared = AutoScreenTimeManager()
    private let appGroupID = "group.com.conjfrnk.Averaged"

    @Published var isAuthorized = false
    @Published var todayMinutes: Double?

    private var refreshTimer: Timer?
    private var foregroundCancellable: AnyCancellable?

    private init() {
        checkAuthorization()
        loadTodayData()
        startPeriodicRefresh()
        observeForeground()
    }

    deinit {
        refreshTimer?.invalidate()
        foregroundCancellable?.cancel()
    }

    private func startPeriodicRefresh() {
        let timer = Timer(timeInterval: 60, repeats: true) { [weak self] _ in
            self?.loadTodayData()
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    private func observeForeground() {
        foregroundCancellable = NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.loadTodayData()
                }
            }
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

    /// Generates a timezone-stable key for a given day using date components (YYYY-MM-DD).
    static func screenTimeKey(for date: Date) -> String {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "screenTime_%04d-%02d-%02d", comps.year!, comps.month!, comps.day!)
    }

    func loadTodayData() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        let key = Self.screenTimeKey(for: Date())
        if defaults.object(forKey: key) != nil {
            let minutes = defaults.double(forKey: key)
            todayMinutes = minutes
        } else {
            todayMinutes = nil
        }
    }

    func screenTimeMinutes(for date: Date) -> Double? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return nil
        }
        let key = Self.screenTimeKey(for: date)
        if defaults.object(forKey: key) != nil {
            return defaults.double(forKey: key)
        }
        // Backward compat: try old epoch-based keys
        let dayStart = Calendar.current.startOfDay(for: date)
        let intKey = "screenTime_\(Int(dayStart.timeIntervalSince1970))"
        if defaults.object(forKey: intKey) != nil {
            return defaults.double(forKey: intKey)
        }
        let doubleKey = "screenTime_\(dayStart.timeIntervalSince1970)"
        if defaults.object(forKey: doubleKey) != nil {
            return defaults.double(forKey: doubleKey)
        }
        return nil
    }
}
