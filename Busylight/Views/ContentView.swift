//
//  ContentView.swift
//  Busylight
//
//  Created by Jose Araujo on 20/02/26.
//

import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case pomodoro = "Pomodoro"
    case teams = "Teams"
    case configuration = "Settings"
    case about = "About"
    case device = "Device"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .pomodoro: return "timer"
        case .teams: return "person.2.fill"
        case .configuration: return "gearshape.fill"
        case .about: return "info.circle.fill"
        case .device: return "lightbulb.fill"
        }
    }
}

struct ContentView: View {
    @StateObject private var busylight = BusylightManager()
    @EnvironmentObject var appDelegate: AppDelegate
    @State private var selectedItem: SidebarItem = .pomodoro
    
    var body: some View {
        NavigationSplitView {
            // Sidebar con glassmorphism
            ZStack {
                // Background
                MeshGradientBackground()
                
                // Sidebar content
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange.opacity(0.8), .red.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .shadow(color: .orange.opacity(0.4), radius: 10, x: 0, y: 4)
                            
                            Image(systemName: "lightbulb.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                        
                        Text("Busylight")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                        
                        Text("Control Center")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Navigation items
                    VStack(spacing: 4) {
                        ForEach(SidebarItem.allCases) { item in
                            GlassSidebarItem(item: item, isSelected: selectedItem == item)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedItem = item
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    Spacer()
                    
                    // Connection status en sidebar
                    GlassStatusCard(busylight: busylight)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 16)
                }
            }
            .frame(minWidth: 180, idealWidth: 200, maxWidth: 220)
        } detail: {
            // Detail view con glassmorphism background
            ZStack {
                MeshGradientBackground()
                
                ScrollView {
                    switch selectedItem {
                    case .pomodoro:
                        PomodoroView(busylight: busylight)
                    case .teams:
                        TeamsView()
                    case .configuration:
                        ConfigurationView()
                    case .about:
                        AboutView(busylight: busylight)
                    case .device:
                        DeviceView(busylight: busylight)
                    }
                }
            }
        }
        .frame(minWidth: 750, idealWidth: 850, maxWidth: 1000,
               minHeight: 550, idealHeight: 650, maxHeight: 800)
        .onReceive(NotificationCenter.default.publisher(for: .openMainWindow)) { _ in
            BusylightLogger.shared.debug("Recibida notificación openMainWindow")
            bringWindowToFront()
        }
    }
    
    private func bringWindowToFront() {
        BusylightLogger.shared.debug("Ejecutando bringWindowToFront")
        NSApp.activate(ignoringOtherApps: true)
        NSApp.unhide(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for window in NSApp.windows {
                if window.isVisible || !window.isMiniaturized {
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                    BusylightLogger.shared.info("Ventana traída al frente exitosamente")
                    return
                }
            }
            BusylightLogger.shared.warning("No se encontró ventana para traer al frente")
        }
    }
}

// MARK: - Sidebar Status Card
struct GlassStatusCard: View {
    @ObservedObject var busylight: BusylightManager
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                // Connection indicator
                ZStack {
                    Circle()
                        .fill(busylight.isConnected ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                        .shadow(color: (busylight.isConnected ? Color.green : Color.red).opacity(0.6), radius: 4)
                    
                    // Pulse animation
                    if busylight.isConnected {
                        PulsingCircle()
                    }
                }
                
                Text(busylight.isConnected ? "Connected" : "Disconnected")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                
                Spacer()
            }
            
            if busylight.isConnected {
                Text(busylight.deviceName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Current color indicator
            HStack(spacing: 8) {
                Text("Active:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Circle()
                    .fill(busylight.color)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: busylight.color.opacity(0.5), radius: 4, x: 0, y: 2)
                
                Spacer()
            }
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.thinMaterial)
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
    }
}

// MARK: - Test View (Glassmorphism)
struct DeviceView: View {
    @ObservedObject var busylight: BusylightManager
    
