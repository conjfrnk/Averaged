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
                                            centerX: center
                                        )
                                    )
                                    .rotation3DEffect(
                                        rotationAngleForItem(
                                            at: index,
                                            offset: wakeScrollOffset,
                                            centerX: center
                                        ),
                                        axis: (x: 0, y: 1, z: 0),
                                        anchor: .center,
                                        perspective: 0.5
                                    )
                                    .opacity(
                                        opacityForItem(
                                            at: index,
                                            offset: wakeScrollOffset,
                                            centerX: center
                                        )
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
            .onDisappear {
                if Self.didChangeGoalTime {
                    NotificationCenter.default.post(
                        name: .didChangeGoalTime, object: nil)
                    Self.didChangeGoalTime = false
                }
            }
        }
    }
}

// MARK: - Private Helpers
extension SettingsView {
    private func selectWakeTime(at index: Int) {
        withTransaction(Transaction(animation: .none)) {
            selectedWakeTime = wakeTimeOptions[index]
            UserDefaults.standard.set(
                selectedWakeTime.timeIntervalSince1970,
                forKey: "goalWakeTime"
            )
            Self.didChangeGoalTime = true
        }
        withAnimation(.easeOut) {
            let targetOffset = -CGFloat(index) * totalItemWidth
            wakeScrollOffset = targetOffset
            lastWakeDragValue = wakeScrollOffset
        }
    }

    private func createDragGesture() -> some Gesture {
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
                        forKey: "goalWakeTime"
                    )
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

    private func initializeSettings() {
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
}
