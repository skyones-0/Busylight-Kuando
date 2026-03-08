# Busylight for macOS

<p align="center">
  <img src="icon Exports/BL Icon.png" alt="Busylight Logo" width="120" height="120">
</p>

<p align="center">
  <b>Professional USB status light control with 15+ productivity features</b>
</p>

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/macOS-26.2%2B-000000?logo=apple&logoColor=white" alt="macOS"></a>
  <a href="#"><img src="https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white" alt="Swift"></a>
  <a href="#"><img src="https://img.shields.io/badge/SwiftUI-Yes-007AFF?logo=swift&logoColor=white" alt="SwiftUI"></a>
  <a href="#"><img src="https://img.shields.io/badge/Architecture-ARM64-FF6B6B" alt="ARM64"></a>
  <a href="#"><img src="https://img.shields.io/badge/Features-15%2B-95E1D3" alt="Features"></a>
</p>

---

## ✨ What's New in Super App 2.0

### 🚀 Reorganized Navigation
- **7 Main Sections** in sidebar: Pomodoro, Deep Work, Profiles, Teams, Dashboard, Settings, Device
- **Deep Work** is now a dedicated section with full-screen focus mode
- **Work Profiles** moved to sidebar for quick access
- **Microsoft Teams** integrated as main section with 3 tabs

### 📅 Enhanced Calendar Integration
- **Real-time calendar status** in menu bar (Current meeting, Available, Next event)
- **Calendar selector** in Settings - choose which calendars to monitor
- **Smart status** - Red during meetings, Yellow 5min before, Green when free
- **Visual indicator** with color-coded status dot

### 🔥 Improved Deep Work Mode
- **Full-screen dedicated view** with countdown timer
- **Auto-pauses Pomodoro** when starting Deep Work
- **3 duration options**: 60, 90, 120 minutes
- **Progress indicator** showing remaining time
- **Visual warning** in Pomodoro view when Deep Work is active

### 👔 Microsoft Teams Integration (New)
- **3 dedicated tabs**: Status, Credentials, Activities
- **Real-time presence sync** with Teams status
- **Today's activities** view showing scheduled meetings
- **Quick status change**: Available, Busy, DND, Away
- **Credential management** with secure storage

### ⏱️ Smart Work Hours (Redesigned)
- **Compact stepper UI** - no more large sliders
- **Quick time selection** with +/- buttons
- **Work schedule display** in Settings toggle
- **Automatic reminders** when working outside hours

### 🌐 Local API (Fixed)
- **Visual status indicator** - Green when running, Gray when stopped
- **Real-time request counter**
- **Endpoint documentation** built into UI
- **Toggle with immediate feedback**

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

## 🎮 Features Overview

### Core Features
- **💡 Light Control** - 10 colors, pulse, blink patterns
- **⏱️ Pomodoro Timer** - Phase management, visual progress
- **🔊 Audio Integration** - 16 jingles, volume control
- **🎨 Glassmorphism UI** - Modern design with blur effects

### Smart Automation (8 Features)
1. **📅 Calendar Sync** - Auto-detect meetings
2. **🌙 Focus Mode Sync** - macOS Focus integration
3. **⏸️ Idle Detection** - Pauses timer on inactivity
4. **👁️ 20-20-20 Breaks** - Eye health reminders
5. **📹 Video Call Detection** - Auto-detect Zoom/Teams
6. **🎯 Presentation Mode** - Keynote/PowerPoint detection
7. **🕐 Smart Work Hours** - Schedule reminders
8. **🔥 Deep Work Mode** - Distraction-free sessions

### ML & AI Features (NEW)
- **🧠 Smart Schedule Learning** - ML model learns your work patterns
- **📈 Work Hour Prediction** - Auto-suggests optimal work hours
- **🎯 Holiday Exclusion** - Mark holidays to exclude from training
- **⚡ Auto-Configuration** - Automatically adjust settings based on patterns

### Integrations
- **🌐 Local API** - HTTP endpoints at localhost:8080
- **👔 Microsoft Teams** - Presence sync & activities
- **📊 Dashboard** - Productivity stats & streaks
- **🎨 Light Themes** - Aurora, Minimal, Nature, Cyber, Calm

---

## 🏗️ Architecture

### Project Structure (Multi-Platform)
```
Busylight/
│
├── 📁 BusylightMac/                 # macOS App
│   └── Sources/
│       ├── Core/                    # App entry, device control
│       ├── Views/                   # Main UI, Menu bar, Timer
│       ├── Models/                  # ML patterns, Sessions
│       ├── Utilities/               # Smart features, Webhook
│       └── Styles/                  # Glassmorphism UI
│
├── 📁 BusylightIOS/                 # iOS App
│   └── Sources/
│       ├── Core/                    # iOS entry point
│       ├── Views/                   # iOS UI
│       └── LiveActivity/            # Live Activities
│
├── 📁 BusylightWatch/               # watchOS App
│   └── Sources/
│       ├── Core/                    # watchOS entry
│       └── Views/                   # Watch UI
│
└── 📁 BusylightShared/              # Shared Framework
    └── Sources/
        ├── CloudKit/                # Sync
        ├── Managers/                # Unified manager
        ├── Models/                  # Shared models
        └── Styles/                  # Shared UI
```

