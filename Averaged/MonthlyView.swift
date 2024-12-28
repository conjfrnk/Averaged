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
    @State private var dailyScreenTimes: [DailyScreenData] = []

    @State private var goalWakeMinutes: Double =
        UserDefaults.standard.double(forKey: "goalWakeTimeInMinutes") == 0
        ? 360
        : UserDefaults.standard.double(forKey: "goalWakeTimeInMinutes")

    @State private var goalScreenTimeMinutes: Double =
        Double(UserDefaults.standard.integer(forKey: "screenTimeGoal")) == 0
        ? 120
        : Double(UserDefaults.standard.integer(forKey: "screenTimeGoal"))

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Monthly Sleep Data")
                    .font(.headline)

                Chart {
                    ForEach(dailyWakeTimes) { item in
                        LineMark(
                            x: .value("Day", item.date),
                            y: .value("Wake Time", item.wakeMinutes)
                        )
                        .foregroundStyle(Color.green)

                        PointMark(
                            x: .value("Day", item.date),
                            y: .value("Wake Time", item.wakeMinutes)
                        )
                        .foregroundStyle(Color.green)
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

                    RuleMark(
                        y: .value("Goal Wake", goalWakeMinutes)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(Color.green.opacity(0.8))
                }
                .chartXScale(
                    domain: (dailyWakeTimes.first?.date ?? Date())...(dailyWakeTimes
                        .last?.date ?? Date())
                )
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intVal = value.as(Double.self) {
                                Text(minutesToHHmm(intVal))
                            }
                        }
                    }
                }
                .frame(height: 300)

                Divider()

                Text("Monthly Screen Time")
                    .font(.headline)

                Chart {
                    ForEach(dailyScreenTimes) { item in
                        LineMark(
                            x: .value("Day", item.date),
                            y: .value("Screen Time", item.screenMinutes)
                        )
                        .foregroundStyle(Color.blue)

                        PointMark(
                            x: .value("Day", item.date),
                            y: .value("Screen Time", item.screenMinutes)
                        )
                        .foregroundStyle(Color.blue)
                        .annotation {
                            if item.screenMinutes <= goalScreenTimeMinutes {
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

                    RuleMark(
                        y: .value("Goal Screen Time", goalScreenTimeMinutes)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundStyle(Color.blue.opacity(0.8))
                }
                .chartXScale(
                    domain: (dailyScreenTimes.first?.date ?? Date())...(dailyScreenTimes
                        .last?.date ?? Date())
                )
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intVal = value.as(Double.self) {
                                Text(minutesToHHmm(intVal))
                            }
                        }
                    }
                }
                .frame(height: 300)

                Spacer()
            }
            .padding()
        }
        .onAppear {
            healthDataManager.requestAuthorization()
            loadDailyData()
        }
    }

    private func loadDailyData() {
        healthDataManager.fetchAverageWakeTimes(byMonth: false) { dict in
            let sorted = dict.sorted(by: { $0.key < $1.key })
            let mapped = sorted.map { (date, minutes) in
                DailyWakeData(date: date, wakeMinutes: minutes)
            }
            dailyWakeTimes = mapped
        }

        healthDataManager.fetchAverageScreenTime(byMonth: false) { dict in
            let sorted = dict.sorted(by: { $0.key < $1.key })
            let mapped = sorted.map { (date, minutes) in
                DailyScreenData(date: date, screenMinutes: minutes)
            }
            dailyScreenTimes = mapped
        }
    }

    private func minutesToHHmm(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let remainder = Int(minutes) % 60
        return String(format: "%dh %02dm", hours, remainder)
    }
}

struct DailyWakeData: Identifiable {
    let id = UUID()
    let date: Date
    let wakeMinutes: Double
}

struct DailyScreenData: Identifiable {
    let id = UUID()
    let date: Date
    let screenMinutes: Double
}
