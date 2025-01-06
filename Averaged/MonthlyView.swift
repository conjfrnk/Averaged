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
    @State private var dailyWakeTimes: [DailyWakeData] = []
    @State private var goalWakeMinutes: Double = 360

    var body: some View {
        VStack(spacing: 16) {
            Text("Wake Time")
                .font(.headline)
            if dailyWakeTimes.isEmpty {
                Text("No data for this month")
                    .foregroundColor(.secondary)
                    .frame(height: 300)
            } else {
                Chart {
                    if let avg = computeAverage(
                        dailyWakeTimes.map(\.wakeMinutes)),
                        !dailyWakeTimes.isEmpty
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
                            item.wakeMinutes <= goalWakeMinutes ? .green : .red
                        )
                    }
                    RuleMark(y: .value("Goal Wake", goalWakeMinutes))
                        .lineStyle(.init(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.green.opacity(0.8))
                }
                .chartXScale(domain: monthlyXDomain())
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                    }
                }
                .chartYScale(
                    domain: yDomain(for: dailyWakeTimes.map(\.wakeMinutes))
                )
                .chartYAxis {
                    let domain = yDomain(for: dailyWakeTimes.map(\.wakeMinutes))
                    AxisMarks(
                        position: .leading,
                        values: Array(
                            stride(
                                from: domain.lowerBound,
                                through: domain.upperBound, by: 30))
                    ) { val in
                        AxisGridLine()
                        AxisValueLabel {
                            if let rawVal = val.as(Double.self) {
                                Text(minutesToHHmm(rawVal))
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
            Spacer()
        }
        .padding()
        .onAppear {
            healthDataManager.requestAuthorization { _, _ in }
            if healthDataManager.allWakeData.isEmpty {
                healthDataManager.fetchWakeTimesOverLastNDays(60) {
                    reloadMonthlyData()
                }
            } else {
                reloadMonthlyData()
            }
            loadUserGoal()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .didChangeGoalTime)
        ) { _ in
            loadUserGoal()
            reloadMonthlyData()
        }
    }

    private func loadUserGoal() {
        let epoch = UserDefaults.standard.double(forKey: "goalWakeTime")
        if epoch > 0 {
            let date = Date(timeIntervalSince1970: epoch)
            let comps = Calendar.current.dateComponents(
                [.hour, .minute], from: date)
            goalWakeMinutes = Double(
                (comps.hour ?? 6) * 60 + (comps.minute ?? 0))
        }
    }

    private func reloadMonthlyData() {
        let start = startOfCurrentMonth()
        let end = endOfCurrentMonth()
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

    private func startOfCurrentMonth() -> Date {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        return cal.date(from: comps) ?? now
    }

    private func endOfCurrentMonth() -> Date {
        let cal = Calendar.current
        let s = startOfCurrentMonth()
        guard let range = cal.range(of: .day, in: .month, for: s) else {
            return s
        }
        return cal.date(bySetting: .day, value: range.upperBound - 1, of: s)
            ?? s
    }

    private func monthlyXDomain() -> ClosedRange<Date> {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        guard
            let startOfMonth = cal.date(from: comps),
            let range = cal.range(of: .day, in: .month, for: startOfMonth),
            let first = cal.date(
                bySetting: .day, value: range.lowerBound, of: startOfMonth),
            let last = cal.date(
                bySetting: .day, value: range.upperBound - 1, of: startOfMonth)
        else {
            return now...now
        }
        return first...last
    }

    private func yDomain(for values: [Double]) -> ClosedRange<Double> {
        let allVals = values + [goalWakeMinutes]
        guard !allVals.isEmpty else { return 0...0 }
        let minVal = allVals.min()!
        let maxVal = allVals.max()!
        let minFloor = Double(Int(minVal / 30) * 30) - 30
        let maxCeil = Double(Int(maxVal / 30) * 30) + 30
        let lower = max(0, minFloor)
        let upper = min(Double(24 * 60), maxCeil)
        return lower...upper
    }

    private func computeAverage(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sum = values.reduce(0, +)
        let avg = sum / Double(values.count)
        return avg.isNaN || avg.isInfinite ? nil : avg
    }

    private func minutesToHHmm(_ val: Double) -> String {
        let h = Int(val / 60)
        let m = Int(val) % 60
        return String(format: "%02d:%02d", h, m)
    }
}

struct DailyWakeData: Identifiable {
    let id = UUID()
    let date: Date
    let wakeMinutes: Double
}
