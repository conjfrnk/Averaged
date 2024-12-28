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
                    .lineStyle(.init(lineWidth: 2, dash: [5]))
                    .foregroundStyle(.green.opacity(0.8))
            }
            .chartXScale(domain: fullYearXDomain())
            .chartXAxis {
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
                            Text(minutesToHHmm(rawVal))
                        }
                    }
                }
            }
            .frame(height: 200)
            if let avg = computeAverageWakeTime() {
                let txt = minutesToHHmm(avg)
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
            healthDataManager.requestAuthorization()
            loadMonthlyData()
        }
    }

    private func loadMonthlyData() {
        healthDataManager.fetchAverageWakeTimes(byMonth: true) { dict in
            let now = Date()
            let calendar = Calendar.current
            var temp: [MonthlyWakeData] = []
            for i in (0..<12).reversed() {
                guard
                    let someDate = calendar.date(
                        byAdding: .month, value: -i, to: now)
                else { continue }
                let comps = calendar.dateComponents(
                    [.year, .month], from: someDate)
                guard let startOfMonth = calendar.date(from: comps) else {
                    continue
                }
                let monthlyAverage = dict[startOfMonth] ?? 0
                temp.append(
                    MonthlyWakeData(
                        date: startOfMonth, wakeMinutes: monthlyAverage))
            }
            monthlyWakeTimes = temp
        }
    }

    private func computeAverageWakeTime() -> Double? {
        guard !monthlyWakeTimes.isEmpty else { return nil }
        let sum = monthlyWakeTimes.reduce(0.0) { $0 + $1.wakeMinutes }
        let avg = sum / Double(monthlyWakeTimes.count)
        return avg.isNaN || avg.isInfinite ? nil : avg
    }

    private func minutesToHHmm(_ val: Double) -> String {
        if val.isNaN || val.isInfinite { return "N/A" }
        let h = Int(val / 60)
        let m = Int(val) % 60
        return String(format: "%dh %02dm", h, m)
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

    private func fullYearXDomain() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        guard
            let earliest = calendar.date(
                byAdding: .month, value: -11, to: startOfThisMonth())
        else {
            return now...now
        }
        return earliest...endOfThisMonth()
    }

    private func startOfThisMonth() -> Date {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: comps) ?? Date()
    }

    private func endOfThisMonth() -> Date {
        let calendar = Calendar.current
        let start = startOfThisMonth()
        guard let dayRange = calendar.range(of: .day, in: .month, for: start)
        else {
            return start
        }
        let lastDay = dayRange.upperBound - 1
        return calendar.date(bySetting: .day, value: lastDay, of: start)
            ?? start
    }

    private func yearlyYDomain() -> ClosedRange<Double> {
        let rawVals = monthlyWakeTimes.map { $0.wakeMinutes }.filter {
            !$0.isNaN && !$0.isInfinite
        }
        guard !rawVals.isEmpty else { return 0...0 }
        let minVal = rawVals.min()!
        let maxVal = rawVals.max()!
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
