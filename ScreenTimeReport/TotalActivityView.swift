//
//  TotalActivityView.swift
//  ScreenTimeReport
//
//  Created by Connor Frank on 2/16/26.
//

import SwiftUI

struct TotalActivityView: View {
    let totalMinutes: Double

    var body: some View {
        VStack(spacing: 8) {
            Text(formattedTime)
                .font(.system(size: 48, weight: .bold, design: .rounded))
            Text("Total Screen Time Today")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var formattedTime: String {
        let hours = Int(totalMinutes) / 60
        let mins = Int(totalMinutes) % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}
