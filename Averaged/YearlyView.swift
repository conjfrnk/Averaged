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
    @ObservedObject private var screenTimeManager = ScreenTimeDataManager.shared
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var monthlyWakeTimes: [MonthlyWakeData] = []
    @State private var monthlyScreenTimes: [MonthlyScreenTimeData] = []
    @State private var goalWakeMinutes: Double = 360
    @AppStorage("screenTimeGoal") private var screenTimeGoal: Int = 120

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Button {
                        selectedYear -= 1
                        reloadMonthlyData()
                        reloadMonthlyScreenTime()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text(String(selectedYear))
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button {
                        selectedYear += 1
                        reloadMonthlyData()
                        reloadMonthlyScreenTime()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(selectedYear >= Calendar.current.component(.year, from: Date()))
                }
                .padding(.horizontal)
                Text("Wake Time")
                    .font(.headline)
                if monthlyWakeTimes.isEmpty {
                    Text("No data for this year")
                        .foregroundColor(.secondary)
                        .frame(height: 200)
                } else {
                    Chart {
                        if let yearlyAvg = computeAverage(monthlyWakeTimes.map { $0.wakeMinutes }) {
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
                        domain: chartYDomain(
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
                if let avg = computeAverage(monthlyWakeTimes.map { $0.wakeMinutes }), !monthlyWakeTimes.isEmpty
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
                        if let yearlyAvg = computeAverage(monthlyScreenTimes.map { $0.minutes }) {
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
                        domain: chartYDomain(
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
                if let avg2 = computeAverage(monthlyScreenTimes.map { $0.minutes }),
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
            reloadMonthlyData()
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
        let year = selectedYear
        guard
            let jan1 = calendar.date(
                from: DateComponents(year: year, month: 1, day: 1)),
            let jan1n = calendar.date(
                from: DateComponents(year: year + 1, month: 1, day: 1))
        else {
            monthlyWakeTimes = []
            return
        }
        let daysSinceJan1 = max(
            365,
            Int(Date().timeIntervalSince(jan1) / 86400) + 1)
        if healthDataManager.allWakeData.isEmpty {
            healthDataManager.fetchWakeTimesOverLastNDays(daysSinceJan1) {
                self.processMonthlyWakeData(
                    calendar: calendar, year: year, jan1: jan1, jan1n: jan1n)
            }
        } else {
            processMonthlyWakeData(
                calendar: calendar, year: year, jan1: jan1, jan1n: jan1n)
        }
    }

    private func processMonthlyWakeData(
        calendar: Calendar, year: Int, jan1: Date, jan1n: Date
    ) {
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
        let year = selectedYear
        guard
            let jan1 = calendar.date(
                from: DateComponents(year: year, month: 1, day: 1)),
            let jan1n = calendar.date(
                from: DateComponents(year: year + 1, month: 1, day: 1))
        else {
            monthlyScreenTimes = []
            return
        }
        let filtered = screenTimeManager.validScreenTimeData.filter {
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

    func currentYearDomain() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let jan1 = calendar.date(
            from: DateComponents(year: selectedYear, month: 1, day: 1))!
        let dec31 = calendar.date(
            from: DateComponents(year: selectedYear, month: 12, day: 31))!
        return jan1...dec31
    }
}

struct MonthlyScreenTimeData: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Double
}
