//
//  HealthDataManager.swift
//  Averaged
//
//  Created by Connor Frank on 12/27/24.
//

import Foundation
import HealthKit

class HealthDataManager: ObservableObject {
    private let healthStore = HKHealthStore()

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard
            let sleepType = HKObjectType.categoryType(
                forIdentifier: .sleepAnalysis)
        else { return }
        let typesToRead: Set<HKObjectType> = [sleepType]
        healthStore.requestAuthorization(toShare: [], read: typesToRead) {
            success, error in
        }
    }

    func fetchAverageWakeTimes(
        byMonth: Bool, completion: @escaping ([Date: Double]) -> Void
    ) {
        guard
            let sleepType = HKObjectType.categoryType(
                forIdentifier: .sleepAnalysis)
        else {
            DispatchQueue.main.async { completion([:]) }
            return
        }
        let calendar = Calendar.current
        let now = Date()
        var startDate: Date
        if byMonth {
            startDate =
                calendar.date(byAdding: .month, value: -12, to: now) ?? now
        } else {
            startDate =
                calendar.date(byAdding: .day, value: -30, to: now) ?? now
        }
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate, end: now, options: .strictStartDate)
        let query = HKSampleQuery(
            sampleType: sleepType, predicate: predicate,
            limit: HKObjectQueryNoLimit, sortDescriptors: nil
        ) { [weak self] _, samples, _ in
            guard let self = self, let samples = samples as? [HKCategorySample]
            else {
                DispatchQueue.main.async { completion([:]) }
                return
            }
            var wakeTimes: [Date: [Double]] = [:]
            let grouped = self.groupSamples(samples, byMonth: byMonth)
            for (keyDate, group) in grouped {
                let times = self.extractWakeTimes(from: group)
                wakeTimes[keyDate] = times
            }
            var result: [Date: Double] = [:]
            for (keyDate, times) in wakeTimes {
                let avg = times.reduce(0, +) / Double(times.count)
                result[keyDate] = avg
            }
            DispatchQueue.main.async {
                completion(result)
            }
        }
        healthStore.execute(query)
    }

    private func groupSamples(_ samples: [HKCategorySample], byMonth: Bool)
        -> [Date: [HKCategorySample]]
    {
        var grouped: [Date: [HKCategorySample]] = [:]
        let calendar = Calendar.current
        for sample in samples {
            let comps: DateComponents
            if byMonth {
                let date = sample.endDate
                comps = calendar.dateComponents([.year, .month], from: date)
                let startOfMonth = calendar.date(from: comps) ?? date
                grouped[startOfMonth, default: []].append(sample)
            } else {
                let day = calendar.startOfDay(for: sample.endDate)
                grouped[day, default: []].append(sample)
            }
        }
        return grouped
    }

    private func extractWakeTimes(from samples: [HKCategorySample]) -> [Double]
    {
        var times: [Double] = []
        let calendar = Calendar.current

        for s in samples {
            // Check if sample is "asleep" or "asleepUnspecified"
            if s.value == HKCategoryValueSleepAnalysis.asleep.rawValue
                || s.value
                    == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
            {

                let comps = calendar.dateComponents(
                    [.hour, .minute], from: s.endDate)
                let minutes = Double(
                    (comps.hour ?? 0) * 60 + (comps.minute ?? 0))
                times.append(minutes)
            }
        }

        return times
    }

    func fetchAverageScreenTime(
        byMonth: Bool, completion: @escaping ([Date: Double]) -> Void
    ) {
        var result: [Date: Double] = [:]
        let calendar = Calendar.current
        if byMonth {
            for monthOffset in 0..<12 {
                if let date = calendar.date(
                    byAdding: .month, value: -monthOffset, to: Date())
                {
                    let randomUsage = Double.random(in: 60...300)
                    let startOfMonth = calendar.date(
                        from: calendar.dateComponents(
                            [.year, .month], from: date))!
                    result[startOfMonth] = randomUsage
                }
            }
        } else {
            for dayOffset in 0..<30 {
                if let date = calendar.date(
                    byAdding: .day, value: -dayOffset, to: Date())
                {
                    let randomUsage = Double.random(in: 60...300)
                    let startOfDay = calendar.startOfDay(for: date)
                    result[startOfDay] = randomUsage
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(result)
        }
    }
}
