# Busylight Multi-Platform Project Structure

## 🏗️ Estructura Organizada

```
Busylight/
│
├── 📁 BusylightMac/                 # APP macOS
│   └── Sources/
│       ├── Core/
│       │   ├── BusylightApp.swift           # Entry point macOS
│       │   ├── BusylightManager.swift       # Control hardware Busylight
│       │   ├── PomodoroManager.swift        # Timer Pomodoro
│       │   ├── Persistence.swift            # SwiftData/Store
│       │   └── AppDelegate.swift            # AppDelegate macOS
│       ├── Models/
│       │   ├── MLWorkPattern.swift          # ML patrones
│       │   └── PomodoroSession.swift        # Sesión Pomodoro
│       ├── Views/
│       │   ├── ContentView.swift            # Vista principal
│       │   ├── MenuBarView.swift            # Menú bar
│       │   └── TimerView.swift              # Vista timer
│       ├── Utilities/
│       │   ├── BusylightLogger.swift        # Logger
│       │   ├── MLScheduleManager.swift      # ML scheduling
│       │   ├── SmartFeaturesManager.swift   # Features inteligentes
│       │   ├── WebhookServer.swift          # Webhook server
│       │   └── ViewController.swift         # ViewController
│       ├── Styles/
│       │   └── GlassmorphismStyles.swift    # UI Glassmorphism
│       ├── Resources/
│       │   └── Localizable.xcstrings        # Localizaciones
│       ├── Assets.xcassets/                 # Assets
│       ├── Busylight.entitlements           # Entitlements
│       └── Info.plist                       # Info plist
│
├── 📁 BusylightIOS/                 # APP iOS
│   └── Sources/
│       ├── Core/
│       │   └── BusylightIOSApp.swift        # Entry point iOS
│       ├── Views/
│       │   └── IOSContentView.swift         # UI completa iOS
│       └── LiveActivity/
│           └── LiveActivityManager.swift    # Live Activities + Dynamic Island
│
├── 📁 BusylightWatch/               # APP watchOS
│   └── Sources/
│       ├── Core/
│       │   └── BusylightWatchApp.swift      # Entry point watchOS
│       └── Views/
│           └── WatchContentView.swift       # UI básica watchOS
│
├── 📁 BusylightShared/              # FRAMEWORK COMPARTIDO
│   └── Sources/
│       ├── CloudKit/
│       │   └── CloudKitSyncManager.swift    # Sync CloudKit
│       ├── Managers/
│       │   └── UnifiedPomodoroManager.swift # Timer + sync + audio
│       ├── Models/
│       │   └── SharedModels.swift           # Modelos compartidos
│       └── Styles/
│           └── SharedStyles.swift           # UI Glassmorphism shared
│
├── 📁 BusylightTests/               # Tests unitarios
├── 📁 BusylightUITests/             # Tests UI
│
└── 📁 BusylightSDK_Swift.framework/ # SDK Hardware Busylight
```

## ✅ Características por Plataforma

### macOS (BusylightMac/)
- 💻 Control hardware Busylight (USB)
- ⏱️ Timer Pomodoro completo
- 🔔 Notificaciones nativas
- 🎨 Glassmorphism UI
- 📊 ML Scheduling inteligente
- 🌐 Webhook server integrado
- ☁️ CloudKit sync

### iOS (BusylightIOS/)
- ⏱️ Timer Pomodoro completo
- 🔔 Live Activities (pantalla bloqueada)
- 🏝️ Dynamic Island
- 🔊 Sonidos de alerta
- 📳 Haptic feedback
- ☁️ CloudKit sync
- 🎨 Glassmorphism UI

### watchOS (BusylightWatch/)
- ⏱️ Timer display
- ▶️ Controles básicos
- 🔔 Alertas
- ☁️ CloudKit sync

### Shared (BusylightShared/)
- 📦 Framework reutilizable
- ☁️ CloudKit synchronization
- 🎨 Glassmorphism components
- 🔊 Audio & Haptics

## 🚀 Configuración Xcode

### Targets existentes:
1. **BusylightMac** - App macOS (principal)
2. **BusylightIOS** - App iOS
3. **BusylightWatch** - App watchOS
4. **BusylightShared** - Framework compartido

### Dependencias

| Target | Dependencias |
|--------|-------------|
| BusylightMac | BusylightShared, BusylightSDK_Swift.framework |
| BusylightIOS | BusylightShared, ActivityKit, SwiftData |
| BusylightWatch | BusylightShared, SwiftData |

## ☁️ CloudKit Container

Usar el mismo en todos:
```
iCloud.co.skyones.Busylight
```

## 🎨 Sistema de Diseño

Todos usan **Glassmorphism**:
- `glass()` - Background con blur
- `GlassCard` - Tarjetas con borde
- `GlassButton` - Botones con efectos
- `GlassStepper` - Steppers estilizados
- `MeshGradientBackground` - Fondos animados

## 📱 Sincronización

El estado se sincroniza automáticamente:
1. Start/Pause/Stop en cualquier dispositivo
2. Cambios de configuración
3. Completado de fases

## 📝 Notas

- ✅ Código macOS movido de `Busylight/` a `BusylightMac/`
- ✅ Sin duplicados - cada plataforma en su carpeta
- ✅ Código compartido en `BusylightShared/`
- ✅ Estructura limpia y organizada
