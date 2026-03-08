<p align="center">
  <img src="icon Exports/BL Icon.png" alt="Busylight Logo" width="120" height="120">
</p>

<h1 align="center">Busylight for macOS</h1>

<p align="center">
  <b>Professional USB status light control for modern workspaces</b>
</p>

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/macOS-26.2%2B-000000?logo=apple&logoColor=white" alt="macOS"></a>
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

### ⏱️ Pomodoro Timer (Enhanced)
- **Customizable Sessions**: Work time (default 25 min), short break (5 min), long break (15 min)
- **Set Counter**: Configure number of work sets
- **Auto Light Control**: Green during work, automatic status changes
- **Phase Management**: Work → Short Break → Work → Long Break cycle
- **Visual Indicators**: Progress bar, phase badges with glow/pulse effects
- **Haptic Feedback**: Prolonged haptic (3 pulses) for main controls
- **Menu Bar Quick Access**: Full timer controls from menu bar

### 🎨 Glassmorphism UI
- **Modern Design**: Glassmorphism style with blur, transparency, and depth
- **Gradient Effects**: Animated shimmer effects on buttons
- **Dynamic Cards**: Glass cards with border highlights and shadows
- **Smooth Animations**: Scale, pulse, and glow animations
- **Phase Visual Effects**: Working/Resting/Relaxing labels with color-coded glow

### 🖥️ Menu Bar Integration
- **NSPopover Interface**: Native macOS popover with glassmorphism design
- **Full-Screen Support**: Automatic NSWindow fallback for full-screen spaces
- **Quick Controls**: Timer controls, color buttons, visibility toggles
- **Status Indicator**: Real-time connection and timer status

### 🌐 Multilanguage Support
- **Localized Interface**: English and Spanish support
- **System Language Detection**: Automatic language selection
- **Localizable.xcstrings**: Modern Swift localization

### 🗄️ SwiftData Persistence
- **Session History**: Track completed Pomodoro sessions
- **SwiftData Models**: Modern replacement for CoreData
- **Automatic Migration**: Seamless data migration from previous versions

### 🔧 Settings (Unified)
- **Appearance**: System/Light/Dark themes, Dock/Menu Bar visibility
- **Microsoft Teams**: Integrated presence sync (Available, Busy, DND, Away)
- **About**: App version, build info, developer info

### 🚀 Super App Features (15 Productivity Tools)

| # | Feature | Description |
|---|---------|-------------|
| 1 | **📅 Calendar Sync** | Auto-detects meetings from Calendar/Outlook. Yellow 5min before, red during meetings |
| 2 | **🌙 Focus Mode Sync** | Integrates with macOS Focus modes (Work, Sleep, DND, Personal) |
| 3 | **⏸️ Idle Detection** | Auto away-status after configurable inactivity time |
| 4 | **👁️ 20-20-20 Breaks** | Eye health timer: every 20min, look 20ft away for 20sec |
| 5 | **📊 Productivity Dashboard** | Weekly stats, streak counter, best day tracking |
| 6 | **🔥 Deep Work Mode** | 60-120min distraction-free blocks with locked focus |
| 7 | **👔 Work Profiles** | Presets: Coding (50/10), Meetings (calendar), Learning (25/5), Deep Work (90min) |
| 8 | **🎤 Siri Shortcuts** | "Hey Siri, start pomodoro" / "I'm busy" / "End work day" |
| 9 | **🌐 Local API** | HTTP endpoints at `localhost:8080` for Zapier/IFTTT/Slack integration |
| 10 | **📹 Video Call Detection** | Auto-detects Zoom/Teams/Meet and sets busy status |
| 11 | **💪 Smart Breaks** | Detects if you skip breaks and gently reminds you |
| 12 | **🎯 Presentation Mode** | Auto-detects Keynote/PowerPoint, mutes sounds, sets red light |
| 13 | **🕐 Smart Work Hours** | Reminds you to stop working outside configured hours |
| 14 | **🎨 Light Themes** | Aurora, Minimal, Nature, Cyber, Calm color schemes |
| 15 | **📱 Widget Support** | macOS widgets for quick timer control (coming soon) |

