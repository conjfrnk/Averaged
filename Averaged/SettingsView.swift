//
//  SettingsView.swift
//  Averaged
//
//  Created by Connor Frank on 12/27/24.
//

import SwiftUI

extension Notification.Name {
    static let didChangeGoalTime = Notification.Name("didChangeGoalTime")
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    static var didChangeGoalTime = false

    @State private var selectedWakeTime: Date = {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 6, minute: 0, second: 0, of: Date())
            ?? Date()
    }()
    @State private var wakeScrollOffset: CGFloat = 0
    @State private var lastWakeDragValue: CGFloat = 0

    @AppStorage("screenTimeGoal") private var selectedScreenTimeGoal: Int = 120
    @State private var screenTimeScrollOffset: CGFloat = 0
    @State private var lastScreenTimeDragValue: CGFloat = 0

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

    private let screenTimeOptions: [Int] = {
        var arr: [Int] = []
        for min in stride(from: 0, through: 1440, by: 15) {
            arr.append(min)
        }
        return arr
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
                    Text("Goal Wake Time: \(formattedTime(selectedWakeTime))")
                        .font(.headline)
                    GeometryReader { geometry in
                        let center = geometry.size.width / 2
                        ZStack {
                            Rectangle()
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: itemWidth, height: 50)
                                .position(x: center, y: 50)
                            HStack(spacing: itemSpacing) {
                                ForEach(wakeTimeOptions.indices, id: \.self) {
                                    i in
                                    let time = wakeTimeOptions[i]
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
                                            i, offset: wakeScrollOffset,
                                            centerX: center)
                                    )
                                    .rotation3DEffect(
                                        rotationAngleForItem(
                                            i, offset: wakeScrollOffset,
                                            centerX: center),
                                        axis: (x: 0, y: 1, z: 0),
                                        anchor: .center, perspective: 0.5
                                    )
                                    .opacity(
                                        opacityForItem(
                                            i, offset: wakeScrollOffset,
                                            centerX: center)
                                    )
                                    .onTapGesture {
                                        selectWakeTime(i)
                                    }
                                }
                            }
                            .padding(
                                .horizontal,
                                (geometry.size.width - itemWidth) / 2
                            )
                            .offset(x: wakeScrollOffset)
                            .gesture(createWakeDragGesture())
                        }
                    }
                    .frame(height: 100)
                }

                VStack(spacing: 16) {
                    Text(
                        "Goal Screen Time: \(formattedScreenTime(selectedScreenTimeGoal))"
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
                                ForEach(screenTimeOptions.indices, id: \.self) {
                                    idx in
                                    let val = screenTimeOptions[idx]
                                    VStack {
                                        Text(formattedScreenTime(val))
                                            .font(
                                                .system(size: 16, weight: .bold)
                                            )
                                            .frame(width: itemWidth, height: 50)
                                    }
                                    .frame(width: itemWidth, height: 50)
                                    .scaleEffect(
                                        scaleEffectForItem(
                                            idx, offset: screenTimeScrollOffset,
                                            centerX: center)
                                    )
                                    .rotation3DEffect(
                                        rotationAngleForItem(
                                            idx, offset: screenTimeScrollOffset,
                                            centerX: center),
                                        axis: (x: 0, y: 1, z: 0),
                                        anchor: .center, perspective: 0.5
                                    )
                                    .opacity(
                                        opacityForItem(
                                            idx, offset: screenTimeScrollOffset,
                                            centerX: center)
                                    )
                                    .onTapGesture {
                                        selectScreenTimeGoal(idx)
                                    }
                                }
                            }
                            .padding(
                                .horizontal,
                                (geometry.size.width - itemWidth) / 2
                            )
                            .offset(x: screenTimeScrollOffset)
                            .gesture(createScreenTimeDragGesture())
                        }
                    }
                    .frame(height: 100)
                }

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                initializeWakeSettings()
                initializeScreenTimeSettings()
            }
            .onDisappear {
                if Self.didChangeGoalTime {
                    NotificationCenter.default.post(
                        name: .didChangeGoalTime, object: nil)
                    Self.didChangeGoalTime = false
                }
            }
        }
    }

    private func selectWakeTime(_ index: Int) {
        withTransaction(Transaction(animation: .none)) {
            selectedWakeTime = wakeTimeOptions[index]
            UserDefaults.standard.set(
                selectedWakeTime.timeIntervalSince1970, forKey: "goalWakeTime")
            Self.didChangeGoalTime = true
        }
        withAnimation(.easeOut) {
            let targetOffset = -CGFloat(index) * totalItemWidth
            wakeScrollOffset = targetOffset
            lastWakeDragValue = wakeScrollOffset
        }
    }

    private func selectScreenTimeGoal(_ index: Int) {
        withTransaction(Transaction(animation: .none)) {
            let val = screenTimeOptions[index]
            selectedScreenTimeGoal = val
            UserDefaults.standard.set(val, forKey: "screenTimeGoal")
            Self.didChangeGoalTime = true
        }
        withAnimation(.easeOut) {
            let targetOffset = -CGFloat(index) * totalItemWidth
            screenTimeScrollOffset = targetOffset
            lastScreenTimeDragValue = screenTimeScrollOffset
        }
    }

    private func createWakeDragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                wakeScrollOffset = lastWakeDragValue + value.translation.width
            }
            .onEnded { value in
                let totalTranslation =
                    value.translation.width
                    + (value.predictedEndTranslation.width
                        - value.translation.width)
                let predictedEndOffset = lastWakeDragValue + totalTranslation
                var centerIndex = Int(
                    round(-predictedEndOffset / totalItemWidth))
                centerIndex = max(
                    0, min(centerIndex, wakeTimeOptions.count - 1))
                withTransaction(Transaction(animation: .none)) {
                    selectedWakeTime = wakeTimeOptions[centerIndex]
                    UserDefaults.standard.set(
                        selectedWakeTime.timeIntervalSince1970,
                        forKey: "goalWakeTime")
                    Self.didChangeGoalTime = true
                }
                withAnimation(.interpolatingSpring(stiffness: 100, damping: 15))
                {
                    let targetOffset = -CGFloat(centerIndex) * totalItemWidth
                    wakeScrollOffset = targetOffset
                    lastWakeDragValue = wakeScrollOffset
                }
            }
    }

    private func createScreenTimeDragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                screenTimeScrollOffset =
                    lastScreenTimeDragValue + value.translation.width
            }
            .onEnded { value in
                let totalTranslation =
                    value.translation.width
                    + (value.predictedEndTranslation.width
                        - value.translation.width)
                let predictedEndOffset =
                    lastScreenTimeDragValue + totalTranslation
                var centerIndex = Int(
                    round(-predictedEndOffset / totalItemWidth))
                centerIndex = max(
                    0, min(centerIndex, screenTimeOptions.count - 1))
                withTransaction(Transaction(animation: .none)) {
                    let val = screenTimeOptions[centerIndex]
                    selectedScreenTimeGoal = val
                    UserDefaults.standard.set(val, forKey: "screenTimeGoal")
                    Self.didChangeGoalTime = true
                }
                withAnimation(.interpolatingSpring(stiffness: 100, damping: 15))
                {
                    let targetOffset = -CGFloat(centerIndex) * totalItemWidth
                    screenTimeScrollOffset = targetOffset
                    lastScreenTimeDragValue = screenTimeScrollOffset
                }
            }
    }

    private func initializeWakeSettings() {
        let stored = UserDefaults.standard.double(forKey: "goalWakeTime")
        let storedWakeTime: Date
        if stored == 0 {
            let cal = Calendar.current
            storedWakeTime =
                cal.date(bySettingHour: 6, minute: 0, second: 0, of: Date())
                ?? Date()
            UserDefaults.standard.set(
                storedWakeTime.timeIntervalSince1970, forKey: "goalWakeTime")
        } else {
            storedWakeTime = Date(timeIntervalSince1970: stored)
        }
        if let i = findClosestWakeTimeIndex(for: storedWakeTime) {
            selectedWakeTime = wakeTimeOptions[i]
            let targetOffset = -CGFloat(i) * totalItemWidth
            wakeScrollOffset = targetOffset
            lastWakeDragValue = wakeScrollOffset
        }
    }

    private func initializeScreenTimeSettings() {
        let val = UserDefaults.standard.integer(forKey: "screenTimeGoal")
        if val == 0 {
            selectedScreenTimeGoal = 120
            UserDefaults.standard.set(120, forKey: "screenTimeGoal")
        } else {
            selectedScreenTimeGoal = val
        }
        if let i = screenTimeOptions.firstIndex(of: selectedScreenTimeGoal) {
            let targetOffset = -CGFloat(i) * totalItemWidth
            screenTimeScrollOffset = targetOffset
            lastScreenTimeDragValue = screenTimeScrollOffset
        }
    }

    private func findClosestWakeTimeIndex(for date: Date) -> Int? {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        return wakeTimeOptions.firstIndex { option in
            let c = calendar.dateComponents([.hour, .minute], from: option)
            let mins = (c.hour ?? 0) * 60 + (c.minute ?? 0)
            return mins >= minutes
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    private func formattedScreenTime(_ val: Int) -> String {
        let h = val / 60
        let m = val % 60
        return String(format: "%d:%02d", h, m)
    }

    private func scaleEffectForItem(
        _ index: Int, offset: CGFloat, centerX: CGFloat
    ) -> CGFloat {
        let itemPosition =
            CGFloat(index) * totalItemWidth + offset
            + ((UIScreen.main.bounds.width - itemWidth) / 2) + (itemWidth / 2)
        let distance = abs(itemPosition - centerX)
        let maxDistance = UIScreen.main.bounds.width / 2
        return max(0.7, 1 - (distance / maxDistance) * 0.3)
    }

    private func rotationAngleForItem(
        _ index: Int, offset: CGFloat, centerX: CGFloat
    ) -> Angle {
        let itemPosition =
            CGFloat(index) * totalItemWidth + offset
            + ((UIScreen.main.bounds.width - itemWidth) / 2) + (itemWidth / 2)
        let angle =
            Double((itemPosition - centerX) / UIScreen.main.bounds.width) * 30
        return Angle(degrees: angle)
    }

    private func opacityForItem(_ index: Int, offset: CGFloat, centerX: CGFloat)
        -> Double
    {
        let itemPosition =
            CGFloat(index) * totalItemWidth + offset
            + ((UIScreen.main.bounds.width - itemWidth) / 2) + (itemWidth / 2)
        let distance = abs(itemPosition - centerX)
        let maxDistance = UIScreen.main.bounds.width / 2
        return Double(max(0.5, 1 - (distance / maxDistance)))
    }
}
