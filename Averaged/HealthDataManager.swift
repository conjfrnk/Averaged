//
//  HealthDataManager.swift
//  Averaged
//
//  Created by Connor Frank on 12/27/24.
//

import Foundation
import HealthKit
import SwiftUI

public class HealthDataManager: ObservableObject {
    @Published public var allWakeData: [WakeData] = []
    private let healthStore = HKHealthStore()
    private let sleepType = HKObjectType.categoryType(
        forIdentifier: .sleepAnalysis)!
    private let dayBoundaryHour = 14
    private let resultsQueue = DispatchQueue(label: "com.conjfrnk.averaged.results")

    public struct WakeData: Identifiable {
        public let id = UUID()
        public let date: Date
        public let wakeTime: Date?
    }

    public func requestAuthorization(
        completion: @escaping (Bool, Error?) -> Void
    ) {
        let toRead: Set<HKObjectType> = [sleepType]
        healthStore.requestAuthorization(toShare: nil, read: toRead) {
            success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    public func fetchWakeTimesOverLastNDays(
        _ days: Int, completion: @escaping () -> Void
    ) {
        guard days > 0 else {
            DispatchQueue.main.async {
                self.allWakeData = []
                completion()
            }
            return
        }
        let calendar = Calendar.current
        let now = Date()
        var results: [WakeData] = []
        let group = DispatchGroup()
        for i in 0..<days {
            group.enter()
            guard
                let targetDay = calendar.date(
                    byAdding: .day, value: -i, to: now)
            else {
                group.leave()
                continue
            }
            fetchWakeTime(for: targetDay) { [weak self] wake in
                let w = WakeData(date: targetDay, wakeTime: wake)
                self?.resultsQueue.sync { results.append(w) }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            let sorted = results.sorted { $0.date > $1.date }
            self.allWakeData = sorted
            completion()
        }
    }

    private func fetchWakeTime(
        for date: Date, completion: @escaping (Date?) -> Void
    ) {
        let calendar = Calendar.current
        let prevDay = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        let startTime =
            calendar.date(
                bySettingHour: dayBoundaryHour, minute: 0, second: 0,
                of: prevDay) ?? prevDay
        let endTime =
            calendar.date(
                bySettingHour: dayBoundaryHour, minute: 0, second: 0, of: date)
            ?? date
        let pred = HKQuery.predicateForSamples(
            withStart: startTime, end: endTime, options: .strictStartDate)
        let sortDescs = [
            NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate, ascending: true),
            NSSortDescriptor(
                key: HKSampleSortIdentifierEndDate, ascending: true),
        ]
        let query = HKSampleQuery(
            sampleType: sleepType, predicate: pred, limit: HKObjectQueryNoLimit,
            sortDescriptors: sortDescs
        ) { [weak self] _, samples, error in
            guard let self = self, error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            guard let rawSamples = samples as? [HKCategorySample],
                !rawSamples.isEmpty
            else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let bestSamples = self.pickBestSamples(from: rawSamples)
            let merged = self.mergeSleepSegments(bestSamples)
            let asleep = merged.filter {
                $0.stage == "Core" || $0.stage == "Deep" || $0.stage == "REM"
                    || $0.stage == "AsleepUnspecified"
            }
            guard !asleep.isEmpty else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let finalSeg = asleep.sorted { $0.endDate < $1.endDate }.last
            let wakeTime = finalSeg?.endDate
            DispatchQueue.main.async {
                completion(wakeTime)
            }
        }
        healthStore.execute(query)
    }

    private func pickBestSamples(from raw: [HKCategorySample])
        -> [HKCategorySample]
    {
        let grouped = Dictionary(grouping: raw) {
            $0.sourceRevision.source.bundleIdentifier
        }
        let best =
            grouped.max(by: { a, b in
                let aHasREM = a.value.contains {
                    $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                        || $0.value
                            == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                }
                let bHasREM = b.value.contains {
                    $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                        || $0.value
                            == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                }
                if aHasREM != bHasREM { return !aHasREM }
                return a.value.count < b.value.count
            })?.value ?? raw
        return best
    }

    private func mergeSleepSegments(_ raw: [HKCategorySample]) -> [(
        stage: String, startDate: Date, endDate: Date
    )] {
        let sorted = raw.sorted { $0.startDate < $1.startDate }
        var result: [(stage: String, startDate: Date, endDate: Date)] = []
        var current: (stage: String, start: Date, end: Date)?
        for s in sorted {
            let stageName: String
            switch s.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                stageName = "InBed"
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                stageName = "Awake"
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                stageName = "Core"
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                stageName = "Deep"
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                stageName = "REM"
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                stageName = "AsleepUnspecified"
            default:
                stageName = "Other"
            }
            if let c = current {
                if c.stage == stageName && s.startDate <= c.end {
                    let newEnd = max(c.end, s.endDate)
                    current = (stageName, c.start, newEnd)
                } else {
                    result.append((c.stage, c.start, c.end))
                    current = (stageName, s.startDate, s.endDate)
                }
            } else {
                current = (stageName, s.startDate, s.endDate)
            }
        }
        if let final = current {
            result.append((final.stage, final.start, final.end))
        }
        return result
    }
}