### 📝 Logging System
- **File-based Logging**: Daily log rotation (`busy_YYYY-MM-DD.log`)
- **Log Levels**: Debug, Info, Warning, Error
- **7-day Retention**: Automatic cleanup of old logs
- **Console Output**: Real-time log printing for debugging

---

## 📋 Requirements

| Component | Minimum Version |
|-----------|----------------|
| macOS | 26.2+ |
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

### Device Panel (antes "Test")
Access via **Device** in the sidebar:
- Click color buttons to set solid colors with glassmorphism effects
- Click jingle buttons (1-16) to play sounds with synchronized lights
- Quick actions: Off, Pulse, Blink
- View connection status and current device name

### Pomodoro Timer
Access via **Pomodoro** in the sidebar or menu bar:
- Configure work time, short break, long break, and number of sets
- Visual stepper controls (increased size for better interaction)
- Click **Start** to begin (light turns green, "Working" label glows)
- Click **Pause** to pause the session
- Click **Stop** to reset
- **Visual Progress**: Elegant progress bar with phase color
- **Phase Indicators**: Dynamic phase label with glow + pulse + capsule effects
- **Set Counter**: Shows current set / total sets

### Settings (Unified)
Access via **Settings** in the sidebar:

**Appearance Section:**
- **Theme**: System, Light, or Dark mode
- **Show in Dock**: Toggle Dock visibility
- **Show in Menu Bar**: Toggle menu bar icon

**Microsoft Teams Section:**
- **Connection Toggle**: Connect/disconnect from Teams
- **Login Fields**: Email and password (when disconnected)
- **Status Grid**: Available, Busy, DND, Away buttons (when connected)
- **Presence Sync**: Automatic light color based on Teams status

**About Section:**
- App icon with gradient background
- Version and build information

### Menu Bar
Click the lightbulb icon in the menu bar for quick access:
- View connection status with color indicator
- Full Pomodoro timer with phase badge
- Timer display with phase-colored glow
- Control buttons (Play/Pause/Stop) with validation states
- Quick color buttons (Red, Green, Blue, Yellow, Purple, White, Orange)
- Visibility toggles
- Open Main Window / Quit actions

---

## 🏗️ Architecture

### Project Structure

```
Busylight/
├── Busylight/
│   ├── Core/
│   │   ├── BusylightApp.swift          # App entry, SwiftData setup
│   │   ├── AppDelegate.swift           # Menu bar, dock visibility, popover/window
│   │   ├── Persistence.swift           # SwiftData persistence controller
│   │   └── BusylightLogger.swift       # File logging system
│   ├── Views/
│   │   ├── ContentView.swift           # Main UI with sidebar navigation
│   │   ├── MenuBarView.swift           # Menu bar popover UI
│   │   └── TimerView.swift             # Standalone timer window
│   ├── Styles/
│   │   └── GlassmorphismStyles.swift   # Glassmorphism components & button styles
│   ├── Utilities/
│   │   └── BusylightManager.swift      # Device control, SDK integration
│   ├── Models/
│   │   └── PomodoroSession.swift       # SwiftData model for sessions
│   └── Resources/
│       └── Localizable.xcstrings       # English/Spanish localization
├── BusylightTests/                     # Unit tests
├── BusylightUITests/                   # UI tests
└── BusylightSDK_Swift.framework        # Official Busylight SDK
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

#### PomodoroManager (Singleton)
Shared timer manager for synchronized state between ContentView and MenuBar:

```swift
// Access shared instance
PomodoroManager.shared.start()
PomodoroManager.shared.pause()
PomodoroManager.shared.stop()

// Properties
PomodoroManager.shared.isRunning
PomodoroManager.shared.currentPhase  // .work, .shortBreak, .longBreak
PomodoroManager.shared.progress      // 0.0 to 1.0
```

#### Glassmorphism Styles
Reusable glassmorphism components:

```swift
// Button styles
.buttonStyle(.gradientWave(color: .green, prominent: true))
.buttonStyle(.smallGradient(color: .blue))

// Glass card
GlassCard(title: "Title", icon: "icon.fill") { content }

