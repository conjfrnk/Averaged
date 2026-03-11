//
//  ScreenTimeDataManager.swift
//  Averaged
//
//  Created by Connor Frank on 1/6/25.
//

import CoreData
import os.log
import SwiftUI

class ScreenTimeDataManager: ObservableObject {
    static let shared = ScreenTimeDataManager()
    private static let logger = Logger(subsystem: "com.conjfrnk.Averaged", category: "CoreData")
    private let container: NSPersistentContainer
    @Published var allScreenTimeData: [ScreenTimeRecord] = []
    @Published var dataError: Error?

    var validScreenTimeData: [ScreenTimeRecord] {
        allScreenTimeData.filter { $0.minutes >= 0 }
    }

    private init() {
        container = NSPersistentContainer(name: "ScreenTimeModel")
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                Self.logger.error("Failed to load persistent stores: \(error.localizedDescription, privacy: .public)")
                DispatchQueue.main.async {
                    self?.dataError = error
                }
            } else {
                DispatchQueue.main.async {
                    self?.fetchAllScreenTime()
                }
            }
        }
    }

    func fetchAllScreenTime() {
        let request: NSFetchRequest<ScreenTimeRecord> =
            ScreenTimeRecord.fetchRequest()
        let sort = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [sort]
        do {
            allScreenTimeData = try container.viewContext.fetch(request)
            dataError = nil
        } catch {
            Self.logger.error("Failed to fetch screen time: \(error.localizedDescription, privacy: .public)")
            allScreenTimeData = []
            dataError = error
        }
    }

    func addOrUpdateScreenTime(date: Date, minutes: Int) {
        let record =
            fetchRecord(for: date)
            ?? ScreenTimeRecord(context: container.viewContext)
        record.date = Calendar.current.startOfDay(for: date)
        record.minutes = Int32(minutes)
        saveContext()
    }

    func skipDay(date: Date) {
        let record =
            fetchRecord(for: date)
            ?? ScreenTimeRecord(context: container.viewContext)
        record.date = Calendar.current.startOfDay(for: date)
        record.minutes = -1
        saveContext()
    }

    func fetchRecord(for date: Date) -> ScreenTimeRecord? {
        let request: NSFetchRequest<ScreenTimeRecord> =
            ScreenTimeRecord.fetchRequest()
        let dayStart = Calendar.current.startOfDay(for: date)
        guard let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) else { return nil }
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@", dayStart as NSDate,
            dayEnd as NSDate)
        request.fetchLimit = 1
        do {
            return try container.viewContext.fetch(request).first
        } catch {
            Self.logger.error("Failed to fetch record for \(date): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func isSkippedDay(_ date: Date) -> Bool {
        if let rec = fetchRecord(for: date) {
            return rec.minutes == -1
        }
        return false
    }

    func delete(_ record: ScreenTimeRecord) {
        container.viewContext.delete(record)
        saveContext()
    }

    private func saveContext() {
        do {
            try container.viewContext.save()
        } catch {
            Self.logger.error("Failed to save context: \(error.localizedDescription, privacy: .public)")
        }
        fetchAllScreenTime()
    }
}
