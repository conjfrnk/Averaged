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

    @State private var existingRecordMinutes: Int? = nil

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
                .onChange(of: selectedDate) { oldDate, newDate in
                    loadRecord(for: newDate)
                }

                Text(actionText)
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
                }
                loadRecord(for: selectedDate)
            }
        }
    }

    private var actionText: String {
        guard let minutes = existingRecordMinutes, minutes >= 0 else {
            return "Select Time Spent"
        }
        let hr = minutes / 60
        let mn = minutes % 60
        return String(format: "Edit Time Spent (previously %d:%02d)", hr, mn)
    }

    func loadRecord(for date: Date) {
        if let rec = manager.fetchRecord(for: date) {
            existingRecordMinutes = Int(rec.minutes)
            if rec.minutes >= 0 {
                let total = Int(rec.minutes)
                hours = total / 60
                mins = total % 60
            } else {
                hours = 0
                mins = 0
            }
        } else {
            existingRecordMinutes = nil
            hours = 0
            mins = 0
        }
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