// Glass text field
GlassTextField(placeholder: "Email", text: $text, icon: "envelope.fill")
```

#### Haptic Feedback
Prolonged haptic feedback for main actions:

```swift
HapticFeedback.light()     // Light feedback
HapticFeedback.medium()    // Medium feedback
HapticFeedback.prolonged() // 3 sequential pulses (for Play/Pause/Stop)
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
| **Core/** |
| `BusylightApp.swift` | `@main` app struct, window management, SwiftData container |
| `AppDelegate.swift` | NSApplicationDelegate, menu bar setup, NSPopover/NSWindow |
| `Persistence.swift` | SwiftData ModelContainer configuration |
| `BusylightLogger.swift` | File-based logging with rotation and cleanup |
| **Views/** |
| `ContentView.swift` | Main NavigationSplitView with sidebar (Pomodoro, Settings, Device) |
| `MenuBarView.swift` | Menu bar popover with Pomodoro, colors, visibility controls |
| `TimerView.swift` | Standalone Pomodoro timer window |
| **Styles/** |
| `GlassmorphismStyles.swift` | Glassmorphism components, button styles, haptics |
| **Utilities/** |
| `BusylightManager.swift` | ObservableObject for device control, color/audio methods |
| **Models/** |
| `PomodoroSession.swift` | SwiftData @Model for session persistence |
| **Resources/** |
| `Localizable.xcstrings` | Multilanguage strings (English/Spanish) |

### Views in ContentView

- **PomodoroView**: Timer configuration and status with glassmorphism design
- **SettingsView**: Unified settings (Appearance + Teams + About)
- **DeviceView**: Color buttons, jingles, and quick actions

### Sidebar Navigation (Simplified)

| Item | Description |
|------|-------------|
| Pomodoro | Timer with phase management and visual effects |
| Settings | Appearance, Teams integration, and About info |
| Device | Light control and audio testing |

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

## 🔄 Recent Changes

### 🚀 Super App Release - 15 Productivity Features

**Smart Automation:**
- **Calendar Sync** - Auto-detects meetings, changes light 5min before/during
- **Focus Mode Sync** - Integrates with macOS Focus modes
- **Idle Detection** - Auto away-status after inactivity
- **Video Call Detection** - Auto-detects Zoom/Teams/Meet
- **Presentation Mode** - Auto-detects Keynote/PowerPoint
- **Smart Work Hours** - Reminds you to stop working outside hours

**Health & Productivity:**
- **20-20-20 Rule** - Eye break reminders every 20 minutes
- **Deep Work Mode** - 60-120min distraction-free blocks
- **Smart Breaks** - Detects skipped breaks and reminds you
- **Work Profiles** - Presets for Coding, Meetings, Learning, Deep Work

**Integrations:**
- **Local API Server** - HTTP endpoints at localhost:8080
- **Siri Shortcuts** - Voice control integration
- **Productivity Dashboard** - Weekly stats and streaks
- **Light Themes** - Aurora, Minimal, Nature, Cyber, Calm

### Glassmorphism UI Redesign
- Complete visual overhaul with glassmorphism design language
- Glass cards with Material backgrounds and gradient borders
- Animated gradient shimmer effects on buttons
- Dynamic shadows and glow effects

### Pomodoro Enhancements
- Phase management: Work → Short Break → Work → Long Break
- Phase label with glow + pulse + capsule effects (green when running, gray when stopped)
- Progress bar with gradient and shadow
- Haptic feedback on all main controls (prolonged 3-pulse)
- Button validation states (gray when disabled, colored when active)

### Architecture Improvements
- Migrated from CoreData to SwiftData
- Reorganized project structure (Core/, Views/, Styles/, Utilities/, Models/)
- Extracted animated components to prevent layout recursion
- Singleton PomodoroManager for cross-view synchronization
- New SmartFeaturesManager for all smart automation
- WebhookServer for local API integration

### Menu Bar Enhancements
- NSPopover with NSWindow fallback for full-screen support
- Full timer controls in menu bar
- Quick color buttons with hover effects
- Phase label with visual effects

### Simplified Navigation
- Removed Teams and About from sidebar
- Unified Settings view combining Appearance + Teams + About + All Smart Features
- Cleaner 3-item sidebar: Pomodoro, Settings, Device

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
