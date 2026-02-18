//
//  MetricsView.swift
//  Averaged
//
//  Created by Connor Frank on 1/6/25.
//

import SwiftUI
import UIKit

struct MetricsView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @ObservedObject private var autoScreenTime = AutoScreenTimeManager.shared
    @AppStorage("screenTimeGoal") private var screenTimeGoal: Int = 120
    @State private var goalWakeMinutes: Double = 360
    @State private var showAuthError = false
    @State private var cachedWakeLookup: [Date: Double] = [:]
    @State private var cachedScreenLookup: [Date: Int] = [:]

    var body: some View {
        List {
            Section("Streaks") {
                HStack {
                    Label("Current Goal Streak", systemImage: "flame.fill")
                    Spacer()
                    Text("\(currentStreak) days")
                        .foregroundColor(currentStreak > 0 ? .green : .secondary)
                        .fontWeight(.semibold)
                }
                HStack {
                    Label("Best Streak This Year", systemImage: "trophy.fill")
                    Spacer()
                    Text("\(bestStreakThisYear) days")
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                }
            }

            Section("Wake Time") {
                HStack {
                    Label("This Week", systemImage: "sunrise.fill")
                    Spacer()
                    if let avg = weeklyWakeAverage {
                        Text(minutesToHHmm(avg))
                            .fontWeight(.semibold)
                        Image(systemName: avg <= goalWakeMinutes ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .foregroundColor(avg <= goalWakeMinutes ? .green : .red)
                    } else {
                        Text("N/A")
                            .foregroundColor(.secondary)
                            .help("No wake data recorded this week")
                    }
                }
                HStack {
                    Label("This Month", systemImage: "calendar")
                    Spacer()
                    if let avg = monthlyWakeAverage {
                        Text(minutesToHHmm(avg))
                            .fontWeight(.semibold)
                        Image(systemName: avg <= goalWakeMinutes ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .foregroundColor(avg <= goalWakeMinutes ? .green : .red)
                    } else {
                        Text("N/A")
                            .foregroundColor(.secondary)
                            .help("No wake data recorded this month")
                    }
                }
                HStack {
                    Label("Days Tracked", systemImage: "checkmark.circle")
                    Spacer()
                    Text("\(wakeDataCountThisMonth)")
                        .fontWeight(.semibold)
                }
            }

            Section("Screen Time") {
                if !autoScreenTime.isAuthorized {
                    Button {
                        Task {
                            await autoScreenTime.requestAuthorization()
                        }
                    } label: {
                        Label("Grant Screen Time Access", systemImage: "lock.shield")
                    }
                }
                HStack {
                    Label("Today", systemImage: "iphone")
                    Spacer()
                    if let mins = autoScreenTime.todayMinutes {
                        Text(minutesToHHmm(mins))
                            .fontWeight(.semibold)
                    } else {
                        Text("N/A")
                            .foregroundColor(.secondary)
                    }
                }
                HStack {
                    Label("This Week", systemImage: "iphone")
                    Spacer()
                    if let avg = weeklyScreenTimeAverage {
                        Text(minutesToHHmm(avg))
                            .fontWeight(.semibold)
                        Image(systemName: avg <= Double(screenTimeGoal) ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .foregroundColor(avg <= Double(screenTimeGoal) ? .green : .red)
                    } else {
                        Text("N/A")
                            .foregroundColor(.secondary)
                            .help("No screen time logged this week")
                    }
                }
                HStack {
                    Label("This Month", systemImage: "calendar")
                    Spacer()
                    if let avg = monthlyScreenTimeAverage {
                        Text(minutesToHHmm(avg))
                            .fontWeight(.semibold)
                        Image(systemName: avg <= Double(screenTimeGoal) ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .foregroundColor(avg <= Double(screenTimeGoal) ? .green : .red)
                    } else {
                        Text("N/A")
                            .foregroundColor(.secondary)
                            .help("No screen time logged this month")
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .alert("Health Data Access", isPresented: $showAuthError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Unable to access Health data. Please enable access in Settings > Health > Data Access.")
        }
        .onAppear {
            goalWakeMinutes = loadWakeTimeGoalMinutes()
            if healthDataManager.allWakeData.isEmpty {
                healthDataManager.requestAuthorization { _, _ in }
                healthDataManager.fetchWakeTimesOverLastNDays(365) {
                    rebuildLookups()
                }
            } else {
                rebuildLookups()
            }
            if healthDataManager.authorizationError != nil {
                showAuthError = true
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .didChangeGoalTime)
        ) { _ in
            goalWakeMinutes = loadWakeTimeGoalMinutes()
        }
        .onChange(of: healthDataManager.allWakeData.count) { _ in
            rebuildLookups()
        }
        .onChange(of: autoScreenTime.todayMinutes) { _ in
            rebuildLookups()
        }
    }

    private func rebuildLookups() {
        let calendar = Calendar.current
        var wDict = [Date: Double]()
        for data in healthDataManager.allWakeData {
            guard let w = data.wakeTime else { continue }
            let key = calendar.startOfDay(for: w)
            let mins = wakeTimeInMinutes(w)
            if let existing = wDict[key] {
                wDict[key] = min(existing, mins)
            } else {
                wDict[key] = mins
            }
        }
        cachedWakeLookup = wDict

        var sDict = [Date: Int]()
        let now = Date()
        let year = calendar.component(.year, from: now)
        guard let jan1 = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else {
            cachedScreenLookup = sDict
            return
        }
        let today = calendar.startOfDay(for: now)
        var day = jan1
        while day <= today {
            if let mins = autoScreenTime.screenTimeMinutes(for: day) {
                sDict[day] = Int(mins)
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = nextDay
        }
        cachedScreenLookup = sDict
    }

    // MARK: - Wake Time Calculations

    private var weeklyWakeAverage: Double? {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return nil }
        let values = healthDataManager.allWakeData.compactMap { data -> Double? in
            guard let w = data.wakeTime, w >= weekAgo else { return nil }
            return wakeTimeInMinutes(w)
        }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var monthlyWakeAverage: Double? {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: comps) else { return nil }
        let values = healthDataManager.allWakeData.compactMap { data -> Double? in
            guard let w = data.wakeTime, w >= startOfMonth else { return nil }
            return wakeTimeInMinutes(w)
        }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var wakeDataCountThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: comps) else { return 0 }
        return healthDataManager.allWakeData.filter {
            guard let w = $0.wakeTime else { return false }
            return w >= startOfMonth
        }.count
    }

    // MARK: - Screen Time Calculations

    private var weeklyScreenTimeAverage: Double? {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return nil }
        var values = [Double]()
        var day = calendar.startOfDay(for: weekAgo)
        let today = calendar.startOfDay(for: now)
        while day <= today {
            if let mins = autoScreenTime.screenTimeMinutes(for: day) {
                values.append(mins)
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = nextDay
        }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var monthlyScreenTimeAverage: Double? {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: comps) else { return nil }
        var values = [Double]()
        var day = startOfMonth
        let today = calendar.startOfDay(for: now)
        while day <= today {
            if let mins = autoScreenTime.screenTimeMinutes(for: day) {
                values.append(mins)
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = nextDay
        }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    // MARK: - Streak Calculations

    private func metGoalsForDay(_ day: Date, wakeLookup: [Date: Double], screenLookup: [Date: Int]) -> Bool {
        guard let mins = wakeLookup[day], mins <= goalWakeMinutes else { return false }
        guard let screenMins = screenLookup[day], Double(screenMins) <= Double(screenTimeGoal) else { return false }
        return true
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var day = calendar.startOfDay(for: Date())

        // Start from yesterday -- today is still in progress
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
        day = yesterday

        while true {
            if metGoalsForDay(day, wakeLookup: cachedWakeLookup, screenLookup: cachedScreenLookup) {
                streak += 1
            } else {
                break
            }
            guard let prevDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prevDay
        }

        if [7, 30, 100].contains(streak) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }

        return streak
    }

    private var bestStreakThisYear: Int {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let year = calendar.component(.year, from: now)
        guard let jan1 = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else { return 0 }

        var best = 0
        var current = 0
        var day = jan1

        while day <= now {
            if metGoalsForDay(day, wakeLookup: cachedWakeLookup, screenLookup: cachedScreenLookup) {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = nextDay
        }

        let storedKey = "bestStreak_\(year)"
        let storedBest = UserDefaults.standard.integer(forKey: storedKey)
        let finalBest = max(best, storedBest)
        if finalBest > storedBest {
            UserDefaults.standard.set(finalBest, forKey: storedKey)
        }
        return finalBest
    }
}
