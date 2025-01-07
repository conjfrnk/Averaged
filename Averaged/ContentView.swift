//
//  ContentView.swift
//  Averaged
//
//  Created by Connor Frank on 12/27/24.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showInfo = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                TabView(selection: $selectedTab) {
                    YearlyView()
                        .tabItem {
                            Label("Yearly", systemImage: "chart.line.text.clipboard")
                        }
                        .tag(0)
                    MonthlyView()
                        .tabItem {
                            Label("Monthly", systemImage: "calendar")
                        }
                        .tag(1)
                    MetricsView()
                        .tabItem {
                            Label("Metrics", systemImage: "list.bullet.rectangle.fill")
                        }
                        .tag(2)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showInfo.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showInfo) {
                InfoView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}
