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
                // Main tab bar
                TabView(selection: $selectedTab) {

                    YearlyView()
                        .tabItem {
                            Label("Yearly", systemImage: "calendar")
                        }
                        .tag(0)

                    MonthlyView()
                        .tabItem {
                            Label("Monthly", systemImage: "calendar.badge.plus")
                        }
                        .tag(1)

                    WeeklyView()
                        .tabItem {
                            Label("Weekly", systemImage: "calendar.badge.minus")
                        }
                        .tag(2)
                }
            }
            .navigationTitle("Averaged")
            .toolbar {
                // Info button (left)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showInfo.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }

                // Settings button (right)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            // Present the InfoView as a sheet
            .sheet(isPresented: $showInfo) {
                InfoView()
            }
            // Present the SettingsView as a sheet (placeholder)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
}
