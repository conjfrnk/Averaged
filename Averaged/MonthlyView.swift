//
//  MonthlyView.swift
//  Averaged
//
//  Created by Connor Frank on 12/27/24.
//

import Charts
import SwiftUI

struct MonthlyView: View {
    @StateObject private var healthDataManager = HealthDataManager()
    @State private var dailyWakeTimes: [DailyWakeData] = []
    @State private var goalWakeMinutes: Double =
        UserDefaults.standard.double(forKey: "goalWakeTimeInMinutes") == 0
        ? 360
        : UserDefaults.standard.double(forKey: "goalWakeTimeInMinutes")

    var body: some View {
        VStack(spacing: 16) {
            Text("Monthly Sleep Data")
                .font(.headline)
            Chart {
                ForEach(dailyWakeTimes) { item in
                    LineMark(
                        x: .value("Day", item.date),
                        y: .value("Wake Time", item.wakeMinutes)
                    )
                    .foregroundStyle(.green)
                    PointMark(
                        x: .value("Day", item.date),
                        y: .value("Wake Time", item.wakeMinutes)
                    )
                    .foregroundStyle(.green)
                    .annotation {
                        if item.wakeMinutes <= goalWakeMinutes {
                            Label("", systemImage: "checkmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.green, .clear)
                        } else {
                            Label("", systemImage: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.red, .clear)
                        }
                    }
                }
                RuleMark(y: .value("Goal Wake", goalWakeMinutes))
                    .lineStyle(.init(lineWidth: 2, dash: [5]))
                    .foregroundStyle(.green.opacity(0.8))
            }
            .chartXScale(domain: monthlyXDomain())
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisValueLabel(centered: true) {
                        Text("")
                    }
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
                            from: domain.lowerBound, through: domain.upperBound,
                            by: 30))
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
            if let avgWake = computeAverage(dailyWakeTimes.map(\.wakeMinutes)) {
                let formatted = minutesToHHmm(avgWake)
                HStack {
                    Text("Monthly Avg Wake: \(formatted)")
                    if avgWake <= goalWakeMinutes {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            } else {
                Text("Monthly Avg Wake: N/A")
            }
            Spacer()
        }
        .padding()
        .onAppear {
            healthDataManager.requestAuthorization()
            loadDailyData()
        }
    }

    private func loadDailyData() {
        healthDataManager.fetchAverageWakeTimes(byMonth: false) { dict in
            let filtered = dict.filter { $0.key >= startOfCurrentMonth() }
            let sorted = filtered.sorted { $0.key < $1.key }
            let mapped = sorted.map { (dayDate, minutes) in
                DailyWakeData(date: dayDate, wakeMinutes: minutes)
            }
            dailyWakeTimes = mapped
        }
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

    private func startOfCurrentMonth() -> Date {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        return cal.date(from: comps) ?? now
    }

    private func yDomain(for values: [Double]) -> ClosedRange<Double> {
        guard !values.isEmpty else { return 0...0 }
        let minVal = values.min()!
        let maxVal = values.max()!
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
        if avg.isNaN || avg.isInfinite { return nil }
        return avg
    }

    private func minutesToHHmm(_ val: Double) -> String {
        if val.isNaN || val.isInfinite { return "N/A" }
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
