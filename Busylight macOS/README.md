# Busylight for Kuando

<p align="center">
  <img src="Busylight%20macOS/icon%20Exports/icon-macOS-Dark-256x256@1x.png" alt="Busylight Logo" width="120" height="120">
</p>

<p align="center">
  <b>Professional USB status light control with ML-powered schedule prediction</b>
</p>

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/macOS-26.2%2B-000000?logo=apple&logoColor=white" alt="macOS"></a>
  <a href="#"><img src="https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white" alt="Swift"></a>
  <a href="#"><img src="https://img.shields.io/badge/SwiftUI-Yes-007AFF?logo=swift&logoColor=white" alt="SwiftUI"></a>
  <a href="#"><img src="https://img.shields.io/badge/Core%20ML-Enabled-FF6B6B" alt="CoreML"></a>
  <a href="#"><img src="https://img.shields.io/badge/Localization-Spanish%20100%25-blue" alt="Spanish"></a>
</p>

<p align="center">
  <img src="https://github.com/skyones-0/Busylight-Kuando/workflows/Validate%20Project/badge.svg" alt="Validate Project">
</p>

---

## ✨ Features

### Core Features
- **💡 Light Control** - 10 colors + pulse, blink, and audio effects
- **⏱️ Pomodoro Timer** - Phase management with work/break cycles
- **🔥 Deep Work Mode** - Distraction-free sessions with auto-pause Pomodoro
- **🔊 Audio Integration** - 16 jingles and alert sounds

### ML & AI Features
- **🧠 Smart Schedule Learning** - CoreML models learn your work patterns
- **📈 Work Hour Prediction** - Predicts optimal start/end hours for each day
- **🎯 Holiday Exclusion** - Mark holidays to exclude from ML training
- **⚡ Auto-Configuration** - Automatically adjusts settings based on predictions

### Productivity Features
- **📅 Calendar Sync** - Auto-detect meetings and sync status
- **🌙 Focus Mode Sync** - macOS Focus integration
- **🕐 Smart Work Hours** - Schedule reminders and automatic adjustments
- **🎨 Glassmorphism UI** - Modern design with blur effects

### Integrations
- **🌐 Local API Server** - HTTP endpoints at localhost:8080
- **👔 Microsoft Teams** - Presence sync support
- **📊 Productivity Dashboard** - Stats and insights

---

## 📋 Requirements

| Component | Minimum Version |
|-----------|----------------|
| macOS | 26.2+ |
| Xcode | 16.0+ |
| Swift | 5.9+ |
| Hardware | Apple Silicon (ARM64) |
| Device | Kuando Busylight Omega series |

---

## 🏗️ Project Structure

```
Busylight macOS/
│
├── 📁 Busylight macOS/              # Main App
│   ├──
│   │   ├── BusylightApp.swift       # App entry point
│   │   ├── BusylightManager.swift   # Device control (USB)
│   │   ├── PomodoroManager.swift    # Timer logic
│   │   └── Persistence.swift        # SwiftData
│   │
│   ├── 📁 Views/                    # SwiftUI Views
│   │   ├── ContentView.swift        # Main UI
│   │   ├── MenuBarView.swift        # Menu bar popover
│   │   └── TimerView.swift          # Timer overlay
│   │
│   ├── 📁 CoreML/                   # ML Models & Logic
│   │   ├── TrainedModelLoader.swift # Load Create ML models
│   │   ├── WorkSchedulePredictor.swift # In-app training
│   │   └── 📁 ML Model/             # Pre-trained models
│   │       ├── StartHours.mlpackage
│   │       └── EndHours.mlpackage
│   │
│   ├── 📁 Utilities/                # Managers
│   │   ├── MLScheduleManager.swift  # ML orchestration
│   │   ├── SmartFeaturesManager.swift
│   │   ├── WebhookServer.swift      # Local API
│   │   ├── BusylightLogger.swift
│   │   └── UserInteractionLogger.swift
│   │
│   ├── 📁 Models/                   # SwiftData Models
│   │   ├── MLWorkPattern.swift
│   │   └── PomodoroSession.swift
│   │
│   ├── 📁 Resources/                # Assets & Localization
│   │   └── Localizable.xcstrings    # 100% Spanish translated
│   │
│   └── 📁 Styles/                   # UI Styles
│       └── GlassmorphismStyles.swift
│
├── 📁 BusylightTests/               # Unit Tests
│   └── MLModelTests.swift           # CoreML model tests
│
├── 📁 ML Training Data/             # Training datasets
│   ├── work_schedule_training_data.csv
│   ├── testing_data.csv
│   └── 📁 predict_hours.mlproj/     # Create ML project
│
└── 📁 BusylightSDK_Swift.framework/ # Hardware SDK
```

---

## 🚀 Installation

### Build & Run
```bash
# Clone repository
git clone https://github.com/skyones-0/Busylight-Kuando.git
cd Busylight-Kuando

# Open in Xcode
open "Busylight macOS/Busylight macOS.xcodeproj"

# Build and run (Cmd+R)
```

### Running Tests
```bash
# Run unit tests (Cmd+U in Xcode)
# or via command line:
xcodebuild test -project "Busylight mac OS/Busylight mac OS.xcodeproj" \
  -scheme "Busylight mac OS" \
  -destination 'platform=macOS'
```

