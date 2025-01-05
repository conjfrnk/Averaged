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
    @State private var goalWakeMinutes: Double = 360

    var body: some View {
        VStack(spacing: 16) {
            Text("Yearly Sleep Data")
                .font(.headline)

            // If no data, show placeholder. Otherwise, show the chart.
            if monthlyWakeTimes.isEmpty {
                Text("No data for this year")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            } else {
                Chart {
                    // Plot actual data for any month that has it
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

                    // Green dashed line for goal
                    RuleMark(y: .value("Goal Wake", goalWakeMinutes))
                        .lineStyle(.init(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.green.opacity(0.8))
                }
                .chartXScale(domain: currentYearDomain())
                .chartXAxis {
                    // Tick for each month from Jan to Dec
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(singleLetterMonth(date))
                            }
                        }
                    }
                }
                .chartYScale(domain: yearlyYDomain())
                .chartYAxis {
                    AxisMarks(position: .leading) { val in
                        AxisGridLine()
                        AxisValueLabel {
                            if let rawVal = val.as(Double.self) {
                                Text(minutesToTime(rawVal))
                            }
                        }
                    }
                }
                .frame(height: 200)
            }

            // If there's data, show average; else "N/A"
            if let avg = computeAverageWakeTime(), !monthlyWakeTimes.isEmpty {
                let txt = minutesToTime(avg)
                HStack {
                    Text("Yearly Avg Wake Time: \(txt)")
                    if avg <= goalWakeMinutes {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            } else {
                Text("Yearly Avg Wake Time: N/A")
            }

            Spacer()
        }
        .padding()
        .onAppear {
            healthDataManager.requestAuthorization { _, _ in
                loadMonthlyData()
            }
            // If you want the user’s goal from Settings
            let epoch = UserDefaults.standard.double(forKey: "goalWakeTime")
            if epoch > 0 {
                let date = Date(timeIntervalSince1970: epoch)
                let comps = Calendar.current.dateComponents(
                    [.hour, .minute], from: date)
                goalWakeMinutes = Double(
                    (comps.hour ?? 6) * 60 + (comps.minute ?? 0))
            }
        }
    }

    private func loadMonthlyData() {
        // We'll fetch a full year’s worth of nights
        healthDataManager.fetchNightsOverLastNDays(365, sleepGoalMinutes: 480) {
            nights in
            let calendar = Calendar.current
            let now = Date()
            let year = calendar.component(.year, from: now)

            // We'll group only nights that fall in the CURRENT year
            let january1 = calendar.date(
                from: DateComponents(year: year, month: 1, day: 1))!
            let december31 = calendar.date(
                from: DateComponents(year: year, month: 12, day: 31))!

            let nightsInCurrentYear = nights.filter {
                $0.sleepEndTime >= january1 && $0.sleepEndTime <= december31
            }

            // Group by (month) → [wakeMinutes]
            var grouped: [Date: [Double]] = [:]
            for night in nightsInCurrentYear {
                let comps = calendar.dateComponents(
                    [.year, .month], from: night.sleepEndTime)
                guard let startOfMonth = calendar.date(from: comps) else {
                    continue
                }

                // Convert final wake time → minutes from midnight
                let hour = calendar.component(.hour, from: night.sleepEndTime)
                let min = calendar.component(.minute, from: night.sleepEndTime)
                let wakeMins = Double(hour * 60 + min)

                grouped[startOfMonth, default: []].append(wakeMins)
            }

            // For each month from 1...12 in the current year,
            // only add an entry if there's data
            var temp: [MonthlyWakeData] = []
            for month in 1...12 {
                guard
                    let thisMonthDate = calendar.date(
                        from: DateComponents(year: year, month: month, day: 1))
                else {
                    continue
                }
                guard let arr = grouped[thisMonthDate], !arr.isEmpty else {
                    // Skip months with no data
                    continue
                }
                let avg = arr.reduce(0, +) / Double(arr.count)
                temp.append(
                    MonthlyWakeData(date: thisMonthDate, wakeMinutes: avg))
            }

            // Sort chronologically
            monthlyWakeTimes = temp.sorted { $0.date < $1.date }
        }
    }

    private func computeAverageWakeTime() -> Double? {
        // Only average the months that have real data
        guard !monthlyWakeTimes.isEmpty else { return nil }

        let sum = monthlyWakeTimes.reduce(0.0) { $0 + $1.wakeMinutes }
        let avg = sum / Double(monthlyWakeTimes.count)
        return avg.isNaN || avg.isInfinite ? nil : avg
    }

    private func minutesToTime(_ val: Double) -> String {
        if val.isNaN || val.isInfinite { return "N/A" }
        let h = Int(val / 60)
        let m = Int(val) % 60
        return String(format: "%d:%02d", h, m)
    }

    private func singleLetterMonth(_ date: Date) -> String {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 1: return "J"
        case 2: return "F"
        case 3: return "M"
        case 4: return "A"
        case 5: return "M"
        case 6: return "J"
        case 7: return "J"
        case 8: return "A"
        case 9: return "S"
        case 10: return "O"
        case 11: return "N"
        case 12: return "D"
        default: return ""
        }
    }

    private func currentYearDomain() -> ClosedRange<Date> {
        // Jan 1 ... Dec 31 of current year
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())

        let january1 = calendar.date(
            from: DateComponents(year: year, month: 1, day: 1))!
        let december31 = calendar.date(
            from: DateComponents(year: year, month: 12, day: 31))!

        return january1...december31
    }

    private func yearlyYDomain() -> ClosedRange<Double> {
        // Include the user’s goal wake time
        let rawVals = monthlyWakeTimes.map { $0.wakeMinutes }
        let allVals = rawVals + [goalWakeMinutes]

        guard !allVals.isEmpty else { return 0...0 }

        let minVal = allVals.min()!
        let maxVal = allVals.max()!
        let minFloor = Double(Int(minVal / 30) * 30) - 30
        let maxCeil = Double(Int(maxVal / 30) * 30) + 30

        let lower = max(0, minFloor)
        let upper = min(Double(24 * 60), maxCeil)
        return lower...upper
    }
}

struct MonthlyWakeData: Identifiable {
    let id = UUID()
    let date: Date
    let wakeMinutes: Double
}
