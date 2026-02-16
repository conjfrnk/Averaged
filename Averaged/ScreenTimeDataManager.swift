//
//  ScreenTimeDataManager.swift
//  Averaged
//
//  Created by Connor Frank on 1/6/25.
//

import CoreData
import SwiftUI

class ScreenTimeDataManager: ObservableObject {
    static let shared = ScreenTimeDataManager()
    let container: NSPersistentContainer
    @Published var allScreenTimeData: [ScreenTimeRecord] = []

    var validScreenTimeData: [ScreenTimeRecord] {
        allScreenTimeData.filter { $0.minutes >= 0 }
    }

    private init() {
        container = NSPersistentContainer(name: "ScreenTimeModel")
        container.loadPersistentStores { _, _ in }
        fetchAllScreenTime()
    }

    func fetchAllScreenTime() {
        let request: NSFetchRequest<ScreenTimeRecord> =
            ScreenTimeRecord.fetchRequest()
        let sort = NSSortDescriptor(key: "date", ascending: false)
        request.sortDescriptors = [sort]
        if let results = try? container.viewContext.fetch(request) {
            allScreenTimeData = results
        } else {
            allScreenTimeData = []
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
        let dayEnd = Calendar.current.date(
            byAdding: .day, value: 1, to: dayStart)!
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@", dayStart as NSDate,
            dayEnd as NSDate)
        request.fetchLimit = 1
        return (try? container.viewContext.fetch(request))?.first
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
        try? container.viewContext.save()
        fetchAllScreenTime()
    }
}
