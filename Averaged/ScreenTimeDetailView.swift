//
//  ScreenTimeDetailView.swift
//  Averaged
//
//  Created by Connor Frank on 1/6/25.
//

import SwiftUI

struct ScreenTimeDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager = ScreenTimeDataManager.shared
    @AppStorage("screenTimeGoal") private var screenTimeGoal: Int = 120
    @State private var selectedDate = Date()
    @State private var minutes: Int = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Add or Edit Screen Time")
                    .font(.headline)
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                Stepper("Minutes: \(minutes)", value: $minutes, in: 0...1440, step: 15)
                    .padding()
                Button("Save") {
                    manager.addOrUpdateScreenTime(date: selectedDate, minutes: minutes)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                Divider()
                Text("Logged Screen Time")
                    .font(.headline)
                List {
                    ForEach(manager.allScreenTimeData.sorted(by: { $0.date ?? Date() > $1.date ?? Date() })) { record in
                        HStack {
                            Text(dateString(record.date ?? Date()))
                            Spacer()
                            Text("\(record.minutes) min")
                                .foregroundColor(.secondary)
                        }
                        .onTapGesture {
                            if let d = record.date {
                                selectedDate = d
                            }
                            minutes = Int(record.minutes)
                        }
                    }
                    .onDelete { indices in
                        let items = indices.map { manager.allScreenTimeData[$0] }
                        for item in items {
                            manager.delete(item)
                        }
                    }
                }
                Spacer()
            }
            .padding()
            .navigationBarTitle("Screen Time Details", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let emptyDate = firstEmptyDayInCurrentYear() {
                    selectedDate = emptyDate
                }
            }
        }
    }

    func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    func firstEmptyDayInCurrentYear() -> Date? {
        let cal = Calendar.current
        let now = Date()
        let year = cal.component(.year, from: now)
        guard let jan1 = cal.date(from: DateComponents(year: year, month: 1, day: 1)) else { return nil }
        var day = jan1
        while day <= now {
            if manager.fetchRecord(for: day) == nil {
                return day
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return nil
    }
}
