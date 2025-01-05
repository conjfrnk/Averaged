//
//  SettingsView.swift
//  Averaged
//
//  Created by Connor Frank on 12/27/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode

    // Removed screenTimeGoal references entirely

    @State private var selectedWakeTime: Date = {
        // Default 6:00 AM
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    @State private var wakeScrollOffset: CGFloat = 0
    @State private var lastWakeDragValue: CGFloat = 0

    private let wakeTimeOptions: [Date] = {
        var times: [Date] = []
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: Date())!
        // e.g. from 4:00 AM to 4:00 PM in 15-minute increments
        for minutes in stride(from: 0, through: 12 * 60, by: 15) {
            if let time = calendar.date(byAdding: .minute, value: minutes, to: startTime) {
                times.append(time)
            }
        }
        return times
    }()

    private let itemWidth: CGFloat = 80
    private let itemSpacing: CGFloat = 20
    private var totalItemWidth: CGFloat { itemWidth + itemSpacing }

    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Text("Settings")
                    .font(.largeTitle)
                    .padding(.top)

                // --- Only the Wake Time Carousel remains ---
                VStack(spacing: 16) {
                    Text("Goal Wake Time: \(formattedTime(selectedWakeTime))")
                        .font(.headline)

                    GeometryReader { geometry in
                        let center = geometry.size.width / 2
                        ZStack {
                            // Highlight box
                            Rectangle()
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: itemWidth, height: 50)
                                .position(x: center, y: 50)

                            // Horizontal “carousel” of possible times
                            HStack(spacing: itemSpacing) {
                                ForEach(wakeTimeOptions.indices, id: \.self) { index in
                                    let time = wakeTimeOptions[index]
                                    VStack {
                                        Text(formattedTime(time))
                                            .font(.system(size: 16, weight: .bold))
                                            .frame(width: itemWidth, height: 50)
                                    }
                                    .frame(width: itemWidth, height: 50)
                                    .scaleEffect(
                                        scaleEffectForItem(
                                            at: index,
                                            offset: wakeScrollOffset,
                                            centerX: center)
                                    )
                                    .rotation3DEffect(
                                        rotationAngleForItem(
                                            at: index,
                                            offset: wakeScrollOffset,
                                            centerX: center),
                                        axis: (x: 0, y: 1, z: 0),
                                        anchor: .center,
                                        perspective: 0.5
                                    )
                                    .opacity(
                                        opacityForItem(
                                            at: index,
                                            offset: wakeScrollOffset,
                                            centerX: center)
                                    )
                                    .onTapGesture {
                                        selectWakeTime(at: index)
                                    }
                                }
                            }
                            .padding(.horizontal, (geometry.size.width - itemWidth) / 2)
                            .offset(x: wakeScrollOffset)
                            .gesture(createDragGesture())
                        }
                    }
                    .frame(height: 100)
                }

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                initializeSettings()
            }
        }
    }
}

extension SettingsView {
    private func createDragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                wakeScrollOffset = lastWakeDragValue + value.translation.width
            }
            .onEnded { value in
                let totalTranslation =
                    value.translation.width
                    + (value.predictedEndTranslation.width - value.translation.width)
                let predictedEndOffset = lastWakeDragValue + totalTranslation
                // Snap to the nearest wakeTimeOptions index
                var centerIndex = Int(round(-predictedEndOffset / totalItemWidth))
                centerIndex = max(0, min(centerIndex, wakeTimeOptions.count - 1))

                // Update user defaults
                withTransaction(Transaction(animation: .none)) {
                    selectedWakeTime = wakeTimeOptions[centerIndex]
                    UserDefaults.standard.set(
                        selectedWakeTime.timeIntervalSince1970,
                        forKey: "goalWakeTime"
                    )
                }

                // Snap the carousel
                withAnimation(.interpolatingSpring(stiffness: 100, damping: 15)) {
                    let targetOffset = -CGFloat(centerIndex) * totalItemWidth
                    wakeScrollOffset = targetOffset
                    lastWakeDragValue = wakeScrollOffset
                }
            }
    }

    private func initializeSettings() {
        // Initialize wake time with 6:00 AM default
        let storedWakeTimeInterval = UserDefaults.standard.double(forKey: "goalWakeTime")
        let storedWakeTime: Date
        if storedWakeTimeInterval == 0 {
            // 6:00 AM default if none stored
            let cal = Calendar.current
            storedWakeTime = cal.date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date()
            UserDefaults.standard.set(storedWakeTime.timeIntervalSince1970, forKey: "goalWakeTime")
        } else {
            storedWakeTime = Date(timeIntervalSince1970: storedWakeTimeInterval)
        }

        if let initialIndex = findClosestWakeTimeIndex(for: storedWakeTime) {
            selectedWakeTime = wakeTimeOptions[initialIndex]
            let targetOffset = -CGFloat(initialIndex) * totalItemWidth
            wakeScrollOffset = targetOffset
            lastWakeDragValue = wakeScrollOffset
        }
    }

    private func findClosestWakeTimeIndex(for date: Date) -> Int? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)

        return wakeTimeOptions.firstIndex { option in
            let c = calendar.dateComponents([.hour, .minute], from: option)
            let mins = (c.hour ?? 0) * 60 + (c.minute ?? 0)
            return mins >= minutes
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func scaleEffectForItem(
        at index: Int,
        offset: CGFloat,
        centerX: CGFloat
    ) -> CGFloat {
        let itemPosition = CGFloat(index) * totalItemWidth
            + offset
            + ((UIScreen.main.bounds.width - itemWidth) / 2)
            + (itemWidth / 2)
        let distance = abs(itemPosition - centerX)
        let maxDistance = UIScreen.main.bounds.width / 2
        return max(0.7, 1 - (distance / maxDistance) * 0.3)
    }

    private func rotationAngleForItem(
        at index: Int,
        offset: CGFloat,
        centerX: CGFloat
    ) -> Angle {
        let itemPosition = CGFloat(index) * totalItemWidth
            + offset
            + ((UIScreen.main.bounds.width - itemWidth) / 2)
            + (itemWidth / 2)
        let angle = Double((itemPosition - centerX) / UIScreen.main.bounds.width) * 30
        return Angle(degrees: angle)
    }

    private func opacityForItem(
        at index: Int,
        offset: CGFloat,
        centerX: CGFloat
    ) -> Double {
        let itemPosition = CGFloat(index) * totalItemWidth
            + offset
            + ((UIScreen.main.bounds.width - itemWidth) / 2)
            + (itemWidth / 2)
        let distance = abs(itemPosition - centerX)
        let maxDistance = UIScreen.main.bounds.width / 2
        return Double(max(0.5, 1 - (distance / maxDistance)))
    }

    private func selectWakeTime(at index: Int) {
        withTransaction(Transaction(animation: .none)) {
            selectedWakeTime = wakeTimeOptions[index]
            UserDefaults.standard.set(
                selectedWakeTime.timeIntervalSince1970,
                forKey: "goalWakeTime"
            )
        }
        withAnimation(.easeOut) {
            let targetOffset = -CGFloat(index) * totalItemWidth
            wakeScrollOffset = targetOffset
            lastWakeDragValue = wakeScrollOffset
        }
    }
}
