//
//  ChartHelpers.swift
//  Averaged
//
//  Created by Connor Frank on 2/16/26.
//

import Foundation

/// Shared chart helper functions used across views

enum ChartConstants {
    static let minutesInDay = 1440
    static let defaultStride = 30
    static let wakeTimeStride = 30
    static let screenTimeStride = 60
}

func wakeTimeInMinutes(_ date: Date) -> Double {
    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
    return Double((comps.hour ?? 0) * 60 + (comps.minute ?? 0))
}

func minutesToHHmm(_ val: Double) -> String {
    let h = Int(val / 60)
    let m = Int(val) % 60
    return String(format: "%02d:%02d", h, m)
}

func chartYDomain(for values: [Double], goal: Double) -> ClosedRange<Double> {
    let allVals = values + [goal]
    if allVals.isEmpty {
        return 0...0
    }
    let stride = Double(ChartConstants.defaultStride)
    let minVal = allVals.min() ?? 0
    let maxVal = allVals.max() ?? Double(ChartConstants.minutesInDay)
    let minFloor = Double(Int(minVal / stride) * ChartConstants.defaultStride) - stride
    let maxCeil = Double(Int(maxVal / stride) * ChartConstants.defaultStride) + stride
    let lower = max(0, minFloor)
    let upper = min(Double(ChartConstants.minutesInDay), maxCeil)
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

func computeAverage(_ values: [Double]) -> Double? {
    guard !values.isEmpty else { return nil }
    let sum = values.reduce(0, +)
    let avg = sum / Double(values.count)
    if avg.isNaN || avg.isInfinite {
        return nil
    }
    return avg
}
