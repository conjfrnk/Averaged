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
    
    // “Goal wake time” in minutes from midnight (e.g. 6:00 AM = 360).
    @State private var goalWakeMinutes: Double = 360

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

                // Draw a rule at “goal wake time”
                RuleMark(y: .value("Goal Wake", goalWakeMinutes))
                    .lineStyle(.init(lineWidth: 2, dash: [5]))
                    .foregroundStyle(.green.opacity(0.8))
            }
            .chartXScale(domain: monthlyXDomain())
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisValueLabel(centered: true) {
                        Text("") // or day number, if you like
                    }
                }
            }
            .chartYScale(domain: yDomain(for: dailyWakeTimes.map(\.wakeMinutes)))
            .chartYAxis {
                let domain = yDomain(for: dailyWakeTimes.map(\.wakeMinutes))
                AxisMarks(
                    position: .leading,
                    values: Array(stride(from: domain.lowerBound,
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

            if let avgWake = computeAverage(dailyWakeTimes.map(\.wakeMinutes)) {
                let formatted = minutesToHHmm(avgWake)
                HStack {
                    Text("Monthly Avg Wake Time: \(formatted)")
                    if avgWake <= goalWakeMinutes {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            } else {
                Text("Monthly Avg Wake Time: N/A")
            }

            Spacer()
        }
        .padding()
        .onAppear {
            healthDataManager.requestAuthorization { _, _ in
                loadDailyData()
            }
            // If you want the user’s goal from Settings:
            let epoch = UserDefaults.standard.double(forKey: "goalWakeTime")
            if epoch > 0 {
                let date = Date(timeIntervalSince1970: epoch)
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                goalWakeMinutes = Double((comps.hour ?? 6) * 60 + (comps.minute ?? 0))
            }
        }
    }

    private func loadDailyData() {
        // Example: fetch 60 days, then filter for the current month
        healthDataManager.fetchNightsOverLastNDays(60, sleepGoalMinutes: 480) { nights in
            let start = startOfCurrentMonth()
            let end   = endOfCurrentMonth()
            let filtered = nights.filter {
                $0.sleepEndTime >= start && $0.sleepEndTime <= end
            }
            let sorted = filtered.sorted { $0.sleepEndTime < $1.sleepEndTime }

            var mapped: [DailyWakeData] = []
            for n in sorted {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: n.sleepEndTime)
                let mins = Double((comps.hour ?? 0) * 60 + (comps.minute ?? 0))
                mapped.append(DailyWakeData(date: n.sleepEndTime, wakeMinutes: mins))
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
            let first = cal.date(bySetting: .day, value: range.lowerBound, of: startOfMonth),
            let last = cal.date(bySetting: .day, value: range.upperBound - 1, of: startOfMonth)
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

    private func endOfCurrentMonth() -> Date {
        let cal = Calendar.current
        let now = startOfCurrentMonth()
        guard let range = cal.range(of: .day, in: .month, for: now) else {
            return now
        }
        return cal.date(bySetting: .day, value: range.upperBound - 1, of: now) ?? now
    }

    private func yDomain(for values: [Double]) -> ClosedRange<Double> {
        // We want to ensure the goal is also in range
        let allVals = values + [goalWakeMinutes]
        guard !allVals.isEmpty else { return 0...0 }

        let minVal = allVals.min()!
        let maxVal = allVals.max()!
        let minFloor = Double(Int(minVal / 30) * 30) - 30
        let maxCeil  = Double(Int(maxVal / 30) * 30) + 30

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
