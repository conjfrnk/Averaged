# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is a SwiftUI iOS app built with Xcode. No SPM packages — all Apple system frameworks.

```bash
# Build for simulator
xcodebuild -scheme Averaged -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Archive for release (use system PATH to avoid Homebrew rsync mismatch)
PATH=/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Xcode.app/Contents/Developer/usr/bin \
  xcodebuild -scheme Averaged -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath /tmp/Averaged.xcarchive archive -allowProvisioningUpdates

# Export & upload to TestFlight (same PATH fix required)
PATH=/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Xcode.app/Contents/Developer/usr/bin \
  xcodebuild -exportArchive -archivePath /tmp/Averaged.xcarchive \
  -exportOptionsPlist ExportOptions.plist -exportPath /tmp/AveragedExport \
  -allowProvisioningUpdates
```

Tests are minimal (placeholder only): `xcodebuild test -scheme Averaged -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

## Architecture

**Manager + View pattern** — not pure MVVM. Three singleton managers own data; SwiftUI views observe them.

### Data Flow

```
HealthKit sleep API → HealthDataManager (@EnvironmentObject)
                              ↓
                         SwiftUI Views (YearlyView, MonthlyView, MetricsView)
                              ↑
CoreData ← ScreenTimeDataManager (singleton, @ObservedObject)
                              ↑
App Group UserDefaults ← ScreenTimeReport extension (DeviceActivityReportExtension)
                              ↑
                     AutoScreenTimeManager (reads extension data)
```

### Three Data Sources

1. **HealthKit** (`HealthDataManager`): Wake times from sleep analysis. Concurrent `DispatchGroup` queries with source prioritization (prefers sources with REM/Deep data). Thread-safe via dedicated `DispatchQueue`. **Day boundary is 14:00 (2 PM)** — wake times after 2 PM belong to the next day.

2. **CoreData** (`ScreenTimeDataManager`): Manual screen time entries. Entity `ScreenTimeRecord` with `date` (Date) and `minutes` (Int32). **Negative minutes (-1) means "skipped day"** — filter these with `validScreenTimeData`.

3. **App Group UserDefaults** (`AutoScreenTimeManager` + `ScreenTimeReport` extension): Real device screen time via DeviceActivity framework. Extension writes to the shared App Group with key format `screenTime_[epoch]`.

### Key Files

- `ChartHelpers.swift` — shared functions: `minutesToHHmm`, `chartYDomain`, `singleLetterMonth`, `computeAverage`
- `ContentView.swift` — tab bar with Yearly, Monthly, Metrics tabs
- `SettingsView.swift` — 3D cylindrical picker for goal wake time and screen time goal

### ScreenTimeReport Extension

Currently **disconnected from the main target** (dependency removed from pbxproj) because `com.apple.developer.family-controls` requires Apple approval. The extension code is in `ScreenTimeReport/` and ready to re-enable:
1. Add `PBXTargetDependency` from Averaged → ScreenTimeReport
2. Add "Embed Extensions" build phase back to Averaged target
3. Restore `com.apple.developer.family-controls` and App Groups to `Averaged.entitlements`
4. Restore `DeviceActivity` imports and `AutoScreenTimeManager` in `AveragedApp.swift` and `MetricsView.swift`

## Project Config

- **Deployment target**: iOS 18.2
- **Version**: 1.2 (build 5)
- **Entitlements**: HealthKit + background delivery
- **File sync**: Uses `PBXFileSystemSynchronizedRootGroup` (Xcode 16+) — files auto-sync from filesystem, no manual project references needed

## Known Issues

- **Homebrew rsync conflict**: `xcodebuild -exportArchive` fails with "Copy failed" if Homebrew rsync (3.4.1) is in PATH. Fix: prefix commands with `PATH=/usr/bin:/bin:/usr/sbin:/sbin:...`
- **Xcode beta asset catalog**: On Xcode 26.2 beta, asset catalog thinning may fail for simulator builds. Device builds and archives work fine.
