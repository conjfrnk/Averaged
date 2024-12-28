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
    //@State private var monthlyScreenTimes: [MonthlyScreenData] = []
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
                RuleMark(
                    y: .value("Goal Wake", goalWakeMinutes)
                )
                .lineStyle(.init(lineWidth: 2, dash: [5]))
                .foregroundStyle(.green.opacity(0.8))
            }
            .chartXScale(domain: domainForYearlyX(monthlyWakeTimes.map(\.date)))
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

            /*
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
                RuleMark(
                    y: .value("Goal Screen Time", goalScreenTimeMinutes)
                )
                .lineStyle(.init(lineWidth: 2, dash: [5]))
                .foregroundStyle(.blue.opacity(0.8))
            }
            .chartXScale(
                domain: domainForYearlyX(monthlyScreenTimes.map(\.date))
            )
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

            if let avg = computeAverageScreenTime() {
                let txt = minutesToHHmm(avg)
                HStack {
                    Text("Yearly Avg Screen Time: \(txt)")
                    if avg <= goalScreenTimeMinutes {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            } else {
                Text("Yearly Avg Screen Time: N/A")
            }

            Spacer()
             */
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
        /*
        healthDataManager.fetchAverageScreenTime(byMonth: true) { dict in
            let sorted = dict.sorted { $0.key < $1.key }
            let mapped = sorted.map { (date, minutes) in
                MonthlyScreenData(date: date, screenMinutes: minutes)
            }
            monthlyScreenTimes = mapped
        }
         */
    }

    private func computeAverageWakeTime() -> Double? {
        guard !monthlyWakeTimes.isEmpty else { return nil }
        let sum = monthlyWakeTimes.reduce(0.0) { $0 + $1.wakeMinutes }
        let avg = sum / Double(monthlyWakeTimes.count)
        if avg.isNaN || avg.isInfinite { return nil }
        return avg
    }

    /*
    private func computeAverageScreenTime() -> Double? {
        guard !monthlyScreenTimes.isEmpty else { return nil }
        let sum = monthlyScreenTimes.reduce(0.0) { $0 + $1.screenMinutes }
        let avg = sum / Double(monthlyScreenTimes.count)
        if avg.isNaN || avg.isInfinite { return nil }
        return avg
    }
     */

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

    private func domainForYearlyX(_ dates: [Date]) -> ClosedRange<Date> {
        guard let minDate = dates.min(), let maxDate = dates.max() else {
            let now = Date()
            return now...now
        }
        return minDate...maxDate
    }
}

struct MonthlyWakeData: Identifiable {
    let id = UUID()
    let date: Date
    let wakeMinutes: Double
}

/*
 struct MonthlyScreenData: Identifiable {
 let id = UUID()
 let date: Date
 let screenMinutes: Double
 }
 */