    private var colors: [(name: String, color: Color, action: () -> Void)] {
        [
            ("Red", .red, { busylight.red() }),
            ("Green", .green, { busylight.green() }),
            ("Blue", .blue, { busylight.blue() }),
            ("Yellow", .yellow, { busylight.yellow() }),
            ("Cyan", .cyan, { busylight.cyan() }),
            ("Magenta", .pink, { busylight.magenta() }),
            ("White", .white, { busylight.white() }),
            ("Orange", .orange, { busylight.orange() }),
            ("Purple", .purple, { busylight.purple() }),
            ("Pink", .pink, { busylight.pink() })
        ]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 4) {
                Text("Light Control")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                
                Text("Test your Busylight device")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Colors Section
            GlassCard(title: "Solid Colors", icon: "paintpalette.fill") {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 75, maximum: 85), spacing: 10)
                ], spacing: 10) {
                    ForEach(colors, id: \.name) { item in
                        GlassColorButton(
                            name: item.name,
                            color: item.color,
                            action: {
                                BusylightLogger.shared.info("DeviceView: \(item.name) presionado")
                                item.action()
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Jingles Section
            GlassCard(title: "Audio Jingles", icon: "speaker.wave.2.fill") {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 8)
                ], spacing: 8) {
                    ForEach(1...16, id: \.self) { number in
                        GlassJingleButton(number: number) {
                            BusylightLogger.shared.info("DeviceView: Jingle \(number) presionado")
                            busylight.jingle(
                                soundNumber: number,
                                red: Int.random(in: 0...100),
                                green: Int.random(in: 0...100),
                                blue: Int.random(in: 0...100),
                                andVolume: Int.random(in: 30...100)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Quick Actions
            GlassCard(title: "Quick Actions", icon: "bolt.fill") {
                HStack(spacing: 12) {
                    GlassActionButton(
                        title: "Off",
                        icon: "power",
                        color: .gray,
                        action: { busylight.off() }
                    )
                    
                    GlassActionButton(
                        title: "Pulse",
                        icon: "waveform",
                        color: .blue,
                        action: { busylight.pulseBlue() }
                    )
                    
                    GlassActionButton(
                        title: "Blink",
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        action: { busylight.blinkRedFast() }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer(minLength: 20)
        }
    }
}

// MARK: - Pomodoro View (Elegant Design)
struct PomodoroView: View {
    @ObservedObject var busylight: BusylightManager
    @ObservedObject private var manager = PomodoroManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Elegant Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.title3)
                        .foregroundStyle(manager.currentPhase.color)
                    
                    Text(NSLocalizedString("Focus Session", comment: "Pomodoro session title"))
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                }
                
                Spacer()
                
                // Elegant Phase Pill
                PhasePill(
                    phase: manager.currentPhase.rawValue,
                    icon: manager.currentPhase.icon,
                    color: manager.currentPhase.color
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Main Timer Card
            VStack(spacing: 12) {
                // Timer
                Text(manager.timeString)
                    .font(.system(size: 64, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                
                // Set Counter
                HStack(spacing: 4) {
                    Text(NSLocalizedString("Session", comment: "Session label"))
                        .foregroundStyle(.secondary)
                    Text("\(manager.currentSet)/\(manager.totalSets)")
                        .fontWeight(.semibold)
                        .foregroundStyle(manager.currentPhase.color)
                }
                .font(.subheadline)
                
                // Elegant Progress Bar
                ElegantProgressBar(
                    progress: manager.progress,
                    color: manager.currentPhase.color
                )
                .padding(.horizontal, 60)
                .padding(.top, 4)
            }
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(manager.currentPhase.color.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            .shadow(color: manager.currentPhase.color.opacity(0.1), radius: 20, x: 0, y: 10)
            
            // Config Summary Row
            HStack(spacing: 12) {
                ConfigItem(
                    icon: "briefcase.fill",
                    label: manager.currentPhase == .work && manager.isRunning ? NSLocalizedString("Working", comment: "Active work phase") : NSLocalizedString("Work", comment: "Work phase"),
                    value: "\(manager.workTimeMinutes)m",
                    color: manager.currentPhase == .work && manager.isRunning ? .green : .gray
                )
                ConfigItem(
                    icon: "cup.and.saucer.fill",
                    label: manager.currentPhase == .shortBreak && manager.isRunning ? NSLocalizedString("Resting", comment: "Active break phase") : NSLocalizedString("Break", comment: "Break phase"),
                    value: "\(manager.shortBreakMinutes)m",
                    color: manager.currentPhase == .shortBreak && manager.isRunning ? .blue : .gray
                )
                ConfigItem(
                    icon: "sun.max.fill",
                    label: manager.currentPhase == .longBreak && manager.isRunning ? NSLocalizedString("Relaxing", comment: "Active long break phase") : NSLocalizedString("Long", comment: "Long break phase"),
                    value: "\(manager.longBreakMinutes)m",
                    color: manager.currentPhase == .longBreak && manager.isRunning ? .orange : .gray
                )
                ConfigItem(icon: "number", label: NSLocalizedString("Sets", comment: "Number of sets"), value: "\(manager.configuredSets)", color: .purple)
            }
            .padding(.horizontal, 24)
            
            // Stepper Row
            HStack(spacing: 12) {
                ElegantStepper(icon: "briefcase.fill", value: $manager.workTimeMinutes, range: 1...60)
                    .onChange(of: manager.workTimeMinutes) { manager.updateConfiguration() }
                
                ElegantStepper(icon: "cup.and.saucer.fill", value: $manager.shortBreakMinutes, range: 1...30)
                    .onChange(of: manager.shortBreakMinutes) { manager.updateConfiguration() }
                
                ElegantStepper(icon: "sun.max.fill", value: $manager.longBreakMinutes, range: 1...60)
                    .onChange(of: manager.longBreakMinutes) { manager.updateConfiguration() }
                
                ElegantStepper(icon: "arrow.clockwise", value: $manager.configuredSets, range: 1...10)
                    .onChange(of: manager.configuredSets) { manager.updateConfiguration() }
            }
            .padding(.horizontal, 24)
            .disabled(manager.isRunning)
            .opacity(manager.isRunning ? 0.5 : 1)
            
            // Control Buttons
            HStack(spacing: 16) {
                ControlButton(
                    title: manager.isPaused ? NSLocalizedString("Resume", comment: "Resume button") : NSLocalizedString("Start", comment: "Start button"),
                    icon: "play.fill",
                    color: .green,
                    isProminent: true,
                    action: { manager.start() }
                )
                .disabled(manager.isRunning && !manager.isPaused)
                
                ControlButton(
                    title: NSLocalizedString("Pause", comment: "Pause button"),
                    icon: "pause.fill",
                    color: .orange,
                    isProminent: false,
                    action: { manager.pause() }
                )
                .disabled(!manager.isRunning || manager.isPaused)
                
                ControlButton(
                    title: NSLocalizedString("Stop", comment: "Stop button"),
                    icon: "stop.fill",
                    color: .red,
                    isProminent: false,
                    action: { manager.stop() }
                )
                .disabled(!manager.isRunning && !manager.isPaused)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
}

// Phase Pill
struct PhasePill: View {
    let phase: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(phase)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .foregroundStyle(color)
    }
}

// Config Item
struct ConfigItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.caption, design: .rounded).weight(.semibold))
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// Elegant Stepper
struct ElegantStepper: View {
    let icon: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        HStack(spacing: 10) {
            Button {
                if value > range.lowerBound {
                    value -= 1
                    HapticFeedback.light()
                }
            } label: {
                Image(systemName: "minus")
                    .font(.callout.weight(.bold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(ElegantStepperButtonStyle())
            
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(value)")
                    .font(.system(.body, design: .rounded).weight(.semibold))
            }
            .frame(minWidth: 40)
            
            Button {
                if value < range.upperBound {
                    value += 1
                    HapticFeedback.light()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.callout.weight(.bold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(ElegantStepperButtonStyle())
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct ElegantStepperButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? .white : .secondary)
            .background(
                Circle()
                    .fill(configuration.isPressed ? Color.accentColor : Color.gray.opacity(0.2))
            )
            .focusable(false)
    }
}

// Control Button with Prolonged Haptic
struct ControlButton: View {
    let title: String
    let icon: String
    let color: Color
    let isProminent: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.prolonged()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.callout)
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(isProminent ? .semibold : .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(ControlButtonStyle(color: color, isProminent: isProminent))
    }
}

struct ControlButtonStyle: ButtonStyle {
    let color: Color
    let isProminent: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isProminent ? .white : color)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            configuration.isPressed
                                ? color.opacity(isProminent ? 1 : 0.3)
                                : color.opacity(isProminent ? 0.8 : 0.15)
                        )
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(configuration.isPressed ? 0.8 : 0.4), lineWidth: 1)
                }
            )
            .shadow(
                color: color.opacity(configuration.isPressed ? 0.4 : 0.2),
                radius: configuration.isPressed ? 8 : 4,
                x: 0,
                y: configuration.isPressed ? 4 : 2
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .focusable(false)
    }
}

struct ConfigLabel: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(.caption2, design: .rounded).weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Teams View (Glassmorphism)
struct TeamsView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isLoggedIn = false
    @State private var microsoftStatus = "Disconnected"
    @State private var teamsStatus = "Offline"
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.8), .purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 5)
                    
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.white)
                }
                
                Text("Microsoft Teams")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                
                Text("Sync your presence status")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
            
            // Login Card
            GlassCard(
                title: isLoggedIn ? "Account Connected" : "Sign In",
                icon: isLoggedIn ? "checkmark.shield.fill" : "person.crop.circle.fill",
                material: .ultraThinMaterial
            ) {
                VStack(spacing: 14) {
                    if !isLoggedIn {
                        GlassTextField(
                            placeholder: "Email",
                            text: $username,
                            icon: "envelope.fill"
                        )
                        
                        GlassTextField(
                            placeholder: "Password",
                            text: $password,
                            icon: "lock.fill",
                            isSecure: true
                        )
                    } else {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(username.isEmpty ? "user@company.com" : username)
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                    Text("Connected")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Material.thinMaterial)
                        )
                    }
                    
                    Button {
                        BusylightLogger.shared.info("Teams: Login presionado")
                        withAnimation(.spring(response: 0.4)) {
                            isLoggedIn.toggle()
                            microsoftStatus = isLoggedIn ? "Connected" : "Disconnected"
                            teamsStatus = isLoggedIn ? "Available" : "Offline"
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isLoggedIn ? "xmark.circle.fill" : "arrow.right.circle.fill")
                            Text(isLoggedIn ? "Disconnect" : "Connect Account")
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.gradientWave(color: isLoggedIn ? .red : .blue, prominent: !isLoggedIn))
                }
            }
            .frame(maxWidth: 380)
            
            // Status Card (when logged in)
            if isLoggedIn {
                GlassCard(title: "Presence Status", icon: "status") {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            StatusOption(
                                icon: "checkmark.circle.fill",
                                title: "Available",
                                color: .green,
                                isSelected: teamsStatus == "Available"
                            ) {
                                teamsStatus = "Available"
                            }
                            
                            StatusOption(
                                icon: "minus.circle.fill",
                                title: "Busy",
                                color: .red,
                                isSelected: teamsStatus == "Busy"
                            ) {
                                teamsStatus = "Busy"
                            }
                            
                            StatusOption(
                                icon: "moon.circle.fill",
                                title: "DND",
                                color: .purple,
                                isSelected: teamsStatus == "Do Not Disturb"
                            ) {
                                teamsStatus = "Do Not Disturb"
                            }
                            
                            StatusOption(
                                icon: "clock.circle.fill",
                                title: "Away",
                                color: .orange,
                                isSelected: teamsStatus == "Away"
                            ) {
                                teamsStatus = "Away"
                            }
                        }
                    }
                }
                .frame(maxWidth: 380)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct StatusOption: View {
    let icon: String
    let title: String
    let color: Color
    var isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color.opacity(0.15))
                        
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color.opacity(0.4), lineWidth: 1.5)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Material.thinMaterial)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Configuration View (Glassmorphism)
struct ConfigurationView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @AppStorage("appearanceMode") private var appearanceMode = 0
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 4) {
                Text("Settings")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                
                Text("Customize your experience")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Appearance Card
            GlassCard(title: "Appearance", icon: "paintbrush.fill") {
                VStack(spacing: 16) {
                    Picker("Theme", selection: $appearanceMode) {
                        Label("System", systemImage: "macpro.gen1").tag(0)
                        Label("Light", systemImage: "sun.max.fill").tag(1)
                        Label("Dark", systemImage: "moon.fill").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: appearanceMode) { _, newValue in
                        BusylightLogger.shared.info("Appearance: \(newValue)")
                    }
                    
                    Divider()
                        .opacity(0.5)
                    
                    HStack(spacing: 16) {
                        GlassToggleRow(
                            icon: "dock.rectangle",
                            title: "Show in Dock",
                            isOn: $appDelegate.showInDock
                        )
                        
                        GlassToggleRow(
                            icon: "menubar.rectangle",
                            title: "Show in Menu Bar",
                            isOn: $appDelegate.showInMenuBar
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Info Card
            GlassCard(title: "Application", icon: "app.badge.fill") {
                VStack(spacing: 12) {
                    InfoRowGlass(label: "Version", value: "1.0.0", icon: "number")
                    InfoRowGlass(label: "Build", value: "2026.03.07", icon: "hammer.fill")
                    InfoRowGlass(label: "Developer", value: "Sky One", icon: "person.fill")
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

struct GlassToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            Text(title)
                .font(.system(.body, design: .rounded))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Material.thinMaterial)
                
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            }
        )
    }
}

struct InfoRowGlass: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(label)
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(.callout, design: .rounded).weight(.medium))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - About View (Glassmorphism)
struct AboutView: View {
    @ObservedObject var busylight: BusylightManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.orange.opacity(0.4), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .orange.opacity(0.5), radius: 20, x: 0, y: 8)
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }
                
                VStack(spacing: 4) {
                    Text("Busylight")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 20)
            
            // Info Cards
            HStack(spacing: 16) {
                GlassCard(title: "Device", icon: "lightbulb.fill") {
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: busylight.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(busylight.isConnected ? .green : .red)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(busylight.isConnected ? "Connected" : "Disconnected")
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                
                                Text(busylight.deviceName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        if busylight.isConnected {
                            HStack(spacing: 8) {
                                Text("Current Color:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Circle()
                                    .fill(busylight.color)
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Circle()
                                            .stroke(.white.opacity(0.4), lineWidth: 1)
                                    )
                                    .shadow(color: busylight.color.opacity(0.5), radius: 4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                GlassCard(title: "About", icon: "info.circle.fill") {
                    VStack(spacing: 8) {
                        Text("Professional USB status light control for modern workspaces.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Divider()
                            .opacity(0.5)
                        
                        Text("© 2026 Sky One")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

// MARK: - Supporting Views
struct GlassActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
        }
        .buttonStyle(.plain)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.thinMaterial)
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(isHovered ? 0.4 : 0.2),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: color.opacity(isHovered ? 0.3 : 0.1), radius: isHovered ? 12 : 4, x: 0, y: isHovered ? 6 : 2)
        .scaleEffect(isHovered ? 1.02 : 1)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// Pulsing Circle Component - separado para evitar layout recursion
struct PulsingCircle: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.green)
            .frame(width: 10, height: 10)
            .opacity(isAnimating ? 0.3 : 0.6)
            .scaleEffect(isAnimating ? 1.8 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

// Elegant Progress Bar - separado para evitar layout recursion
struct ElegantProgressBar: View {
    let progress: Double
    let color: Color
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 6)
                
                // Progress
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.8),
                                color
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geo.size.width * animatedProgress), height: 6)
                    .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 0)
            }
        }
        .frame(height: 6)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.linear(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppDelegate())
    }
}
