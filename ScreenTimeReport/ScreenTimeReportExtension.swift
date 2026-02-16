//
//  ScreenTimeReportExtension.swift
//  ScreenTimeReport
//
//  Created by Connor Frank on 2/16/26.
//

import DeviceActivity
import SwiftUI

@main
struct ScreenTimeReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { totalMinutes in
            TotalActivityView(totalMinutes: totalMinutes)
        }
    }
}
