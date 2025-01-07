//
//  WakeDataModels.swift
//  Averaged
//
//  Created by Connor Frank on 1/6/25.
//

import Foundation

struct DailyWakeData: Identifiable {
    let id = UUID()
    let date: Date
    let wakeMinutes: Double
}

struct MonthlyWakeData: Identifiable {
    let id = UUID()
    let date: Date
    let wakeMinutes: Double
}
