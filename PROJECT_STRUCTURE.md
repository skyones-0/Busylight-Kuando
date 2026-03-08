# Busylight Multi-Platform Project Structure

## 🏗️ Estructura Organizada

```
Busylight/
│
├── 📁 macOS/                        # APP macOS
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
├── 📁 iOS/                          # APP iOS
│   └── Sources/
│       ├── Core/
│       │   └── BusylightIOSApp.swift        # Entry point iOS
│       ├── Views/
│       │   └── IOSContentView.swift         # UI completa iOS
│       └── LiveActivity/
│           └── LiveActivityManager.swift    # Live Activities + Dynamic Island
│
├── 📁 watchOS/                      # APP watchOS
│   └── Sources/
│       ├── Core/
│       │   └── BusylightWatchApp.swift      # Entry point watchOS
│       └── Views/
│           └── WatchContentView.swift       # UI básica watchOS
│
├── 📁 Shared/                       # FRAMEWORK COMPARTIDO
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

### macOS
- 💻 Control hardware Busylight (USB)
- ⏱️ Timer Pomodoro completo
- 🔔 Notificaciones nativas
- 🎨 Glassmorphism UI
- 📊 ML Scheduling inteligente
- 🌐 Webhook server integrado
- ☁️ CloudKit sync

### iOS
- ⏱️ Timer Pomodoro completo
- 🔔 Live Activities (pantalla bloqueada)
- 🏝️ Dynamic Island
- 🔊 Sonidos de alerta
- 📳 Haptic feedback
- ☁️ CloudKit sync
- 🎨 Glassmorphism UI

### watchOS
- ⏱️ Timer display
- ▶️ Controles básicos
- 🔔 Alertas
- ☁️ CloudKit sync

### Shared
- 📦 Framework reutilizable
- ☁️ CloudKit synchronization
- 🎨 Glassmorphism components
- 🔊 Audio & Haptics

## 🚀 Configuración Xcode

### Targets existentes:
1. **macOS** - App macOS (principal)
2. **iOS** - App iOS
3. **watchOS** - App watchOS
4. **Shared** - Framework compartido

### Dependencias

| Target | Dependencias |
|--------|-------------|
| macOS | Shared, BusylightSDK_Swift.framework |
| iOS | Shared, ActivityKit, SwiftData |
| watchOS | Shared, SwiftData |

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

- ✅ Código macOS en `macOS/`
- ✅ Código iOS en `iOS/`
- ✅ Código watchOS en `watchOS/`
- ✅ Código compartido en `Shared/`
- ✅ Sin duplicados - cada plataforma en su carpeta
- ✅ Estructura limpia y organizada
