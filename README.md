
&lt;p align="center"&gt;
  &lt;img src="https://via.placeholder.com/120x120/6366f1/ffffff?text=BL" alt="Busylight Logo" width="120" height="120" style="border-radius: 20px;"&gt;
&lt;/p&gt;

&lt;h1 align="center"&gt;Busylight for macOS&lt;/h1&gt;

&lt;p align="center"&gt;
  &lt;b&gt;Professional USB status light control for modern workspaces&lt;/b&gt;
&lt;/p&gt;

&lt;p align="center"&gt;
  &lt;a href="#"&gt;&lt;img src="https://img.shields.io/badge/macOS-13.0%2B-000000?logo=apple&logoColor=white" alt="macOS"&gt;&lt;/a&gt;
  &lt;a href="#"&gt;&lt;img src="https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white" alt="Swift"&gt;&lt;/a&gt;
  &lt;a href="#"&gt;&lt;img src="https://img.shields.io/badge/Architecture-ARM64-FF6B6B" alt="ARM64"&gt;&lt;/a&gt;
  &lt;a href="#"&gt;&lt;img src="https://img.shields.io/badge/License-MIT-4ECDC4" alt="License"&gt;&lt;/a&gt;
  &lt;a href="#"&gt;&lt;img src="https://img.shields.io/badge/Status-Active-95E1D3" alt="Status"&gt;&lt;/a&gt;
&lt;/p&gt;

&lt;p align="center"&gt;
  &lt;a href="#features"&gt;Features&lt;/a&gt; •
  &lt;a href="#installation"&gt;Installation&lt;/a&gt; •
  &lt;a href="#usage"&gt;Usage&lt;/a&gt; •
  &lt;a href="#architecture"&gt;Architecture&lt;/a&gt; •
  &lt;a href="#roadmap"&gt;Roadmap&lt;/a&gt;
&lt;/p&gt;

---

## ✨ Features

&lt;table&gt;
&lt;tr&gt;
&lt;td width="50%"&gt;

### 🎨 **Color Control**
- 10 solid colors with precise RGB values
- Smooth pulse breathing effects
- Configurable blink patterns (slow/medium/fast)

&lt;/td&gt;
&lt;td width="50%"&gt;

### 🔊 **Audio Integration**
- 8 built-in alert sounds
- Volume control (0-100%)
- Custom jingles with color sync

&lt;/td&gt;
&lt;/tr&gt;
&lt;tr&gt;
&lt;td width="50%"&gt;

### ⏱️ **Productivity Timer**
- Pomodoro-style focus sessions
- Automatic light state changes
- Menu bar quick access

&lt;/td&gt;
&lt;td width="50%"&gt;

### 🖥️ **Native macOS**
- SwiftUI interface
- Menu bar extra support
- Sandboxed & code-signed

&lt;/td&gt;
&lt;/tr&gt;
&lt;/table&gt;

---

## 🚀 Quick Start

### Prerequisites

| Component | Minimum Version |
|-----------|----------------|
| macOS | 13.0 (Ventura) |
| Xcode | 15.0 |
| Swift | 5.9 |
| Hardware | Apple Silicon (ARM64) |

### Installation

```bash
# Clone repository
git clone https://github.com/skyones-0/kuando_macos.git
cd kuando_macos/Busylight

# Open in Xcode
open Busylight.xcodeproj

# Build and run (⌘R)


// Solid colors
busylight.red()      // RGB(100, 0, 0)
busylight.green()    // RGB(0, 100, 0)
busylight.blue()     // RGB(0, 0, 100)

// Pulse effects
busylight.pulseRed()
busylight.pulseBlue()

// Blink patterns
busylight.blinkRedFast()    // 200ms intervals
busylight.blinkGreenSlow()  // 1s intervals

// Custom jingle with color and sound
busylight.jingle(
    soundNumber: 5,
    red: 100,
    green: 50,
    blue: 0,
    andVolume: 75
)

// Alert with auto-off
busylight.alertLoud()
// Auto resets after 10 seconds

┌─────────────────────────────────────────┐
│           Presentation Layer            │
│  ┌─────────────┐    ┌───────────────┐  │
│  │ ContentView │    │  MenuBarView  │  │
│  │  (Colors)   │    │  (Quick Menu) │  │
│  └──────┬──────┘    └───────┬───────┘  │
│         │                   │           │
│  ┌─────────────┐    ┌───────────────┐  │
│  │  TimerView  │    │ AppDelegate   │  │
│  │ (Pomodoro)  │    │  (Lifecycle)  │  │
│  └──────┬──────┘    └───────────────┘  │
└─────────┼───────────────────────────────┘
          │
┌─────────▼───────────────────────────────┐
│         Business Logic Layer            │
│         BusylightManager                │
│  ┌─────────────────────────────────┐    │
│  │  • ObservableObject             │    │
│  │  • @Published state properties  │    │
│  │  • USB device management        │    │
│  └─────────────────────────────────┘    │
└───────────────────┬─────────────────────┘
                    │
┌───────────────────▼─────────────────────┐
│           Hardware Abstraction          │
│      BusylightSDK_Swift.framework       │
│  ┌─────────────────────────────────┐    │
│  │  • USB HID communication        │    │
│  │  • Device discovery             │    │
│  │  • Light & sound commands       │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘

Busylight/
├── 📱 Application
│   ├── BusylightApp.swift          # Entry point
│   ├── AppDelegate.swift           # Dock/MenuBar config
│   └── Persistence.swift           # Core Data stack
│
├── 🖼️ Views
│   ├── ContentView.swift           # Main color controls
│   ├── MenuBarView.swift           # Status bar interface
│   └── TimerView.swift             # Pomodoro timer
│
├── 🧠 Core
│   └── BusylightManager.swift      # Device controller
│
└── 🔌 Vendor
    └── BusylightSDK_Swift.framework  # Official SDK




// Example: Type-safe color API
func light(red: Int, green: Int, blue: Int) {
    bl?.Light(
        red: UInt8(red),
        green: UInt8(green),
        blue: UInt8(blue)
    )
}

// Automatic cleanup with deferred off command
DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
    self?.off()
}

🗺️ Roadmap

[x] Core color control
[x] Pulse & blink effects
[x] Audio alerts
[x] Menu bar integration
[x] Pomodoro timer
[ ] Intel (x86_64) support
[ ] Keyboard shortcuts
[ ] Custom color presets
[ ] Meeting integration (Zoom/Teams)
[ ] HomeKit bridge
