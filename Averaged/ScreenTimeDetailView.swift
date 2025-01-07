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
    @State private var hours: Int = 0
    @State private var mins: Int = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Add or Edit Screen Time")
                    .font(.headline)
                DatePicker(
                    "Select Date", selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)

                Text("Select Time Spent")
                    .font(.subheadline)

                HStack(spacing: 20) {
                    VStack {
                        Text("Hours")
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<24, id: \.self) { hr in
                                Text("\(hr)").tag(hr)
                            }
                        }
                        .frame(width: 70, height: 120)
                        .clipped()
                        .pickerStyle(.wheel)
                    }
                    VStack {
                        Text("Minutes")
                        Picker("Minutes", selection: $mins) {
                            ForEach(
                                Array(stride(from: 0, through: 59, by: 5)),
                                id: \.self
                            ) { m in
                                Text("\(m)").tag(m)
                            }
                        }
                        .frame(width: 70, height: 120)
                        .clipped()
                        .pickerStyle(.wheel)
                    }
                }

                Button("Save") {
                    let totalMinutes = hours * 60 + mins
                    manager.addOrUpdateScreenTime(
                        date: selectedDate, minutes: totalMinutes)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)

                Button("Skip Day") {
                    manager.skipDay(date: selectedDate)
                    if let next = firstEmptyDayInCurrentYear() {
                        selectedDate = next
                        loadRecord(for: next)
                    } else {
                        dismiss()
                    }
                }
                .buttonStyle(.bordered)

                Divider()
                Text("Logged Screen Time")
                    .font(.headline)
                List {
                    ForEach(
                        manager.allScreenTimeData.sorted(by: {
                            $0.date ?? Date() > $1.date ?? Date()
                        })
                    ) { record in
                        HStack {
                            Text(dateString(record.date ?? Date()))
                            Spacer()
                            if record.minutes == -1 {
                                Text("Skipped")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(record.minutes) min")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onTapGesture {
                            if let d = record.date {
                                selectedDate = d
                                loadRecord(for: d)
                            }
                        }
                    }
                    .onDelete { indices in
                        let items = indices.map {
                            manager.allScreenTimeData[$0]
                        }
                        for item in items {
                            manager.delete(item)
                        }
                    }
                }
                Spacer()
            }
            .padding()
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
                    loadRecord(for: emptyDate)
                }
            }
        }
    }

    func loadRecord(for date: Date) {
        if let rec = manager.fetchRecord(for: date) {
            if rec.minutes >= 0 {
                let total = Int(rec.minutes)
                hours = total / 60
                mins = total % 60
            } else {
                hours = 0
                mins = 0
            }
        } else {
            hours = 0
            mins = 0
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
        guard
            let jan1 = cal.date(
                from: DateComponents(year: year, month: 1, day: 1))
        else { return nil }
        var day = jan1
        while day <= now {
            if !manager.isSkippedDay(day), manager.fetchRecord(for: day) == nil
            {
                return day
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else {
                break
            }
            day = next
        }
        return nil
    }
}
