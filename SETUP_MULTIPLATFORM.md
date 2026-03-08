# Busylight Multi-Platform Setup Guide

This guide explains how to configure the Busylight project for iOS, macOS, and watchOS.

## Project Structure

```
Busylight/
├── BusylightShared/             # Shared framework for all platforms
│   └── Sources/
│       ├── Models/
│       │   └── SharedModels.swift
│       ├── Managers/
│       │   ├── CloudKitSyncManager.swift
│       │   └── UnifiedPomodoroManager.swift
│       ├── Styles/
│       │   └── SharedStyles.swift
│       └── CloudKit/
│           └── CloudKitSyncManager.swift
│
├── BusylightMac/                # macOS app
│   └── Sources/
│       ├── Core/                # App entry, device control, timer
│       ├── Views/               # Main UI, Menu bar, Timer
│       ├── Models/              # ML patterns, Sessions
│       ├── Utilities/           # Smart features, Webhook, Logger
│       └── Styles/              # Glassmorphism UI
│
├── BusylightIOS/                # iOS app
│   └── Sources/
│       ├── Core/
│       │   └── BusylightIOSApp.swift
│       ├── Views/
│       │   └── IOSContentView.swift
│       └── LiveActivity/
│           └── LiveActivityManager.swift
│
├── BusylightWatch/              # watchOS app
│   └── Sources/
│       ├── Core/
│       │   └── BusylightWatchApp.swift
│       └── Views/
│           └── WatchContentView.swift
│
└── Busylight.xcodeproj          # Xcode project
```

## Features by Platform

### macOS (BusylightMac/)
- ✅ Hardware control via BusylightSDK
- ✅ Full UI with glassmorphism
- ✅ Menu bar integration
- ✅ CloudKit sync

### iOS (BusylightIOS/)
- ✅ Full timer controls
- ✅ Live Activities (Lock Screen)
- ✅ Dynamic Island support
- ✅ Push notifications
- ✅ Sound alerts
- ✅ Haptic feedback
- ✅ CloudKit sync
- ✅ Glassmorphism UI

### watchOS (BusylightWatch/)
- ✅ Basic timer display
- ✅ Start/Pause/Stop controls
- ✅ Alerts and notifications
- ✅ CloudKit sync
- ✅ Complications support ready

## Xcode Configuration Steps

### 1. Create Framework Target for Shared Code

1. File → New → Target
2. Select "Framework" under iOS
3. Name: `BusylightShared`
4. Add to project

### 2. Add Shared Files to Framework

Add these files to the `BusylightShared` target:
- `Shared/Models/SharedModels.swift`
- `Shared/Managers/CloudKitSyncManager.swift`
- `Shared/Managers/UnifiedPomodoroManager.swift`
- `Shared/Styles/SharedStyles.swift`

### 3. Create iOS App Target

1. File → New → Target
2. Select "App" under iOS
3. Name: `BusylightIOS`
4. Interface: SwiftUI
5. Language: Swift
6. Enable: Live Activities, CloudKit

### 4. Create watchOS App Target

1. File → New → Target
2. Select "App" under watchOS
3. Name: `BusylightWatch`
4. Interface: SwiftUI
5. Language: Swift

### 5. Configure Capabilities

#### iOS Target (BusylightIOS):
- Background Modes: Background processing, Remote notifications
- CloudKit
- Live Activities
- Push Notifications

#### watchOS Target (BusylightWatch):
- Background Modes
- CloudKit

#### macOS Target (BusylightMac):
- CloudKit (add if not present)

### 6. Add Dependencies

#### iOS:
```swift
// Link BusylightShared framework
// Link ActivityKit
```

#### watchOS:
```swift
// Link BusylightShared framework
```

#### macOS:
```swift
// Link BusylightShared framework
// Keep existing BusylightSDK_Swift.framework
```

### 7. Create Widget Extension for Live Activities

1. File → New → Target
2. Select "Widget Extension"
3. Name: `BusylightWidget`
4. Include Live Activity: YES

Add `BusylightLiveActivityWidget` to the widget extension.

### 8. Configure CloudKit Container

1. Sign in to Apple Developer account
2. Enable CloudKit in Capabilities for all targets
3. Use the same CloudKit container identifier:
   - `iCloud.co.skyones.Busylight`

### 9. Bundle Identifiers

Set up bundle identifiers:
- macOS: `co.skyones.Busylight`
- iOS: `co.skyones.Busylight.ios`
- watchOS: `co.skyones.Busylight.watch`
- Shared: `co.skyones.Busylight.shared`
- Widget: `co.skyones.Busylight.widget`

### 10. App Groups (for data sharing)

Enable App Groups for all targets:
- Group: `group.co.skyones.Busylight`

## Build Settings

### Swift Compiler - Custom Flags
Add to all targets:
- `-D DEBUG` for debug builds

### Deployment Targets
- iOS: 17.0+
- macOS: 14.0+
- watchOS: 10.0+

## Testing

### macOS
```bash
xcodebuild -project Busylight.xcodeproj -scheme BusylightMac -destination 'platform=macOS' build
```

### iOS Simulator
```bash
xcodebuild -project Busylight.xcodeproj -scheme BusylightIOS -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

### watchOS Simulator
```bash
xcodebuild -project Busylight.xcodeproj -scheme BusylightWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build
```

## Troubleshooting

### Live Activities not showing
1. Check deployment target is iOS 16.1+
2. Verify ActivityKit is linked
3. Check entitlement: `com.apple.developer.live-activities`

### CloudKit sync not working
1. Verify same container ID across all targets
2. Check iCloud account is signed in
3. Verify CloudKit entitlement

### Framework not found
1. Add framework to "Frameworks, Libraries, and Embedded Content"
2. Check "Target Membership" for shared files

## Next Steps

1. Open `Busylight.xcodeproj` in Xcode
2. Follow the configuration steps above
3. Build and test each target
4. Deploy to devices for testing
