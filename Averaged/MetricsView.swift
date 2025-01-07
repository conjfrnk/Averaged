//
//  MetricsView.swift
//  Averaged
//
//  Created by Connor Frank on 1/6/25.
//

import SwiftUI

struct MetricsView: View {
    @StateObject private var screenTimeManager = ScreenTimeDataManager.shared
    @AppStorage("screenTimeGoal") private var screenTimeGoal: Int = 120
    @State private var showScreenTimeDetail = false

    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section("Metrics") {
                        Button {
                            showScreenTimeDetail.toggle()
                        } label: {
                            HStack {
                                Text("Screen Time")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .sheet(isPresented: $showScreenTimeDetail) {
                ScreenTimeDetailView()
            }
        }
    }
}
