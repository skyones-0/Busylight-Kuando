//
//  ContentView.swift
//  Busylight
//
//  Created by Jose Araujo on 20/02/26.
//

import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case pomodoro = "Pomodoro"
    case configuration = "Settings"
    case device = "Device"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .pomodoro: return "timer"
        case .configuration: return "gearshape.fill"
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
                    case .configuration:
                        SettingsView()
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
                
                // Elegant Phase Pill con efectos visuales
                PhaseLabel(
                    text: manager.currentPhase.rawValue,
                    color: manager.currentPhase.color,
                    isRunning: manager.isRunning
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
            
            // Config Summary Row - solo iconos y valores (sin labels)
            HStack(spacing: 12) {
                ConfigItem(
                    icon: "briefcase.fill",
                    label: "",
                    value: "\(manager.workTimeMinutes)m",
                    color: manager.currentPhase == .work && manager.isRunning ? .green : .gray
                )
                ConfigItem(
                    icon: "cup.and.saucer.fill",
                    label: "",
                    value: "\(manager.shortBreakMinutes)m",
                    color: manager.currentPhase == .shortBreak && manager.isRunning ? .blue : .gray
                )
                ConfigItem(
                    icon: "sun.max.fill",
                    label: "",
                    value: "\(manager.longBreakMinutes)m",
                    color: manager.currentPhase == .longBreak && manager.isRunning ? .orange : .gray
                )
                ConfigItem(icon: "number", label: "", value: "\(manager.configuredSets)", color: .purple)
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
            if !label.isEmpty {
                Text(label)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// Elegant Stepper - Ajustado para mejor proporción
struct ElegantStepper: View {
    let icon: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        HStack(spacing: 11) {
            Button {
                if value > range.lowerBound {
                    value -= 1
                    HapticFeedback.light()
                }
            } label: {
                Image(systemName: "minus")
                    .font(.callout.weight(.bold))
                    .frame(width: 33, height: 33)
            }
            .buttonStyle(ElegantStepperButtonStyle())
            
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(value)")
                    .font(.system(.body, design: .rounded).weight(.semibold))
            }
            .frame(minWidth: 41)
            
            Button {
                if value < range.upperBound {
                    value += 1
                    HapticFeedback.light()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.callout.weight(.bold))
                    .frame(width: 33, height: 33)
            }
            .buttonStyle(ElegantStepperButtonStyle())
        }
        .padding(9)
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

// Control Button with Prolonged Haptic - Ahora con soporte para estado deshabilitado
struct ControlButton: View {
    let title: String
    let icon: String
    let color: Color
    let isProminent: Bool
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    
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
        .buttonStyle(ControlButtonStyle(color: isEnabled ? color : .gray, isProminent: isEnabled && isProminent))
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

// MARK: - Settings View (Integrado: Appearance + Teams + Info)
struct SettingsView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @AppStorage("appearanceMode") private var appearanceMode = 0
    
    // Teams state
    @State private var teamsUsername = ""
    @State private var teamsPassword = ""
    @State private var isTeamsConnected = false
    @State private var teamsStatus = "Offline"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // MARK: Appearance Section
                GlassCard(title: "Appearance", icon: "paintbrush.fill") {
                    VStack(spacing: 16) {
                        Picker("Theme", selection: $appearanceMode) {
                            Label("System", systemImage: "macpro.gen1").tag(0)
                            Label("Light", systemImage: "sun.max.fill").tag(1)
                            Label("Dark", systemImage: "moon.fill").tag(2)
                        }
                        .pickerStyle(.segmented)
                        
                        Divider().opacity(0.5)
                        
                        VStack(spacing: 8) {
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
                
                // MARK: Microsoft Teams Section
                GlassCard(title: "Microsoft Teams", icon: "person.2.fill") {
                    VStack(spacing: 16) {
                        // Connection Status
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(isTeamsConnected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: isTeamsConnected ? "checkmark.shield.fill" : "person.crop.circle.badge.xmark")
                                    .font(.title3)
                                    .foregroundStyle(isTeamsConnected ? .blue : .secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isTeamsConnected ? "Connected" : "Disconnected")
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                Text(isTeamsConnected ? teamsUsername : "Sync your presence status")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isTeamsConnected)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .onChange(of: isTeamsConnected) { _, newValue in
                                    teamsStatus = newValue ? "Available" : "Offline"
                                    BusylightLogger.shared.info("Teams: \(newValue ? "Connected" : "Disconnected")")
                                }
                        }
                        
                        // Login fields when not connected
                        if !isTeamsConnected {
                            Divider().opacity(0.5)
                            
                            VStack(spacing: 10) {
                                GlassTextField(
                                    placeholder: "Email",
                                    text: $teamsUsername,
                                    icon: "envelope.fill"
                                )
                                
                                GlassTextField(
                                    placeholder: "Password",
                                    text: $teamsPassword,
                                    icon: "lock.fill",
                                    isSecure: true
                                )
                            }
                        }
                        
                        // Status selector when connected
                        if isTeamsConnected {
                            Divider().opacity(0.5)
                            
                            Text("Presence Status")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Status grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                TeamsStatusButton(
                                    icon: "checkmark.circle.fill",
                                    title: "Available",
                                    color: .green,
                                    isSelected: teamsStatus == "Available"
                                ) { teamsStatus = "Available" }
                                
                                TeamsStatusButton(
                                    icon: "minus.circle.fill",
                                    title: "Busy",
                                    color: .red,
                                    isSelected: teamsStatus == "Busy"
                                ) { teamsStatus = "Busy" }
                                
                                TeamsStatusButton(
                                    icon: "moon.circle.fill",
                                    title: "DND",
                                    color: .purple,
                                    isSelected: teamsStatus == "Do Not Disturb"
                                ) { teamsStatus = "Do Not Disturb" }
                                
                                TeamsStatusButton(
                                    icon: "clock.circle.fill",
                                    title: "Away",
                                    color: .orange,
                                    isSelected: teamsStatus == "Away"
                                ) { teamsStatus = "Away" }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // MARK: About Section
                GlassCard(title: "About", icon: "info.circle.fill") {
                    HStack(spacing: 16) {
                        // App Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .shadow(color: .orange.opacity(0.4), radius: 8)
                            
                            Image(systemName: "lightbulb.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Busylight")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                            Text("Version 1.0.0 (2026.03.07)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 20)
            }
        }
    }
}

// Teams Status Button (compacto para Settings)
struct TeamsStatusButton: View {
    let icon: String
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color.opacity(0.15) : Color.gray.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? color.opacity(0.4) : .white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
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