---

## 📖 Usage Guide

### First Launch
1. Connect your Kuando Busylight via USB
2. Grant USB permissions when prompted
3. The app will automatically detect the device

### Light Control
- **Solid Colors**: Red, Green, Blue, Yellow, Cyan, Magenta, White, Orange, Purple, Pink
- **Pulse Effects**: Slow breathing effect in any color
- **Blink Patterns**: Slow, Medium, Fast blinking
- **Audio**: 16 different jingles and alert sounds

### Pomodoro Timer
1. Select duration (15, 25, or 45 minutes)
2. Click **Start** to begin
3. Light shows work status automatically
4. Auto-switches to break phase

### Deep Work Mode
1. Click **Deep Work** in sidebar
2. Choose duration (60/90/120 min)
3. Pomodoro auto-pauses
4. Light turns red (busy status)
5. Timer counts down with progress bar

### ML Schedule Learning

#### Setup
1. Go to **Settings > Smart Schedule Learning**
2. Enable **Smart Schedule Learning**
3. Enable **Auto-train model** for automatic training
4. Enable **Auto-apply predictions** to auto-adjust work hours

#### How It Works
- The app collects your daily work patterns automatically
- After **3+ days** of data, the model can train
- Training happens automatically (or manually via "Train Now")
- Predictions are made for tomorrow's optimal work hours
- Work hours are adjusted automatically (if enabled)

#### Managing Holidays
1. Go to **Settings > Holiday Calendars**
2. Add a holiday calendar (e.g., "US Holidays 2026")
3. Select dates that should be excluded from ML training
4. ML model will ignore these days when learning patterns

#### ML Console Log Indicators
- 🚀 `ML: Starting training` - Training started
- ⏳ `ML: Training model` - Training in progress  
- ✅ `ML: Training completed` - Training finished
- ❌ `ML: Training error` - Training failed
- 📝 `ML: New daily pattern created` - New pattern collected
- 🎯 `ML: Minimum data reached` - Ready to train
- 🔮 `ML: Prediction generated` - Prediction created
- 🔄 `ML: Hours auto-adjusted` - Hours updated

### Local API Server
1. Go to **Settings > Local API Server**
2. Toggle **Local API Server**
3. Server runs on `http://localhost:8080`

**Available endpoints:**
```bash
GET  /status              # Get current status
POST /color               # Set light color {r,g,b}
POST /status              # Set presence status
POST /timer/start         # Start pomodoro
POST /timer/pause         # Pause pomodoro
POST /timer/stop          # Stop pomodoro
```

---

## 🧪 Testing

### Unit Tests
The project includes comprehensive unit tests for ML models:

```swift
// MLModelTests.swift includes:
- testModelLoaderExists()           // Verify loader initialization
- testModelsLoadedSuccessfully()    // Verify CoreML models load
- testStartHourPredictionWeekday()  // Test weekday predictions
- testStartHourPredictionWeekend()  // Test weekend predictions
- testStartHourPredictionHoliday()  // Test holiday handling
- testPredictionConsistency()       // Verify deterministic output
- testEndHourAfterStartHour()       // Verify logical time ranges
- testPredictionPerformance()       // Measure prediction speed
```

Run tests with **Cmd+U** in Xcode.

---

## 🧠 ML Model Details

### Pre-trained Models (Create ML)
The app uses two CoreML models trained in Create ML:

- **StartHours.mlmodel** - Predicts optimal start hour (0-23)
- **EndHours.mlmodel** - Predicts optimal end hour (0-23)

### Input Features
- `dayOfWeek` - Day of week (1=Sunday, 7=Saturday)
- `isWeekend` - 0 or 1
- `isHoliday` - 0 or 1
- `sessionCount` - Number of work sessions
- `deepWorkMinutes` - Deep work duration
- `calendarEventCount` - Number of calendar events

### Fallback Training
If pre-trained models are not available, the app can train models in-app using CreateML framework with collected work patterns.

---

## 🌐 Localization

The app is fully localized in Spanish (100%):
- All UI strings translated
- Proper pluralization support
- Region-appropriate formatting

---

## 🛠️ Technical Details

### Frameworks Used
- **SwiftUI** - Modern declarative UI
- **SwiftData** - Local data persistence
- **CoreML** - Machine learning models
- **CreateML** - In-app model training
- **Combine** - Reactive programming
- **UserNotifications** - Local notifications

### Hardware Integration
- **BusylightSDK_Swift** - Official Kuando SDK
- USB HID communication
- Real-time device status

---

## 🔄 Recent Updates

### Latest Changes
- ✅ **100% Spanish Localization** - Complete translation
- ✅ **Unit Tests** - ML model validation tests
- ✅ **Pre-trained Models** - Create ML StartHours/EndHours models
- ✅ **Auto-training** - Automatic model retraining
- ✅ **Holiday Calendars** - Exclude holidays from training
- ✅ **Local API** - HTTP server for integrations

### Architecture Improvements
- ✅ Conditional compilation for testing (`#if !TESTING`)
- ✅ Modular ML architecture with fallback training
- ✅ SwiftData for local persistence
- ✅ Proper error handling and logging

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
