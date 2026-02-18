//
//  OnboardingView.swift
//  Averaged
//
//  Created by Connor Frank on 2/16/26.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @ObservedObject private var autoScreenTime = AutoScreenTimeManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding =
        false
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "chart.line.text.clipboard")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                Text("Track Your Goals")
                    .font(.title)
                    .bold()
                Text(
                    "Track your wake time and screen time goals to build better habits."
                )
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                Spacer()
                Button("Next") {
                    withAnimation {
                        currentPage = 1
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 60)
            }
            .tag(0)

            // Page 2: Health Access
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "heart.text.square")
                    .font(.system(size: 64))
                    .foregroundColor(.red)
                Text("Health Access")
                    .font(.title)
                    .bold()
                Text(
                    "Grant Health access to automatically track your wake times."
                )
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                Button("Grant Access") {
                    healthDataManager.requestAuthorization { _, _ in }
                }
                .buttonStyle(.borderedProminent)
                Spacer()
                Button("Next") {
                    withAnimation {
                        currentPage = 2
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 60)
            }
            .tag(1)

            // Page 3: Screen Time Access
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "hourglass")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                Text("Screen Time Access")
                    .font(.title)
                    .bold()
                Text(
                    "Grant Screen Time access to automatically track your daily screen time."
                )
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                if autoScreenTime.isAuthorized {
                    Label("Access Granted", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.headline)
                } else {
                    Button("Grant Screen Time Access") {
                        Task { await autoScreenTime.requestAuthorization() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
                Button("Next") {
                    withAnimation {
                        currentPage = 3
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 60)
            }
            .tag(2)

            // Page 4: Set Your Goals
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "target")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                Text("Set Your Goals")
                    .font(.title)
                    .bold()
                Text(
                    "Configure your wake time and screen time goals in Settings."
                )
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                Spacer()
                Button("Get Started") {
                    hasCompletedOnboarding = true
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 60)
            }
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}
