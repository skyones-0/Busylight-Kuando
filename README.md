<p align="center">
  <img src="https://via.placeholder.com/120x120/6366f1/ffffff?text=BL" alt="Busylight Logo" width="120" height="120">
</p>

<h1 align="center">Busylight for macOS</h1>

<p align="center">
  <b>Professional USB status light control for modern workspaces</b>
</p>

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/macOS-13.0%2B-000000?logo=apple&logoColor=white" alt="macOS"></a>
  <a href="#"><img src="https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white" alt="Swift"></a>
  <a href="#"><img src="https://img.shields.io/badge/SwiftUI-Yes-007AFF?logo=swift&logoColor=white" alt="SwiftUI"></a>
  <a href="#"><img src="https://img.shields.io/badge/Architecture-ARM64-FF6B6B" alt="ARM64"></a>
  <a href="#"><img src="https://img.shields.io/badge/Status-Active-95E1D3" alt="Status"></a>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#requirements">Requirements</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#file-structure">File Structure</a>
</p>

---

## ✨ Features

### 💡 Light Control
- **10 Solid Colors**: Red, Green, Blue, Yellow, Cyan, Magenta, White, Orange, Purple, Pink
- **Pulse Effects**: Smooth breathing animation for all colors
- **Blink Patterns**: Configurable blink speeds (slow, medium, fast)
- **Alert Mode**: Sound + light alerts for notifications

### 🔊 Audio Integration
- **16 Built-in Jingles**: Play various alert sounds
- **Volume Control**: Adjustable from 0-100%
- **Color Sync**: Synchronize lights with audio alerts

### ⏱️ Pomodoro Timer
- **Customizable Sessions**: Work time (default 25 min), short break (5 min), long break (15 min)
- **Set Counter**: Configure number of work sets
- **Auto Light Control**: Green during work, automatic status changes
- **Menu Bar Quick Access**: Start/pause from menu bar

### 🖥️ Microsoft Teams Integration
- **Presence Sync**: Connect with Microsoft Teams status
- **Status Display**: Available, Busy, Do Not Disturb, Away
- **Account Connection**: OAuth-style login interface

### 🎨 Native macOS Interface
- **SwiftUI Interface**: Modern, responsive design
- **Menu Bar Extra**: Quick access from system menu bar
- **Sidebar Navigation**: Test, Pomodoro, Teams, Configuration, About
- **Appearance Modes**: System, Light, Dark themes
- **Dock Visibility**: Show/hide app from Dock

### 📝 Logging System
- **File-based Logging**: Daily log rotation (`busy_YYYY-MM-DD.log`)
- **Log Levels**: Debug, Info, Warning, Error
- **7-day Retention**: Automatic cleanup of old logs
- **Console Output**: Real-time log printing for debugging

---

## 📋 Requirements

| Component | Minimum Version |
|-----------|----------------|
| macOS | 13.0+ |
| Xcode | 15.0+ |
| Swift | 5.9+ |
| Hardware | Apple Silicon (ARM64) |
| Device | Busylight Omega series |

---

## 🚀 Installation

### Clone Repository

```bash
git clone https://github.com/skyones-0/kuando_macos.git
cd kuando_macos/Busylight
```

### Build & Run

```bash
# Open in Xcode
open Busylight.xcodeproj

# Or build via command line
xcodebuild -project Busylight.xcodeproj -scheme Busylight -configuration Release
```

---

## 🎮 Usage

### Test Panel
Access via **Test** in the sidebar:
- Click color buttons to set solid colors
- Click jingle buttons (1-16) to play sounds with random colors
- View connection status and current device name

### Pomodoro Timer
Access via **Pomodoro** in the sidebar or menu bar:
- Configure work time, short break, long break, and number of sets
- Click **Start** to begin (light turns green)
- Click **Pause** to pause the session
- Visual progress indicator

### Microsoft Teams
Access via **Teams** in the sidebar:
- Enter email and password
- Click **Login** to connect
- Select presence status from dropdown

### Configuration
Access via **Configuration** in the sidebar:
- **Theme**: System, Light, or Dark mode
- **Show in Dock**: Toggle Dock visibility
- **Show in Menu Bar**: Toggle menu bar icon

