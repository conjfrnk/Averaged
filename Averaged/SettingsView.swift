//
//  SettingsView.swift
//  Averaged
//
//  Created by Connor Frank on 12/27/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedScreenTimeGoal: Int = 2 * 60  // 2 hours default
    @State private var screenTimeScrollOffset: CGFloat = 0
    @State private var lastScreenTimeDragValue: CGFloat = 0

    private let screenTimeGoals = Array(stride(from: 60, through: 720, by: 15))  // 60min (1h) -> 720min (12h)

    @State private var selectedWakeTime: Date =
        Calendar.current.date(
            bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var wakeScrollOffset: CGFloat = 0
    @State private var lastWakeDragValue: CGFloat = 0

    private let wakeTimeOptions: [Date] = {
        var times: [Date] = []
        let calendar = Calendar.current
        let startTime = calendar.date(
            bySettingHour: 4, minute: 0, second: 0, of: Date())!
        for minutes in stride(from: 0, through: 12 * 60, by: 15) {
            if let time = calendar.date(
                byAdding: .minute, value: minutes, to: startTime)
            {
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

                VStack(spacing: 16) {
                    Text(
                        "Screen Time Goal: \(formattedScreenTimeGoal(minutes: selectedScreenTimeGoal))"
                    )
                    .font(.headline)

                    GeometryReader { geometry in
                        let center = geometry.size.width / 2
                        ZStack {
                            Rectangle()
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: itemWidth, height: 50)
                                .position(x: center, y: 50)

                            HStack(spacing: itemSpacing) {
                                ForEach(screenTimeGoals.indices, id: \.self) {
                                    index in
                                    let goal = screenTimeGoals[index]
                                    VStack {
                                        Text(
                                            formattedScreenTimeGoal(
                                                minutes: goal)
                                        )
                                        .font(.system(size: 16, weight: .bold))
                                        .frame(width: itemWidth, height: 50)
                                    }
                                    .frame(width: itemWidth, height: 50)
                                    .scaleEffect(
                                        scaleEffectForItem(
                                            at: index,
                                            offset: screenTimeScrollOffset,
                                            centerX: center)
                                    )
                                    .rotation3DEffect(
                                        rotationAngleForItem(
                                            at: index,
                                            offset: screenTimeScrollOffset,
                                            centerX: center),
                                        axis: (x: 0, y: 1, z: 0),
                                        anchor: .center,
                                        perspective: 0.5
                                    )
                                    .opacity(
                                        opacityForItem(
                                            at: index,
                                            offset: screenTimeScrollOffset,
                                            centerX: center)
                                    )
                                    .onTapGesture {
                                        selectScreenTimeGoal(at: index)
                                    }
                                }
                            }
                            .padding(
                                .horizontal,
                                (geometry.size.width - itemWidth) / 2
                            )
                            .offset(x: screenTimeScrollOffset)
                            .gesture(createDragGesture(for: .screenTime))
                        }
                    }
                    .frame(height: 100)
                }

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
                                ForEach(wakeTimeOptions.indices, id: \.self) {
                                    index in
                                    let time = wakeTimeOptions[index]
                                    VStack {
                                        Text(formattedTime(time))
                                            .font(
                                                .system(size: 16, weight: .bold)
                                            )
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
                            .padding(
                                .horizontal,
                                (geometry.size.width - itemWidth) / 2
                            )
                            .offset(x: wakeScrollOffset)
                            .gesture(createDragGesture(for: .wake))
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

    private enum ScrollType {
        case screenTime
        case wake
    }

    private func createDragGesture(for type: ScrollType) -> some Gesture {
        DragGesture()
            .onChanged { value in
                switch type {
                case .screenTime:
                    screenTimeScrollOffset =
                        lastScreenTimeDragValue + value.translation.width
                case .wake:
                    wakeScrollOffset =
                        lastWakeDragValue + value.translation.width
                }
            }
            .onEnded { value in
                let totalTranslation =
                    value.translation.width
                    + (value.predictedEndTranslation.width
                        - value.translation.width)

                switch type {
                case .screenTime:
                    let predictedEndOffset =
                        lastScreenTimeDragValue + totalTranslation
                    var centerIndex = Int(
                        round(-predictedEndOffset / totalItemWidth))
                    centerIndex = max(
                        0, min(centerIndex, screenTimeGoals.count - 1))

                    // Update the user’s screen time goal
                    withTransaction(Transaction(animation: .none)) {
                        selectedScreenTimeGoal = screenTimeGoals[centerIndex]
                        UserDefaults.standard.set(
                            selectedScreenTimeGoal, forKey: "screenTimeGoal")
                    }

                    // Snap to the selected item
                    withAnimation(
                        .interpolatingSpring(stiffness: 100, damping: 15)
                    ) {
                        let targetOffset =
                            -CGFloat(centerIndex) * totalItemWidth
                        screenTimeScrollOffset = targetOffset
                        lastScreenTimeDragValue = screenTimeScrollOffset
                    }

                case .wake:
                    let predictedEndOffset =
                        lastWakeDragValue + totalTranslation
                    var centerIndex = Int(
                        round(-predictedEndOffset / totalItemWidth))
                    centerIndex = max(
                        0, min(centerIndex, wakeTimeOptions.count - 1))

                    // Update the user’s wake time
                    withTransaction(Transaction(animation: .none)) {
                        selectedWakeTime = wakeTimeOptions[centerIndex]
                        UserDefaults.standard.set(
                            selectedWakeTime.timeIntervalSince1970,
                            forKey: "goalWakeTime")
                    }

                    // Snap to the selected item
                    withAnimation(
                        .interpolatingSpring(stiffness: 100, damping: 15)
                    ) {
                        let targetOffset =
                            -CGFloat(centerIndex) * totalItemWidth
                        wakeScrollOffset = targetOffset
                        lastWakeDragValue = wakeScrollOffset
                    }
                }
            }
    }
}

extension SettingsView {
    private func initializeSettings() {
        // Initialize Screen Time Goal
        let storedScreenTimeGoal = UserDefaults.standard.integer(
            forKey: "screenTimeGoal")
        if storedScreenTimeGoal != 0,
            let initialIndex = screenTimeGoals.firstIndex(
                of: storedScreenTimeGoal)
        {
            selectedScreenTimeGoal = storedScreenTimeGoal
            let targetOffset = -CGFloat(initialIndex) * totalItemWidth
            screenTimeScrollOffset = targetOffset
            lastScreenTimeDragValue = screenTimeScrollOffset
        } else if let initialIndex = screenTimeGoals.firstIndex(of: 2 * 60) {
            // Default to 2 hours if none is stored
            selectedScreenTimeGoal = 2 * 60
            let targetOffset = -CGFloat(initialIndex) * totalItemWidth
            screenTimeScrollOffset = targetOffset
            lastScreenTimeDragValue = screenTimeScrollOffset
        }

        // Initialize wake time with 6:00 AM default
        let storedWakeTimeInterval = UserDefaults.standard.double(
            forKey: "goalWakeTime")
        let storedWakeTime: Date
        if storedWakeTimeInterval == 0 {
            // Set default 6:00 AM if not set
            storedWakeTime =
                Calendar.current.date(
                    bySettingHour: 6, minute: 0, second: 0, of: Date())
                ?? Date()
            UserDefaults.standard.set(
                storedWakeTime.timeIntervalSince1970, forKey: "goalWakeTime")
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
            let optionComponents = calendar.dateComponents(
                [.hour, .minute], from: option)
            let optionMinutes =
                (optionComponents.hour ?? 0) * 60
                + (optionComponents.minute ?? 0)
            return optionMinutes >= minutes
        }
    }
}

extension SettingsView {
    private func formattedScreenTimeGoal(minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func scaleEffectForItem(
        at index: Int, offset: CGFloat, centerX: CGFloat
    ) -> CGFloat {
        let itemPosition =
            CGFloat(index) * totalItemWidth
            + offset
            + ((UIScreen.main.bounds.width - itemWidth) / 2)
            + (itemWidth / 2)
        let distance = abs(itemPosition - centerX)
        let maxDistance = UIScreen.main.bounds.width / 2
        return max(0.7, 1 - (distance / maxDistance) * 0.3)
    }

    private func rotationAngleForItem(
        at index: Int, offset: CGFloat, centerX: CGFloat
    ) -> Angle {
        let itemPosition =
            CGFloat(index) * totalItemWidth
            + offset
            + ((UIScreen.main.bounds.width - itemWidth) / 2)
            + (itemWidth / 2)
        let angle =
            Double((itemPosition - centerX) / UIScreen.main.bounds.width) * 30
        return Angle(degrees: angle)
    }

    private func opacityForItem(
        at index: Int, offset: CGFloat, centerX: CGFloat
    ) -> Double {
        let itemPosition =
            CGFloat(index) * totalItemWidth
            + offset
            + ((UIScreen.main.bounds.width - itemWidth) / 2)
            + (itemWidth / 2)
        let distance = abs(itemPosition - centerX)
        let maxDistance = UIScreen.main.bounds.width / 2
        return Double(max(0.5, 1 - (distance / maxDistance)))
    }

    private func selectScreenTimeGoal(at index: Int) {
        withTransaction(Transaction(animation: .none)) {
            selectedScreenTimeGoal = screenTimeGoals[index]
            UserDefaults.standard.set(
                selectedScreenTimeGoal, forKey: "screenTimeGoal")
        }
        withAnimation(.easeOut) {
            let targetOffset = -CGFloat(index) * totalItemWidth
            screenTimeScrollOffset = targetOffset
            lastScreenTimeDragValue = screenTimeScrollOffset
        }
    }

    private func selectWakeTime(at index: Int) {
        withTransaction(Transaction(animation: .none)) {
            selectedWakeTime = wakeTimeOptions[index]
            UserDefaults.standard.set(
                selectedWakeTime.timeIntervalSince1970, forKey: "goalWakeTime")
        }
        withAnimation(.easeOut) {
            let targetOffset = -CGFloat(index) * totalItemWidth
            wakeScrollOffset = targetOffset
            lastWakeDragValue = wakeScrollOffset
        }
    }
}