### macOS App Structure (BusylightMac/Sources/)
```
Core/
├── BusylightApp.swift          # App entry point
├── AppDelegate.swift           # Menu bar, dock control
├── BusylightManager.swift      # Device control
├── Persistence.swift           # SwiftData
└── PomodoroManager.swift       # Timer logic

Views/
├── ContentView.swift           # Main UI
├── MenuBarView.swift           # Menu bar popover
└── TimerView.swift             # Standalone timer

Utilities/
├── SmartFeaturesManager.swift  # 15 smart features
├── WebhookServer.swift         # Local API
├── MLScheduleManager.swift     # ML scheduling
└── BusylightLogger.swift       # Logging

Models/
├── PomodoroSession.swift       # SwiftData model
└── MLWorkPattern.swift         # ML patterns
```

---

## 🚀 Installation

### Build & Run
```bash
# Clone repository
git clone https://github.com/skyones-0/kuando_macos.git
cd kuando_macos

# Open in Xcode
open Busylight.xcodeproj

# Or build via command line
xcodebuild -project Busylight.xcodeproj -scheme BusylightMac -configuration Release
```

---

## 📖 Usage Guide

### Sidebar Navigation
| Icon | Section | Description |
|------|---------|-------------|
| ⏱️ | **Pomodoro** | Timer with phases (Work/Break/Long Break) |
| 🔥 | **Deep Work** | Focus mode with countdown |
| 👔 | **Profiles** | Work presets (Coding/Meetings/Learning) |
| 👥 | **Teams** | MS Teams integration |
| 📊 | **Dashboard** | Productivity stats |
| ⚙️ | **Settings** | App configuration |
| 💡 | **Device** | Light control & testing |

### Deep Work Mode
1. Click **Deep Work** in sidebar
2. Choose duration (60/90/120 min)
3. Pomodoro auto-pauses
4. Light turns red (busy status)
5. Timer counts down with progress bar

### Calendar Integration
1. Go to **Settings > Smart Features**
2. Enable **Calendar Sync**
3. Grant calendar permissions
4. Select specific calendar (or "All")
5. Status shows in menu bar automatically

### ML Autoconfiguration (NEW)
1. Go to **Settings > ML Autoconfiguration**
2. Enable **Smart Schedule Learning**
3. The app automatically collects your daily work patterns
4. After 14+ days, the model **trains automatically**
5. Work hours are **automatically adjusted** based on predictions

**Features:**
- **Fully Automatic**: Trains and applies predictions without user intervention
- Learns your actual work patterns vs configured hours
- Predicts optimal work hours for each day
- Excludes holidays from training data
- Shows model accuracy and confidence
- Manual training available anytime via "Train Now"

### Managing Holidays
1. Go to **Settings > ML Autoconfiguration > Holidays**
2. Create a holiday calendar (e.g., "US Holidays")
3. Select dates to exclude from ML training
4. ML model will ignore these days when learning patterns

### Local API
1. Go to **Settings > API & Integrations**
2. Toggle **Local API Server**
3. Access endpoints at `http://localhost:8080`

**Available endpoints:**
```bash
GET  /status          # Get current status
POST /color           # Set light color
POST /status          # Set presence status
POST /timer/start     # Start pomodoro
POST /timer/pause     # Pause pomodoro
POST /timer/stop      # Stop pomodoro
```

---

## 🔄 Recent Changes (Super App 2.0)

### Navigation Reorganization
- ✅ Moved Deep Work to dedicated sidebar section
- ✅ Moved Work Profiles to sidebar
- ✅ Moved Teams to sidebar with 3 tabs
- ✅ Created standalone Dashboard view
- ✅ Simplified Settings layout

### UI Improvements
- ✅ Compact Calendar Sync with inline selector
- ✅ Redesigned Work Hours with steppers (no sliders)
- ✅ Fixed Local API status display
- ✅ Added Calendar activity to menu bar
- ✅ Deep Work banner in Pomodoro view

### New Features
- ✅ Teams integration with 3 tabs (Status/Credentials/Activities)
- ✅ Calendar selector (choose specific calendars)
- ✅ Next event preview in menu bar
- ✅ Deep Work countdown timer
- ✅ Visual indicators for all smart features

### ML Autoconfiguration (NEW)
- ✅ **Smart Schedule Learning** - ML model learns work patterns automatically
- ✅ **Auto-Training** - Model trains automatically when enough data is collected
- ✅ **Work Hour Prediction** - Predicts optimal hours based on history
- ✅ **Holiday Exclusion** - Exclude holidays from training
- ✅ **Auto-apply** - Automatically adjust settings every day
- ✅ **Manual Override** - Train manually anytime with "Train Now"

### Bug Fixes (Latest)
- ✅ **Fixed layout recursion crash** in menu bar calendar card
- ✅ **Fixed SF Symbols compatibility** for older macOS versions
- ✅ Improved app stability and launch time

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
