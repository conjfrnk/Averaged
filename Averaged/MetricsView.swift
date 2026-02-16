//
//  MetricsView.swift
//  Averaged
//
//  Created by Connor Frank on 1/6/25.
//

import DeviceActivity
import SwiftUI

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

struct MetricsView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var autoScreenTime: AutoScreenTimeManager
    @ObservedObject private var screenTimeManager = ScreenTimeDataManager.shared
    @AppStorage("screenTimeGoal") private var screenTimeGoal: Int = 120
    @State private var showScreenTimeDetail = false
    @State private var goalWakeMinutes: Double = 360
    @State private var screenTimeFilter = DeviceActivityFilter(
        segment: .daily(
            during: {
                let cal = Calendar.current
                let now = Date()
                let start = cal.dateComponents(
                    [.hour, .minute, .second], from: cal.startOfDay(for: now))
                var end = start
                end.hour = 23
                end.minute = 59
                end.second = 59
                return DateInterval(
                    start: cal.date(from: start) ?? now,
                    end: cal.date(from: end) ?? now)
            }()
        )
    )

    var body: some View {
        List {
            if autoScreenTime.isAuthorized {
                Section("Today's Screen Time") {
                    DeviceActivityReport(.totalActivity, filter: screenTimeFilter)
                        .frame(height: 100)
                }
            }

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
                        Text("N/A").foregroundColor(.secondary)
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
                        Text("N/A").foregroundColor(.secondary)
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
                HStack {
                    Label("This Week", systemImage: "iphone")
                    Spacer()
                    if let avg = weeklyScreenTimeAverage {
                        Text(minutesToHHmm(avg))
                            .fontWeight(.semibold)
                        Image(systemName: avg <= Double(screenTimeGoal) ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .foregroundColor(avg <= Double(screenTimeGoal) ? .green : .red)
                    } else {
                        Text("N/A").foregroundColor(.secondary)
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
                        Text("N/A").foregroundColor(.secondary)
                    }
                }
                Button {
                    showScreenTimeDetail.toggle()
                } label: {
                    HStack {
                        Label("Log Screen Time", systemImage: "plus.circle")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .sheet(isPresented: $showScreenTimeDetail) {
            ScreenTimeDetailView()
        }
        .onAppear {
            loadGoal()
            if healthDataManager.allWakeData.isEmpty {
                healthDataManager.requestAuthorization { _, _ in }
                healthDataManager.fetchWakeTimesOverLastNDays(365) {}
            }
        }
    }

    private func loadGoal() {
        let epoch = UserDefaults.standard.double(forKey: "goalWakeTime")
        if epoch > 0 {
            let date = Date(timeIntervalSince1970: epoch)
            let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
            goalWakeMinutes = Double((comps.hour ?? 6) * 60 + (comps.minute ?? 0))
        }
    }

    private func minutesToHHmm(_ val: Double) -> String {
        let h = Int(val / 60)
        let m = Int(val) % 60
        return String(format: "%02d:%02d", h, m)
    }

    // MARK: - Wake Time Calculations

    private var weeklyWakeAverage: Double? {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return nil }
        let values = healthDataManager.allWakeData.compactMap { data -> Double? in
            guard let w = data.wakeTime, w >= weekAgo else { return nil }
            let comps = calendar.dateComponents([.hour, .minute], from: w)
            return Double((comps.hour ?? 0) * 60 + (comps.minute ?? 0))
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
            let c = calendar.dateComponents([.hour, .minute], from: w)
            return Double((c.hour ?? 0) * 60 + (c.minute ?? 0))
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

    private var validScreenTimeRecords: [ScreenTimeRecord] {
        screenTimeManager.allScreenTimeData.filter { $0.minutes >= 0 }
    }

    private var weeklyScreenTimeAverage: Double? {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return nil }
        let values = validScreenTimeRecords.compactMap { record -> Double? in
            guard let d = record.date, d >= weekAgo else { return nil }
            return Double(record.minutes)
        }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var monthlyScreenTimeAverage: Double? {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: comps) else { return nil }
        let values = validScreenTimeRecords.compactMap { record -> Double? in
            guard let d = record.date, d >= startOfMonth else { return nil }
            return Double(record.minutes)
        }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    // MARK: - Streak Calculations

    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var day = calendar.startOfDay(for: Date())

        while true {
            guard let prevDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prevDay

            let metWakeGoal = healthDataManager.allWakeData.contains { data in
                guard let w = data.wakeTime else { return false }
                let wDay = calendar.startOfDay(for: w)
                guard wDay == day else { return false }
                let comps = calendar.dateComponents([.hour, .minute], from: w)
                let mins = Double((comps.hour ?? 0) * 60 + (comps.minute ?? 0))
                return mins <= goalWakeMinutes
            }

            let screenRecord = validScreenTimeRecords.first { record in
                guard let d = record.date else { return false }
                return calendar.startOfDay(for: d) == day
            }
            let metScreenGoal = screenRecord.map { Double($0.minutes) <= Double(screenTimeGoal) } ?? false

            if metWakeGoal && metScreenGoal {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private var bestStreakThisYear: Int {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        guard let jan1 = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else { return 0 }

        var best = 0
        var current = 0
        var day = jan1

        while day <= now {
            let metWakeGoal = healthDataManager.allWakeData.contains { data in
                guard let w = data.wakeTime else { return false }
                let wDay = calendar.startOfDay(for: w)
                guard wDay == day else { return false }
                let comps = calendar.dateComponents([.hour, .minute], from: w)
                let mins = Double((comps.hour ?? 0) * 60 + (comps.minute ?? 0))
                return mins <= goalWakeMinutes
            }

            let screenRecord = validScreenTimeRecords.first { record in
                guard let d = record.date else { return false }
                return calendar.startOfDay(for: d) == day
            }
            let metScreenGoal = screenRecord.map { Double($0.minutes) <= Double(screenTimeGoal) } ?? false

            if metWakeGoal && metScreenGoal {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = nextDay
        }
        return best
    }
}
