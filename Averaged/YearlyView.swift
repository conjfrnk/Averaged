//
//  YearlyView.swift
//  Averaged
//
//  Created by Connor Frank on 12/27/24.
//

import Charts
import SwiftUI

struct YearlyView: View {
    @StateObject private var healthDataManager = HealthDataManager()

    @State private var monthlyWakeTimes: [MonthlyWakeData] = []
    @State private var monthlyScreenTimes: [MonthlyScreenData] = []

    @State private var goalWakeMinutes: Double = 360
    @State private var goalScreenTimeMinutes: Double = 120

    var body: some View {
        VStack(spacing: 16) {
            Text("Yearly Sleep Data")
                .font(.headline)

            Chart {
                ForEach(monthlyWakeTimes) { item in
                    LineMark(
                        x: .value("Month", item.date),
                        y: .value("Wake Time", item.wakeMinutes)
                    )
                    .foregroundStyle(.green)

                    PointMark(
                        x: .value("Month", item.date),
                        y: .value("Wake Time", item.wakeMinutes)
                    )
                    .foregroundStyle(.green)
                }
                RuleMark(y: .value("Goal Wake", goalWakeMinutes))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(Color.green.opacity(0.8))
            }
            .chartXScale(
                domain: (monthlyWakeTimes.first?.date ?? Date())...(monthlyWakeTimes
                    .last?.date ?? Date())
            )
            .frame(height: 200)

            if let averageWake = computeAverageWakeTime() {
                let averageText = minutesToHHmm(averageWake)
                HStack {
                    Text("Yearly Avg Wake Time: \(averageText)")
                    let arrowUp = Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.red)
                    let arrowDown = Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)

                    if averageWake <= goalWakeMinutes {
                        arrowDown
                    } else {
                        arrowUp
                    }
                }
            } else {
                Text("Yearly Avg Wake Time: N/A")
            }

            Divider()

            Text("Yearly Screen Time")
                .font(.headline)

            Chart {
                ForEach(monthlyScreenTimes) { item in
                    LineMark(
                        x: .value("Month", item.date),
                        y: .value("Screen Time", item.screenMinutes)
                    )
                    .foregroundStyle(.blue)

                    PointMark(
                        x: .value("Month", item.date),
                        y: .value("Screen Time", item.screenMinutes)
                    )
                    .foregroundStyle(.blue)
                }
                RuleMark(y: .value("Goal Screen Time", goalScreenTimeMinutes))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(Color.blue.opacity(0.8))
            }
            .chartXScale(
                domain: (monthlyScreenTimes.first?.date ?? Date())...(monthlyScreenTimes
                    .last?.date ?? Date())
            )
            .frame(height: 200)

            if let averageScreen = computeAverageScreenTime() {
                let averageText = minutesToHHmm(averageScreen)
                HStack {
                    Text("Yearly Avg Screen Time: \(averageText)")
                    let arrowUp = Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.red)
                    let arrowDown = Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)

                    if averageScreen <= goalScreenTimeMinutes {
                        arrowDown
                    } else {
                        arrowUp
                    }
                }
            } else {
                Text("Yearly Avg Screen Time: N/A")
            }

            Spacer()
        }
        .padding()
        .onAppear {
            healthDataManager.requestAuthorization()
            loadMonthlyData()
        }
    }

    private func loadMonthlyData() {
        healthDataManager.fetchAverageWakeTimes(byMonth: true) { dict in
            let sorted = dict.sorted { $0.key < $1.key }
            let mapped = sorted.map { (date, minutes) in
                MonthlyWakeData(date: date, wakeMinutes: minutes)
            }
            monthlyWakeTimes = mapped
        }

        healthDataManager.fetchAverageScreenTime(byMonth: true) { dict in
            let sorted = dict.sorted { $0.key < $1.key }
            let mapped = sorted.map { (date, minutes) in
                MonthlyScreenData(date: date, screenMinutes: minutes)
            }
            monthlyScreenTimes = mapped
        }
    }

    private func computeAverageWakeTime() -> Double? {
        guard !monthlyWakeTimes.isEmpty else { return nil }
        let sum = monthlyWakeTimes.reduce(0.0) { $0 + $1.wakeMinutes }
        let avg = sum / Double(monthlyWakeTimes.count)
        if avg.isNaN || avg.isInfinite { return nil }
        return avg
    }

    private func computeAverageScreenTime() -> Double? {
        guard !monthlyScreenTimes.isEmpty else { return nil }
        let sum = monthlyScreenTimes.reduce(0.0) { $0 + $1.screenMinutes }
        let avg = sum / Double(monthlyScreenTimes.count)
        if avg.isNaN || avg.isInfinite { return nil }
        return avg
    }

    private func minutesToHHmm(_ minutes: Double) -> String {
        if minutes.isNaN || minutes.isInfinite {
            return "N/A"
        }
        let hours = Int(minutes / 60)
        let remainder = Int(minutes) % 60
        return String(format: "%dh %02dm", hours, remainder)
    }
}

struct MonthlyWakeData: Identifiable {
    let id = UUID()
    let date: Date
    let wakeMinutes: Double
}

struct MonthlyScreenData: Identifiable {
    let id = UUID()
    let date: Date
    let screenMinutes: Double
}
