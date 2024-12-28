//
//  InfoView.swift
//  Averaged
//
//  Created by Connor Frank on 12/27/24.
//

import SwiftUI

struct InfoView: View {
    @Environment(\.presentationMode) var presentationMode

    // Retrieve the build version and version number
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("About Averaged")
                    .font(.largeTitle)
                    .padding()

                // Additional Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Created by: Connor Frank")
                        .font(.title3)

                    Text("Build: \(appVersion) (\(buildNumber))")
                        .font(.title3)
                }
                .padding(.top, 10)

                // GitHub Button
                Button(action: {
                    if let url = URL(
                        string: "https://github.com/conjfrnk/averaged")
                    {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left.slash.chevron.right")
                        Text("View on GitHub")
                    }
                    .font(.title3)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
                }

                // Email Button
                Button(action: {
                    if let url = URL(
                        string: "mailto:conjfrnk+averaged@gmail.com")
                    {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "mail")
                        Text("Email me")
                    }
                    .font(.title3)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
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
        }
    }
}
