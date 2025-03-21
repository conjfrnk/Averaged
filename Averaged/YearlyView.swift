//
//  YearlyView.swift
//  Averaged
//
//  Created by Connor Frank on 12/27/24.
//

import Charts
import SwiftUI

struct YearlyView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @StateObject private var screenTimeManager = ScreenTimeDataManager.shared
    @State private var monthlyWakeTimes: [MonthlyWakeData] = []
    @State private var monthlyScreenTimes: [MonthlyScreenTimeData] = []
    @State private var goalWakeMinutes: Double = 360
    @AppStorage("screenTimeGoal") private var screenTimeGoal: Int = 120

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Wake Time")
                    .font(.headline)
                if monthlyWakeTimes.isEmpty {
                    Text("No data for this year")
                        .foregroundColor(.secondary)
                        .frame(height: 200)
                } else {
                    Chart {
                        if let yearlyAvg = computeAverageWakeTime() {
                            RuleMark(y: .value("Yearly Average", yearlyAvg))
                                .lineStyle(.init(lineWidth: 2, dash: [5]))
                                .foregroundStyle(.blue.opacity(0.8))
                        }
                        ForEach(monthlyWakeTimes) { item in
                            LineMark(
                                x: .value("Month", item.date),
                                y: .value("Wake Time", item.wakeMinutes)
                            )
                            .foregroundStyle(.blue)
                            PointMark(
                                x: .value("Month", item.date),
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
                        domain: yearlyYDomain(
                            for: monthlyWakeTimes.map { $0.wakeMinutes },
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
                    .chartXScale(domain: currentYearDomain())
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
                    .frame(height: 200)
                }
                if let avg = computeAverageWakeTime(), !monthlyWakeTimes.isEmpty
                {
                    let txt = minutesToHHmm(avg)
                    HStack {
                        Text("Average Wake Time: \(txt)")
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
                if monthlyScreenTimes.isEmpty {
                    Text("No data for this year")
                        .foregroundColor(.secondary)
                        .frame(height: 200)
                } else {
                    Chart {
                        if let yearlyAvg = computeAverageScreenTime() {
                            RuleMark(y: .value("Yearly Average", yearlyAvg))
                                .lineStyle(.init(lineWidth: 2, dash: [5]))
                                .foregroundStyle(.blue.opacity(0.8))
                        }
                        ForEach(monthlyScreenTimes) { item in
                            LineMark(
                                x: .value("Month", item.date),
                                y: .value("Screen Time", item.minutes)
                            )
                            PointMark(
                                x: .value("Month", item.date),
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
                        domain: yearlyYDomain(
                            for: monthlyScreenTimes.map { $0.minutes },
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
                    .chartXScale(domain: currentYearDomain())
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
                    .frame(height: 200)
                }
                if let avg2 = computeAverageScreenTime(),
                    !monthlyScreenTimes.isEmpty
                {
                    let txt2 = minutesToHHmm(avg2)
                    HStack {
                        Text("Average Screen Time: \(txt2)")
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
                healthDataManager.fetchWakeTimesOverLastNDays(365) {
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
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        guard
            let jan1 = calendar.date(
                from: DateComponents(year: year, month: 1, day: 1)),
            let jan1n = calendar.date(
                from: DateComponents(year: year + 1, month: 1, day: 1))
        else {
            monthlyWakeTimes = []
            return
        }
        let filtered = healthDataManager.allWakeData.filter {
            guard let w = $0.wakeTime else { return false }
            return w >= jan1 && w < jan1n
        }
        var grouped: [Date: [Double]] = [:]
        for d in filtered {
            guard let w = d.wakeTime else { continue }
            let comps = calendar.dateComponents([.year, .month], from: w)
            guard let startOfMonth = calendar.date(from: comps) else {
                continue
            }
            let h = calendar.component(.hour, from: w)
            let m = calendar.component(.minute, from: w)
            let mins = Double(h * 60 + m)
            grouped[startOfMonth, default: []].append(mins)
        }
        var temp: [MonthlyWakeData] = []
        for month in 1...12 {
            guard
                let thisMonthDate = calendar.date(
                    from: DateComponents(year: year, month: month, day: 1))
            else {
                continue
            }
            guard let arr = grouped[thisMonthDate], !arr.isEmpty else {
                continue
            }
            let avg = arr.reduce(0, +) / Double(arr.count)
            temp.append(MonthlyWakeData(date: thisMonthDate, wakeMinutes: avg))
        }
        monthlyWakeTimes = temp.sorted { $0.date < $1.date }
    }

    func reloadMonthlyScreenTime() {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        guard
            let jan1 = calendar.date(
                from: DateComponents(year: year, month: 1, day: 1)),
            let jan1n = calendar.date(
                from: DateComponents(year: year + 1, month: 1, day: 1))
        else {
            monthlyScreenTimes = []
            return
        }
        let filtered = screenTimeManager.allScreenTimeData.filter {
            guard let d = $0.date else { return false }
            return d >= jan1 && d < jan1n
        }
        var grouped: [Date: [Double]] = [:]
        for r in filtered {
            guard let dateVal = r.date else { continue }
            let comps = calendar.dateComponents([.year, .month], from: dateVal)
            guard let startOfMonth = calendar.date(from: comps) else {
                continue
            }
            grouped[startOfMonth, default: []].append(Double(r.minutes))
        }
        var temp: [MonthlyScreenTimeData] = []
        for month in 1...12 {
            guard
                let thisMonthDate = calendar.date(
                    from: DateComponents(year: year, month: month, day: 1))
            else {
                continue
            }
            guard let arr = grouped[thisMonthDate], !arr.isEmpty else {
                continue
            }
            let avg = arr.reduce(0, +) / Double(arr.count)
            temp.append(
                MonthlyScreenTimeData(date: thisMonthDate, minutes: avg))
        }
        monthlyScreenTimes = temp.sorted { $0.date < $1.date }
    }

    func computeAverageWakeTime() -> Double? {
        guard !monthlyWakeTimes.isEmpty else { return nil }
        let sum = monthlyWakeTimes.reduce(0.0) { $0 + $1.wakeMinutes }
        let avg = sum / Double(monthlyWakeTimes.count)
        if avg.isNaN || avg.isInfinite {
            return nil
        }
        return avg
    }

    func computeAverageScreenTime() -> Double? {
        guard !monthlyScreenTimes.isEmpty else { return nil }
        let sum = monthlyScreenTimes.reduce(0.0) { $0 + $1.minutes }
        let avg = sum / Double(monthlyScreenTimes.count)
        if avg.isNaN || avg.isInfinite {
            return nil
        }
        return avg
    }

    func currentYearDomain() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let jan1 = calendar.date(
            from: DateComponents(year: year, month: 1, day: 1))!
        let dec31 = calendar.date(
            from: DateComponents(year: year, month: 12, day: 31))!
        return jan1...dec31
    }

    func yearlyYDomain(for values: [Double], goal: Double) -> ClosedRange<
        Double
    > {
        let allVals = values + [goal]
        if allVals.isEmpty {
            return 0...0
        }
        let minVal = allVals.min() ?? 0
        let maxVal = allVals.max() ?? 1440
        let minFloor = Double(Int(minVal / 30) * 30) - 30
        let maxCeil = Double(Int(maxVal / 30) * 30) + 30
        let lower = max(0, minFloor)
        let upper = min(1440, maxCeil)
        return lower...upper
    }

    func singleLetterMonth(_ date: Date) -> String {
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

    func minutesToHHmm(_ val: Double) -> String {
        let h = Int(val / 60)
        let m = Int(val) % 60
        return String(format: "%02d:%02d", h, m)
    }
}

struct MonthlyScreenTimeData: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Double
}
