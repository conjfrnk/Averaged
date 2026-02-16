//
//  TotalActivityReport.swift
//  ScreenTimeReport
//
//  Created by Connor Frank on 2/16/26.
//

import DeviceActivity
import SwiftUI

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (Double) -> TotalActivityView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> Double {
        var totalDuration: TimeInterval = 0

        for await dataItem in data {
            for await segment in dataItem.activitySegments {
                totalDuration += segment.totalActivityDuration
            }
        }

        let totalMinutes = totalDuration / 60.0

        // Write to App Group for main app to read
        if let defaults = UserDefaults(
            suiteName: "group.com.conjfrnk.Averaged")
        {
            let today = Calendar.current.startOfDay(for: Date())
            let key = "screenTime_\(today.timeIntervalSince1970)"
            defaults.set(totalMinutes, forKey: key)
            defaults.set(
                today.timeIntervalSince1970,
                forKey: "lastScreenTimeUpdate")
            defaults.synchronize()
        }

        return totalMinutes
    }
}
