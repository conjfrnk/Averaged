//
//  MonthlyView.swift
//  Averaged
//
//  Created by Connor Frank on 12/27/24.
//

import Charts
import SwiftUI

struct MonthlyView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @ObservedObject private var screenTimeManager = ScreenTimeDataManager.shared
    @State private var selectedMonth: Date = {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        return cal.date(from: comps) ?? Date()
    }()
    @State private var dailyWakeTimes: [DailyWakeData] = []
    @State private var dailyScreenTimes: [DailyScreenTimeData] = []
    @State private var goalWakeMinutes: Double = 360
    @AppStorage("screenTimeGoal") private var screenTimeGoal: Int = 120

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Button {
                        if let prev = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
                            selectedMonth = prev
                            reloadMonthlyData()
                            reloadMonthlyScreenTime()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text(monthYearString(selectedMonth))
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button {
                        if let next = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
                            selectedMonth = next
                            reloadMonthlyData()
                            reloadMonthlyScreenTime()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(isCurrentMonth)
                }
                .padding(.horizontal)
                Text("Wake Time")
                    .font(.headline)
                if dailyWakeTimes.isEmpty {
                    Text("No data for this month")
                        .foregroundColor(.secondary)
                        .frame(height: 300)
                } else {
                    Chart {
                        if let avg = computeAverage(
                            dailyWakeTimes.map(\.wakeMinutes))
                        {
                            RuleMark(y: .value("Monthly Average", avg))
                                .lineStyle(.init(lineWidth: 2, dash: [5]))
                                .foregroundStyle(.blue.opacity(0.8))
                        }
                        ForEach(dailyWakeTimes) { item in
                            LineMark(
                                x: .value("Day", item.date),
                                y: .value("Wake Time", item.wakeMinutes)
                            )
                            .foregroundStyle(.blue)
                            PointMark(
                                x: .value("Day", item.date),
                                y: .value("Wake Time", item.wakeMinutes)
                            )
                            .foregroundStyle(
                                item.wakeMinutes <= goalWakeMinutes
                                    ? .green : .red)
                        }
                        RuleMark(y: .value("Goal Wake", goalWakeMinutes))
                            .lineStyle(.init(lineWidth: 2, dash: [5]))
                            .foregroundStyle(.green.opacity(0.8))
                    }
                    .chartYScale(
                        domain: chartYDomain(
                            for: dailyWakeTimes.map(\.wakeMinutes),
                            goal: goalWakeMinutes)
                    )
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .stride(by: 30)) {
                            val in
                            AxisGridLine()
                            AxisValueLabel {
                                if let rawVal = val.as(Double.self) {
                                    Text(minutesToHHmm(rawVal))
                                }
                            }
                        }
                    }
                    .chartXScale(domain: monthlyXDomain())
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 5)) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text("\(Calendar.current.component(.day, from: date))")
                                }
                            }
                        }
                    }
                    .frame(height: 300)
                }
                if let avg = computeAverage(dailyWakeTimes.map(\.wakeMinutes)),
                    !dailyWakeTimes.isEmpty
                {
                    let formatted = minutesToHHmm(avg)
                    HStack {
                        Text("Average Wake Time: \(formatted)")
                        if avg > goalWakeMinutes {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.red)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                } else {
                    Text("Average Wake Time: N/A")
                }
                Divider().padding(.vertical, 10)
                Text("Screen Time")
                    .font(.headline)
                if dailyScreenTimes.isEmpty {
                    Text("No Screen Time data for this month")
                        .foregroundColor(.secondary)
                        .frame(height: 300)
                } else {
                    Chart {
                        if let avg = computeAverage(
                            dailyScreenTimes.map(\.minutes))
                        {
                            RuleMark(y: .value("Monthly Avg", avg))
                                .lineStyle(.init(lineWidth: 2, dash: [5]))
                                .foregroundStyle(.blue.opacity(0.8))
                        }
                        ForEach(dailyScreenTimes) { item in
                            LineMark(
                                x: .value("Day", item.date),
                                y: .value("Screen Time", item.minutes)
                            )
                            PointMark(
                                x: .value("Day", item.date),
                                y: .value("Screen Time", item.minutes)
                            )
                            .foregroundStyle(
                                item.minutes <= Double(screenTimeGoal)
                                    ? .green : .red)
                        }
                        RuleMark(y: .value("Goal", Double(screenTimeGoal)))
                            .lineStyle(.init(lineWidth: 2, dash: [5]))
                            .foregroundStyle(.green.opacity(0.8))
                    }
                    .chartYScale(
                        domain: chartYDomain(
                            for: dailyScreenTimes.map(\.minutes),
                            goal: Double(screenTimeGoal))
                    )
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .stride(by: 30)) {
                            val in
                            AxisGridLine()
                            AxisValueLabel {
                                if let rawVal = val.as(Double.self) {
                                    Text(minutesToHHmm(rawVal))
                                }
                            }
                        }
                    }
                    .chartXScale(domain: monthlyXDomain())
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 5)) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text("\(Calendar.current.component(.day, from: date))")
                                }
                            }
                        }
                    }
                    .frame(height: 300)
                }
                if let avg2 = computeAverage(dailyScreenTimes.map(\.minutes)),
                    !dailyScreenTimes.isEmpty
                {
                    let formatted2 = minutesToHHmm(avg2)
                    HStack {
                        Text("Average Screen Time: \(formatted2)")
                        if avg2 > Double(screenTimeGoal) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.red)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                } else {
                    Text("Average Screen Time: N/A")
                }
            }
            .padding()
        }
        .onAppear {
            healthDataManager.requestAuthorization { _, _ in }
            if healthDataManager.allWakeData.isEmpty {
                healthDataManager.fetchWakeTimesOverLastNDays(60) {
                    reloadMonthlyData()
                }
            } else {
                reloadMonthlyData()
            }
            reloadMonthlyScreenTime()
            loadUserGoal()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .didChangeGoalTime)
        ) { _ in
            loadUserGoal()
            reloadMonthlyData()
            reloadMonthlyScreenTime()
        }
    }

    func loadUserGoal() {
        let epoch = UserDefaults.standard.double(forKey: "goalWakeTime")
        if epoch > 0 {
            let date = Date(timeIntervalSince1970: epoch)
            let comps = Calendar.current.dateComponents(
                [.hour, .minute], from: date)
            goalWakeMinutes = Double(
                (comps.hour ?? 6) * 60 + (comps.minute ?? 0))
        }
    }

    func reloadMonthlyData() {
        let start = startOfMonth()
        let end = endOfMonth()
        let items = healthDataManager.allWakeData.filter {
            guard let w = $0.wakeTime else { return false }
            return w >= start && w <= end
        }
        let sorted = items.sorted {
            ($0.wakeTime ?? .distantPast) < ($1.wakeTime ?? .distantPast)
        }
        let mapped = sorted.map { data -> DailyWakeData in
            guard let wt = data.wakeTime else {
                return DailyWakeData(date: data.date, wakeMinutes: 0)
            }
            let dayOnly = Calendar.current.startOfDay(for: wt)
            let comps = Calendar.current.dateComponents(
                [.hour, .minute], from: wt)
            let mins = Double((comps.hour ?? 0) * 60 + (comps.minute ?? 0))
            return DailyWakeData(date: dayOnly, wakeMinutes: mins)
        }
        dailyWakeTimes = mapped
    }

    func reloadMonthlyScreenTime() {
        let start = startOfMonth()
        let end = endOfMonth()
        let records = screenTimeManager.validScreenTimeData.filter { record in
            guard let d = record.date else { return false }
            return d >= start && d <= end
        }
        let sorted = records.sorted {
            ($0.date ?? Date()) < ($1.date ?? Date())
        }
        dailyScreenTimes = sorted.map { r in
            let dateOnly = Calendar.current.startOfDay(for: r.date ?? Date())
            return DailyScreenTimeData(
                date: dateOnly, minutes: Double(r.minutes))
        }
    }

    func startOfMonth() -> Date {
        return selectedMonth
    }

    func endOfMonth() -> Date {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: selectedMonth) else { return selectedMonth }
        return cal.date(bySetting: .day, value: range.upperBound - 1, of: selectedMonth) ?? selectedMonth
    }

    func monthlyXDomain() -> ClosedRange<Date> {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: selectedMonth),
              let first = cal.date(bySetting: .day, value: range.lowerBound, of: selectedMonth),
              let last = cal.date(bySetting: .day, value: range.upperBound - 1, of: selectedMonth)
        else { return selectedMonth...selectedMonth }
        return first...last
    }

    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private var isCurrentMonth: Bool {
        let cal = Calendar.current
        let now = Date()
        return cal.component(.year, from: selectedMonth) == cal.component(.year, from: now)
            && cal.component(.month, from: selectedMonth) == cal.component(.month, from: now)
    }
}

struct DailyScreenTimeData: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Double
}