### Menu Bar
Click the lightbulb icon in the menu bar for quick access:
- View connection status
- Pomodoro controls
- Quick color buttons (Red, Green, Blue, Yellow, Purple, White)
- Visibility toggles
- Open Main Window / Quit

---

## 🏗️ Architecture

### Project Structure

```
Busylight/
├── Busylight/
│   ├── BusylightApp.swift          # App entry point, scene management
│   ├── AppDelegate.swift           # Menu bar, dock visibility
│   ├── ContentView.swift           # Main UI with sidebar navigation
│   ├── MenuBarView.swift           # Menu bar popover UI
│   ├── BusylightManager.swift      # Device control, SDK integration
│   ├── BusylightLogger.swift       # File logging system
│   ├── TimerView.swift             # Pomodoro timer view
│   ├── Persistence.swift           # CoreData persistence
│   └── Info.plist                  # App configuration
├── BusylightTests/                 # Unit tests
├── BusylightUITests/               # UI tests
└── BusylightSDK_Swift.framework    # Official Busylight SDK
```

### Key Components

#### BusylightManager
Core class for device communication using the official `BusylightSDK_Swift` framework:

```swift
// Set solid colors
busylight.red()
busylight.green()
busylight.blue()
// ... etc

// Pulse effects
busylight.pulseRed()
busylight.pulseGreen()

// Blink patterns
busylight.blinkRedSlow()
busylight.blinkRedFast()

// Audio alerts
busylight.jingle(soundNumber: 1, red: 100, green: 0, blue: 0, andVolume: 50)

// Turn off
busylight.off()
```

#### BusylightLogger
Singleton logger with file rotation:

```swift
BusylightLogger.shared.info("Message")
BusylightLogger.shared.debug("Debug info")
BusylightLogger.shared.warning("Warning")
BusylightLogger.shared.error("Error message")
```

Logs are stored in: `~/Library/Application Support/co.skyones.Busylight/Logs/`

---

## 📁 File Structure

| File | Purpose |
|------|---------|
| `BusylightApp.swift` | `@main` app struct, window management, appearance |
| `AppDelegate.swift` | NSApplicationDelegate, menu bar setup, dock control |
| `ContentView.swift` | Main NavigationSplitView with sidebar and detail views |
| `MenuBarView.swift` | Menu bar popover with quick controls |
| `BusylightManager.swift` | ObservableObject for device control, color/audio methods |
| `BusylightLogger.swift` | File-based logging with rotation and cleanup |
| `TimerView.swift` | Standalone Pomodoro timer window |
| `Persistence.swift` | CoreData stack for data persistence |
| `ViewController.swift` | Placeholder for future use |

### Views in ContentView

- **TestView**: Color buttons and jingle controls
- **PomodoroView**: Timer configuration and status
- **TeamsView**: Microsoft Teams integration UI
- **ConfigurationView**: App settings (appearance, visibility)
- **AboutView**: App info and device status

---

## 🔧 SDK Integration

This app uses the official **BusylightSDK_Swift.framework** for hardware communication:

- **Protocol**: Official Busylight® implementation
- **Devices**: Omega series (Busylight Omega model 2)
- **Communication**: Direct USB control
- **Delegate Pattern**: `BusylightDelegate` for connection events

### Supported SDK Methods

```swift
// Light control
Light(red:green:blue:)
Pulse(red:green:blue:)
Blink(red:green:blue:ontime:offtime:)

// Audio
Jingle(red:green:blue:Sound:andVolume:)
Alert(red:green:blue:andSound:andVolume:)

// Device
Off()
getDevicesArray()
```

---

## 🧪 Testing

### Unit Tests
```bash
xcodebuild test -project Busylight.xcodeproj -scheme Busylight -destination 'platform=macOS'
```

### UI Tests
UI tests are located in `BusylightUITests/` and use XCTest framework.

---

## 📝 Logging

Logs are automatically created and rotated daily:

```
~/Library/Application Support/co.skyones.Busylight/Logs/
├── busy_2026-02-27.log
├── busy_2026-02-26.log
└── ...
```

Log format:
```
[2026-02-27T12:34:56Z] [INFO] [ContentView.swift:45] body: Message here
```

---

## 👤 Author

**Jose Araujo** - Sky One, 2026

---

## 📄 License

This project is proprietary software.

---

<p align="center">
  Made with ❤️ for macOS
</p>
