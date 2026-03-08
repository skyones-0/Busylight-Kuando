//
//  ContentView.swift
//  Busylight
//
//  Created by Jose Araujo on 20/02/26.
//

import SwiftUI
import EventKit

enum SidebarItem: String, CaseIterable, Identifiable {
    case pomodoro = "Pomodoro"
    case deepWork = "Deep Work"
    case workProfiles = "Profiles"
    case teams = "Teams"
    case dashboard = "Dashboard"
    case configuration = "Settings"
    case device = "Device"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .pomodoro: return "timer"
        case .deepWork: return "flame.fill"
        case .workProfiles: return "briefcase.fill"
        case .teams: return "person.2.fill"
        case .dashboard: return "chart.bar.fill"
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
                // Background (versión segura sin GeometryReader)
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
                Color(NSColor.windowBackgroundColor)
                
                ScrollView {
                    switch selectedItem {
                    case .pomodoro:
                        PomodoroView(busylight: busylight)
                    case .deepWork:
                        DeepWorkView()
                    case .workProfiles:
                        WorkProfilesView()
                    case .teams:
                        TeamsView()
                    case .dashboard:
                        DashboardView()
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
    @ObservedObject private var smartFeatures = SmartFeaturesManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Deep Work Active Banner
            if smartFeatures.isDeepWorkActive {
                HStack(spacing: 12) {
                    Image(systemName: "flame.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Deep Work Mode Active")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                        Text("Pomodoro is paused. Deep Work: \(smartFeatures.deepWorkRemainingMinutes) min left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("End Deep Work") {
                        smartFeatures.endDeepWorkMode()
                    }
                    .buttonStyle(.smallGradient(color: .orange))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
            }
            
            // Elegant Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.title3)
                        .foregroundStyle(smartFeatures.isDeepWorkActive ? .gray : manager.currentPhase.color)
                    
                    Text(NSLocalizedString("Focus Session", comment: "Pomodoro session title"))
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(smartFeatures.isDeepWorkActive ? .gray : .primary)
                }
                
                Spacer()
                
                // Elegant Phase Pill con efectos visuales
                PhaseLabel(
                    text: manager.currentPhase.rawValue,
                    color: smartFeatures.isDeepWorkActive ? .gray : manager.currentPhase.color,
                    isRunning: manager.isRunning && !smartFeatures.isDeepWorkActive
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
                    title: smartFeatures.isDeepWorkActive 
                        ? NSLocalizedString("Deep Work Active", comment: "Deep work active button") 
                        : (manager.isPaused ? NSLocalizedString("Resume", comment: "Resume button") : NSLocalizedString("Start", comment: "Start button")),
                    icon: smartFeatures.isDeepWorkActive ? "flame.fill" : "play.fill",
                    color: smartFeatures.isDeepWorkActive ? .orange : .green,
                    isProminent: true,
                    action: { manager.start() }
                )
                .disabled(manager.isRunning && !manager.isPaused || smartFeatures.isDeepWorkActive)
                .opacity(smartFeatures.isDeepWorkActive ? 0.5 : 1)
                
                ControlButton(
                    title: NSLocalizedString("Pause", comment: "Pause button"),
                    icon: "pause.fill",
                    color: .orange,
                    isProminent: false,
                    action: { manager.pause() }
                )
                .disabled(!manager.isRunning || manager.isPaused || smartFeatures.isDeepWorkActive)
                .opacity(smartFeatures.isDeepWorkActive ? 0.3 : 1)
                
                ControlButton(
                    title: NSLocalizedString("Stop", comment: "Stop button"),
                    icon: "stop.fill",
                    color: .red,
                    isProminent: false,
                    action: { manager.stop() }
                )
                .disabled((!manager.isRunning && !manager.isPaused) || smartFeatures.isDeepWorkActive)
                .opacity(smartFeatures.isDeepWorkActive ? 0.3 : 1)
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

// MARK: - Settings View (Super App - All 15 Features)
struct SettingsView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @StateObject private var smartFeatures = SmartFeaturesManager.shared
    @StateObject private var webhookServer = WebhookServer.shared
    
    @AppStorage("appearanceMode") private var appearanceMode = 0
    
    // Teams state
    @State private var teamsUsername = ""
    @State private var teamsPassword = ""
    @State private var isTeamsConnected = false
    @State private var teamsStatus = "Offline"
    
    // Computed properties
    var calendarStatusText: String {
        if !smartFeatures.calendarAccessGranted {
            return "No access"
        }
        switch smartFeatures.calendarStatus {
        case .inMeeting(let title):
            return "In meeting: \(title.prefix(20))"
        case .preparing(let title):
            return "Soon: \(title.prefix(20))"
        case .available:
            return "Available"
        case .none:
            return "No events"
        }
    }
    
    var calendarStatusColor: Color {
        switch smartFeatures.calendarStatus {
        case .inMeeting: return .red
        case .preparing: return .yellow
        case .available: return .green
        case .none: return .gray
        }
    }
    
    var selectedCalendarName: String {
        if smartFeatures.selectedCalendarIdentifier.isEmpty {
            return "All"
        }
        return smartFeatures.availableCalendars.first { $0.calendarIdentifier == smartFeatures.selectedCalendarIdentifier }?.title ?? "Unknown"
    }
    
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
                        
                        Divider().opacity(0.5)
                        
                        // 14. Light Themes
                        Text("Light Theme")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(LightTheme.allCases, id: \.self) { theme in
                                    ThemeButton(
                                        theme: theme,
                                        isSelected: smartFeatures.currentTheme == theme
                                    ) {
                                        smartFeatures.setTheme(theme)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // MARK: Smart Features - Compact Layout
                GlassCard(title: "Smart Features", icon: "sparkles") {
                    VStack(spacing: 16) {
                        
                        // 1. Calendar Sync - Compact Inline
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("Calendar Sync")
                                        .font(.system(.body, design: .rounded))
                                    Spacer()
                                    Toggle("", isOn: $smartFeatures.calendarSyncEnabled)
                                        .toggleStyle(.switch)
                                        .controlSize(.small)
                                }
                                
                                // Inline calendar selector
                                if smartFeatures.calendarSyncEnabled {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(calendarStatusColor)
                                            .frame(width: 8, height: 8)
                                        Text(calendarStatusText)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        
                                        if smartFeatures.calendarAccessGranted && !smartFeatures.availableCalendars.isEmpty {
                                            Text("•")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Menu {
                                                Button("All Calendars") {
                                                    smartFeatures.selectedCalendarIdentifier = ""
                                                }
                                                ForEach(smartFeatures.availableCalendars, id: \.calendarIdentifier) { calendar in
                                                    Button(calendar.title) {
                                                        smartFeatures.selectedCalendarIdentifier = calendar.calendarIdentifier
                                                    }
                                                }
                                            } label: {
                                                HStack(spacing: 2) {
                                                    Text(selectedCalendarName)
                                                        .font(.caption2)
                                                    Image(systemName: "chevron.down")
                                                        .font(.caption2)
                                                }
                                                .foregroundStyle(.blue)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Divider().opacity(0.3)
                        
                        // 2. Work Hours - Compact Stepper Style
                        HStack(spacing: 12) {
                            Image(systemName: "clock.badge.checkmark")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Work Hours")
                                        .font(.system(.body, design: .rounded))
                                    Spacer()
                                    Toggle("", isOn: $smartFeatures.workHoursEnabled)
                                        .toggleStyle(.switch)
                                        .controlSize(.small)
                                }
                                
                                if smartFeatures.workHoursEnabled {
                                    HStack(spacing: 16) {
                                        // Start time stepper
                                        HStack(spacing: 4) {
                                            Button {
                                                if smartFeatures.workStartTime > 0 { smartFeatures.workStartTime -= 1 }
                                            } label: {
                                                Image(systemName: "minus")
                                                    .font(.caption)
                                                    .frame(width: 20, height: 20)
                                                    .background(Color.gray.opacity(0.2))
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(.plain)
                                            
                                            Text("\(smartFeatures.workStartTime):00")
                                                .font(.system(.caption, design: .rounded).weight(.medium))
                                                .frame(width: 40)
                                            
                                            Button {
                                                if smartFeatures.workStartTime < smartFeatures.workEndTime - 1 { smartFeatures.workStartTime += 1 }
                                            } label: {
                                                Image(systemName: "plus")
                                                    .font(.caption)
                                                    .frame(width: 20, height: 20)
                                                    .background(Color.gray.opacity(0.2))
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        
                                        Text("to")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        // End time stepper
                                        HStack(spacing: 4) {
                                            Button {
                                                if smartFeatures.workEndTime > smartFeatures.workStartTime + 1 { smartFeatures.workEndTime -= 1 }
                                            } label: {
                                                Image(systemName: "minus")
                                                    .font(.caption)
                                                    .frame(width: 20, height: 20)
                                                    .background(Color.gray.opacity(0.2))
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(.plain)
                                            
                                            Text("\(smartFeatures.workEndTime):00")
                                                .font(.system(.caption, design: .rounded).weight(.medium))
                                                .frame(width: 40)
                                            
                                            Button {
                                                if smartFeatures.workEndTime < 23 { smartFeatures.workEndTime += 1 }
                                            } label: {
                                                Image(systemName: "plus")
                                                    .font(.caption)
                                                    .frame(width: 20, height: 20)
                                                    .background(Color.gray.opacity(0.2))
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Divider().opacity(0.3)
                        
                        // 3. Other features in compact row
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            CompactToggle(icon: "moon.fill", title: "Focus Mode", isOn: $smartFeatures.focusModeSyncEnabled)
                            CompactToggle(icon: "eye.fill", title: "20-20-20 Breaks", isOn: $smartFeatures.visualBreakEnabled)
                            CompactToggle(icon: "video.fill", title: "Video Calls", isOn: $smartFeatures.zoomDetectionEnabled)
                            CompactToggle(icon: "rectangle.inset.filled", title: "Presentations", isOn: $smartFeatures.presentationModeEnabled)
                        }
                        
                        Divider().opacity(0.3)
                        
                        // 4. Idle Detection
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill.questionmark")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("Idle Detection")
                                        .font(.system(.body, design: .rounded))
                                    Spacer()
                                    Toggle("", isOn: $smartFeatures.idleDetectionEnabled)
                                        .toggleStyle(.switch)
                                        .controlSize(.small)
                                }
                                Text("Pauses timer after \(smartFeatures.idleTimeoutMinutes) min")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // MARK: 6. Deep Work Mode
                GlassCard(title: "Deep Work", icon: "brain.head.profile") {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Deep Work Session")
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                Text("Block distractions for focused work")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        
                        // Pomodoro paused warning
                        if PomodoroManager.shared.isRunning || PomodoroManager.shared.isPaused {
                            HStack(spacing: 8) {
                                Image(systemName: "pause.circle.fill")
                                    .foregroundStyle(.orange)
                                Text("Pomodoro will be paused when Deep Work starts")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if smartFeatures.isDeepWorkActive {
                            VStack(spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "flame.fill")
                                        .font(.title2)
                                        .foregroundStyle(.orange)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Deep Work Active")
                                            .font(.system(.callout, design: .rounded).weight(.semibold))
                                        Text("\(smartFeatures.deepWorkRemainingMinutes) min remaining")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button("End") {
                                        smartFeatures.endDeepWorkMode()
                                    }
                                    .buttonStyle(.smallGradient(color: .red))
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.orange.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        } else {
                            HStack(spacing: 8) {
                                DeepWorkButton(minutes: 60) {
                                    smartFeatures.startDeepWorkMode(durationMinutes: 60)
                                }
                                DeepWorkButton(minutes: 90) {
                                    smartFeatures.startDeepWorkMode(durationMinutes: 90)
                                }
                                DeepWorkButton(minutes: 120) {
                                    smartFeatures.startDeepWorkMode(durationMinutes: 120)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // MARK: ML Autoconfiguration
                MLConfigurationCard()
                    .padding(.horizontal, 20)
                
                // MARK: 9. Webhook API
                GlassCard(title: "API & Integrations", icon: "network") {
                    VStack(spacing: 12) {
                        // Status indicator
                        HStack(spacing: 12) {
                            Image(systemName: webhookServer.isRunning ? "server.rack" : "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(webhookServer.isRunning ? .green : .secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Local API Server")
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(webhookServer.isRunning ? Color.green : Color.gray)
                                        .frame(width: 6, height: 6)
                                    Text(webhookServer.isRunning ? "Running on port 8080" : "Stopped")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { webhookServer.serverEnabled },
                                set: { newValue in
                                    webhookServer.serverEnabled = newValue
                                    if newValue {
                                        webhookServer.start()
                                    } else {
                                        webhookServer.stop()
                                    }
                                }
                            ))
                            .toggleStyle(.switch)
                            .controlSize(.small)
                        }
                        
                        if webhookServer.isRunning {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Endpoint:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("http://localhost:8080/status")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Requests handled:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(webhookServer.requestCount)")
                                        .font(.system(.caption, design: .rounded).weight(.medium))
                                    Spacer()
                                }
                                
                                Divider().opacity(0.3)
                                
                                Text("Available endpoints: GET /status, POST /color, POST /status, POST /timer/{start|pause|stop}")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .background(Color.green.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // MARK: Microsoft Teams Section
                GlassCard(title: "Microsoft Teams", icon: "person.2.fill") {
                    VStack(spacing: 16) {
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
                        
                        if isTeamsConnected {
                            Divider().opacity(0.5)
                            
                            Text("Presence Status")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
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

// MARK: - Deep Work View (Nuevo)
struct DeepWorkView: View {
    @ObservedObject private var smartFeatures = SmartFeaturesManager.shared
    @ObservedObject private var pomodoroManager = PomodoroManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Deep Work")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Status Card
                GlassCard(title: "Session Status", icon: "brain.head.profile") {
                    VStack(spacing: 16) {
                        if smartFeatures.isDeepWorkActive {
                            // Active session
                            VStack(spacing: 12) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.orange)
                                
                                Text("Deep Work Active")
                                    .font(.system(.title2, design: .rounded).weight(.bold))
                                
                                Text("\(smartFeatures.deepWorkRemainingMinutes) minutes remaining")
                                    .font(.system(.title3, design: .rounded))
                                    .foregroundStyle(.secondary)
                                
                                ProgressView(value: Double(smartFeatures.deepWorkRemainingMinutes), total: 90)
                                    .progressViewStyle(.linear)
                                    .tint(.orange)
                                    .padding(.horizontal, 40)
                                
                                Button("End Session") {
                                    smartFeatures.endDeepWorkMode()
                                }
                                .buttonStyle(.gradientWave(color: .red, prominent: true))
                                .padding(.horizontal, 60)
                                .padding(.top, 10)
                            }
                            .padding(.vertical, 20)
                        } else {
                            // No active session
                            VStack(spacing: 12) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.secondary)
                                
                                Text("Ready to Focus")
                                    .font(.system(.title2, design: .rounded).weight(.bold))
                                
                                Text("Choose a duration for your deep work session. Pomodoro will be paused automatically.")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                
                                if pomodoroManager.isRunning {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.orange)
                                        Text("Pomodoro is running and will be paused")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                    .padding(8)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                HStack(spacing: 16) {
                                    DeepWorkSessionButton(minutes: 60, color: .blue) {
                                        smartFeatures.startDeepWorkMode(durationMinutes: 60)
                                    }
                                    DeepWorkSessionButton(minutes: 90, color: .orange) {
                                        smartFeatures.startDeepWorkMode(durationMinutes: 90)
                                    }
                                    DeepWorkSessionButton(minutes: 120, color: .purple) {
                                        smartFeatures.startDeepWorkMode(durationMinutes: 120)
                                    }
                                }
                                .padding(.top, 10)
                            }
                            .padding(.vertical, 20)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Info Card
                GlassCard(title: "About Deep Work", icon: "info.circle.fill") {
                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(icon: "checkmark.circle", text: "Blocks notifications and distractions")
                        InfoRow(icon: "checkmark.circle", text: "Pauses Pomodoro timer automatically")
                        InfoRow(icon: "checkmark.circle", text: "Sets light to red (busy status)")
                        InfoRow(icon: "checkmark.circle", text: "Helps maintain flow state")
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 20)
            }
        }
    }
}

struct DeepWorkSessionButton: View {
    let minutes: Int
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(minutes)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text("min")
                    .font(.caption)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.4), lineWidth: 2)
                    )
            )
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.green)
            Text(text)
                .font(.callout)
            Spacer()
        }
    }
}

// MARK: - Work Profiles View (Nuevo)
struct WorkProfilesView: View {
    @ObservedObject private var smartFeatures = SmartFeaturesManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Work Profiles")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Current Profile
                GlassCard(title: "Current Profile", icon: "briefcase.fill") {
                    HStack(spacing: 16) {
                        Image(systemName: smartFeatures.currentWorkProfile.icon)
                            .font(.system(size: 40))
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(smartFeatures.currentWorkProfile.displayName)
                                .font(.system(.title2, design: .rounded).weight(.bold))
                            Text(profileDescription)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                .padding(.horizontal, 20)
                
                // Profile Selection
                GlassCard(title: "Select Profile", icon: "arrow.swap") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(WorkProfile.allCases, id: \.self) { profile in
                            ProfileSelectionCard(
                                profile: profile,
                                isSelected: smartFeatures.currentWorkProfile == profile
                            ) {
                                smartFeatures.setWorkProfile(profile)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 20)
            }
        }
    }
    
    var profileDescription: String {
        switch smartFeatures.currentWorkProfile {
        case .standard:
            return "25 min work / 5 min break (Classic Pomodoro)"
        case .coding:
            return "50 min work / 10 min break (Extended focus)"
        case .meetings:
            return "Calendar sync enabled for meeting detection"
        case .deepWork:
            return "90 min work / 15 min break (Deep focus)"
        case .learning:
            return "25 min work / 5 min break (Study mode)"
        }
    }
}

struct ProfileSelectionCard: View {
    let profile: WorkProfile
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: profile.icon)
                    .font(.system(size: 32))
                
                Text(profile.displayName)
                    .font(.system(.callout, design: .rounded).weight(.semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
            .foregroundStyle(isSelected ? .blue : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Teams View (Nuevo)
struct TeamsView: View {
    @State private var selectedTab = 0
    @State private var username = ""
    @State private var password = ""
    @State private var isConnected = false
    @State private var status = "Offline"
    @State private var todayActivities = [
        "9:00 AM - Standup meeting",
        "10:30 AM - Project review",
        "2:00 PM - Client call"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Microsoft Teams")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Connection Status Card
                GlassCard(title: "Connection", icon: "person.2.fill") {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(isConnected ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: isConnected ? "checkmark.shield.fill" : "person.crop.circle.badge.xmark")
                                .font(.title2)
                                .foregroundStyle(isConnected ? .green : .secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isConnected ? "Connected" : "Disconnected")
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                            Text(isConnected ? username : "Sync your Teams status")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isConnected)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 20)
                
                // Tab Selector
                Picker("View", selection: $selectedTab) {
                    Text("Status").tag(0)
                    Text("Credentials").tag(1)
                    Text("Activities").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                
                // Tab Content
                Group {
                    switch selectedTab {
                    case 0:
                        StatusTab(status: $status, isConnected: isConnected)
                    case 1:
                        CredentialsTab(username: $username, password: $password, isConnected: isConnected)
                    case 2:
                        ActivitiesTab(activities: todayActivities)
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 20)
            }
        }
    }
}

struct StatusTab: View {
    @Binding var status: String
    let isConnected: Bool
    
    let statuses = [
        ("Available", "checkmark.circle.fill", Color.green),
        ("Busy", "minus.circle.fill", Color.red),
        ("Do Not Disturb", "moon.circle.fill", Color.purple),
        ("Away", "clock.circle.fill", Color.orange)
    ]
    
    var body: some View {
        GlassCard(title: "Presence Status", icon: "person.circle") {
            if isConnected {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(statuses, id: \.0) { item in
                        TeamsStatusButton(
                            icon: item.1,
                            title: item.0,
                            color: item.2,
                            isSelected: status == item.0
                        ) {
                            status = item.0
                        }
                    }
                }
                .padding(.vertical, 8)
            } else {
                HStack {
                    Spacer()
                    Text("Connect to Teams to set status")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 20)
            }
        }
    }
}

struct CredentialsTab: View {
    @Binding var username: String
    @Binding var password: String
    let isConnected: Bool
    
    var body: some View {
        GlassCard(title: "Account", icon: "key.fill") {
            if !isConnected {
                VStack(spacing: 12) {
                    GlassTextField(placeholder: "Email", text: $username, icon: "envelope.fill")
                    GlassTextField(placeholder: "Password", text: $password, icon: "lock.fill", isSecure: true)
                }
                .padding(.vertical, 8)
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text("Connected as \(username)")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            }
        }
    }
}

struct ActivitiesTab: View {
    let activities: [String]
    
    var body: some View {
        GlassCard(title: "Today's Activities", icon: "calendar.day.timeline.left") {
            if activities.isEmpty {
                HStack {
                    Spacer()
                    Text("No activities scheduled")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(activities, id: \.self) { activity in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.blue.opacity(0.5))
                                .frame(width: 8, height: 8)
                            Text(activity)
                                .font(.callout)
                            Spacer()
                        }
                    }
                }
                .padding(.vertical, 8)
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
    var subtitle: String? = nil
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: subtitle != nil ? 2 : 0) {
                Text(title)
                    .font(.system(.body, design: .rounded))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
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

// MARK: - Profile Button
struct ProfileButton: View {
    let profile: WorkProfile
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: profile.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : .secondary)
                
                Text(profile.displayName)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.accentColor.opacity(0.5) : .white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Theme Button
struct ThemeButton: View {
    let theme: LightTheme
    let isSelected: Bool
    let action: () -> Void
    
    var themeColor: Color {
        switch theme {
        case .minimal: return .gray
        case .aurora: return .green
        case .nature: return Color(red: 0.4, green: 0.7, blue: 0.4)
        case .cyber: return .cyan
        case .calm: return Color(red: 0.5, green: 0.6, blue: 0.5)
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle()
                    .fill(themeColor)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? .white : Color.clear, lineWidth: 2)
                    )
                
                Text(theme.displayName)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? themeColor.opacity(0.15) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? themeColor.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Deep Work Button
struct DeepWorkButton: View {
    let minutes: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(minutes)")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text("min")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundStyle(.orange)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @StateObject private var smartFeatures = SmartFeaturesManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Productivity Dashboard")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    DashboardStatCard(
                        title: "Focus Hours",
                        value: String(format: "%.1f", smartFeatures.dashboardData.totalFocusHours),
                        unit: "h",
                        icon: "clock.fill",
                        color: .blue
                    )
                    
                    DashboardStatCard(
                        title: "Pomodoros",
                        value: "\(smartFeatures.dashboardData.pomodorosCompleted)",
                        unit: "",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    DashboardStatCard(
                        title: "Current Streak",
                        value: "\(smartFeatures.dashboardData.currentStreak)",
                        unit: "days",
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    DashboardStatCard(
                        title: "Best Day",
                        value: smartFeatures.dashboardData.bestDay,
                        unit: String(format: "%.1fh", smartFeatures.dashboardData.bestDayHours),
                        icon: "star.fill",
                        color: .purple
                    )
                }
                .padding(.horizontal, 20)
                
                // Weekly Chart (Simplified)
                GlassCard(title: "Last 7 Days", icon: "chart.bar.fill") {
                    HStack(spacing: 8) {
                        ForEach(smartFeatures.dashboardData.weeklyData.prefix(7), id: \.date) { day in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.blue.opacity(0.7))
                                    .frame(width: 20, height: max(4, CGFloat(day.hours) * 10))
                                
                                Text(dayLabel(for: day.date))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 20)
                
                // Tips
                GlassCard(title: "Insights", icon: "lightbulb.fill") {
                    VStack(alignment: .leading, spacing: 8) {
                        InsightRow(
                            icon: "flame.fill",
                            text: "You're on a \(smartFeatures.dashboardData.currentStreak)-day streak! Keep it up!",
                            color: .orange
                        )
                        
                        if smartFeatures.dashboardData.pomodorosCompleted > 20 {
                            InsightRow(
                                icon: "trophy.fill",
                                text: "Over 20 pomodoros this week - outstanding focus!",
                                color: .yellow
                            )
                        }
                        
                        InsightRow(
                            icon: "eye.fill",
                            text: "Remember the 20-20-20 rule for eye health",
                            color: .blue
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 20)
            }
        }
        .onAppear {
            smartFeatures.updateDashboard()
        }
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date).prefix(1).uppercased()
    }
}

struct DashboardStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(color)
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.thinMaterial)
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            }
        )
    }
}

struct InsightRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(color)
            
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Compact Toggle for Settings
struct CompactToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(isOn ? .blue : .secondary)
                .frame(width: 20)
            
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(isOn ? .primary : .secondary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isOn ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isOn ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
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
    var body: some View {
        Circle()
            .fill(Color.green.opacity(0.6))
            .frame(width: 10, height: 10)
    }
}

// Elegant Progress Bar - sin GeometryReader para evitar layout loops
struct ElegantProgressBar: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ProgressView(value: progress)
            .progressViewStyle(LinearProgressViewStyle(tint: color))
            .frame(height: 6)
            .scaleEffect(y: 0.8)
    }
}

// MARK: - ML Configuration Card
struct MLConfigurationCard: View {
    @StateObject private var mlManager = MLScheduleManager.shared
    @State private var showingHolidaySheet = false
    @State private var showingClearConfirmation = false
    @State private var trainingError: String?
    
    private var statusColor: Color {
        if mlManager.isTraining { return .orange }
        if !mlManager.isModelTrained {
            return mlManager.canTrainModel() ? .yellow : .gray
        }
        return mlManager.modelAccuracy > 0.8 ? .green : .orange
    }
    
    private var statusText: String {
        if mlManager.isTraining { return "Training model..." }
        if mlManager.isModelTrained {
            return "Model trained (\(String(format: "%.0f%%", mlManager.modelAccuracy * 100)) accuracy)"
        }
        if mlManager.canTrainModel() {
            return "Ready to train - \(mlManager.trainingDaysCollected) days collected"
        }
        return "Collecting data - \(mlManager.trainingDaysCollected)/\(mlManager.configuration?.minTrainingDays ?? 14) days"
    }
    
    var body: some View {
        GlassCard(title: "ML Autoconfiguration", icon: "brain") {
            VStack(spacing: 16) {
                // Header con toggle principal
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(mlManager.isModelTrained ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: mlManager.isModelTrained ? "checkmark.seal.fill" : "brain.head.profile")
                            .font(.title3)
                            .foregroundStyle(mlManager.isModelTrained ? .green : .orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Smart Schedule Learning")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                        Text(mlManager.configuration?.isMLEnabled == true ? "Learning your patterns" : "Enable to auto-configure work hours")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { mlManager.configuration?.isMLEnabled ?? false },
                        set: { mlManager.updateConfiguration(isEnabled: $0) }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
                
                if mlManager.configuration?.isMLEnabled == true {
                    Divider().opacity(0.3)
                    
                    // Estadísticas de entrenamiento
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Training Data")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(mlManager.trainingDaysCollected) days")
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                        
                        // Barra de progreso (sin GeometryReader para evitar layout loop)
                        MLProgressBar(
                            daysCollected: mlManager.trainingDaysCollected,
                            minDays: mlManager.configuration?.minTrainingDays ?? 14
                        )
                        
                        if mlManager.isModelTrained {
                            HStack {
                                Text("Model Accuracy")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.0f%%", mlManager.modelAccuracy * 100))
                                    .font(.caption)
                                    .foregroundStyle(mlManager.modelAccuracy > 0.8 ? .green : .orange)
                            }
                        }
                    }
                    
                    // Botones de acción
                    HStack(spacing: 10) {
                        // Botón Entrenar
                        Button(action: {
                            Task {
                                do {
                                    try await mlManager.trainModel()
                                } catch {
                                    trainingError = error.localizedDescription
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                if mlManager.isTraining {
                                    ProgressView()
                                        .controlSize(.small)
                                        .scaleEffect(0.6)
                                } else {
                                    Image(systemName: "play.fill")
                                        .font(.caption)
                                }
                                Text(mlManager.isModelTrained ? "Retrain" : "Train Now")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.blue)
                        .disabled(!mlManager.canTrainModel() || mlManager.isTraining)
                        
                        // Botón Calendario Festivos
                        Button(action: { showingHolidaySheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.caption)
                                Text("Holidays")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Spacer()
                        
                        // Botón Limpiar
                        Button(action: { showingClearConfirmation = true }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Auto-training toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-train model")
                                .font(.caption)
                            Text("Trains automatically when enough data is collected")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { mlManager.configuration?.autoTrainingEnabled ?? true },
                            set: { mlManager.updateConfiguration(autoTraining: $0) }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                    }
                    
                    // Auto-adjust toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-apply predictions")
                                .font(.caption)
                            Text("Adjusts work hours based on predictions")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { mlManager.configuration?.autoAdjustSchedule ?? false },
                            set: { mlManager.updateConfiguration(autoAdjust: $0) }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                    }
                    
                    // Estado del sistema
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 6, height: 6)
                            Text(statusText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        
                        // Predicción actual o próxima
                        if let prediction = mlManager.lastPrediction {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.purple)
                                Text("Tomorrow: \(prediction.formattedStartTime) - \(prediction.formattedEndTime)")
                                    .font(.caption)
                                Spacer()
                            }
                            .padding(8)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                        } else if mlManager.isModelTrained {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(.green)
                                Text("Model ready - waiting for tomorrow's prediction")
                                    .font(.caption)
                                Spacer()
                            }
                            .padding(8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    if let error = trainingError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showingHolidaySheet) {
            HolidayCalendarView()
        }
        .alert("Clear all training data?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                mlManager.clearAllData()
            }
        } message: {
            Text("This will delete all collected work patterns and reset the ML model.")
        }
    }
}

// MARK: - Holiday Calendar View
struct HolidayCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mlManager = MLScheduleManager.shared
    @State private var newCalendarName = ""
    @State private var selectedDates: [Date] = []
    @State private var showingDatePicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Holiday Calendars")
                    .font(.title2.bold())
                Spacer()
                Button("Close") { dismiss() }
            }
            .padding(.horizontal)
            .padding(.top)
            
            List {
                Section("Add Holiday Calendar") {
                    TextField("Calendar Name", text: $newCalendarName)
                    
                    Button("Select Dates (\(selectedDates.count) selected)") {
                        showingDatePicker = true
                    }
                    
                    Button("Create Calendar") {
                        if !newCalendarName.isEmpty && !selectedDates.isEmpty {
                            mlManager.createHolidayCalendar(
                                name: newCalendarName,
                                countryCode: "custom",
                                dates: selectedDates
                            )
                            newCalendarName = ""
                            selectedDates = []
                        }
                    }
                    .disabled(newCalendarName.isEmpty || selectedDates.isEmpty)
                }
                
                Section("Active Calendars") {
                    ForEach(mlManager.getHolidayCalendars()) { calendar in
                        HStack {
                            Text(calendar.name)
                            Spacer()
                            if calendar.isEnabled {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        let calendars = mlManager.getHolidayCalendars()
                        for index in indexSet {
                            mlManager.deleteHolidayCalendar(calendars[index])
                        }
                    }
                }
                
                Section {
                    Text("Holidays are excluded from ML training.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 400, height: 500)
        .sheet(isPresented: $showingDatePicker) {
            MultiDatePicker(selectedDates: $selectedDates)
        }
    }
}

// MARK: - ML Progress Bar (sin GeometryReader)
struct MLProgressBar: View {
    let daysCollected: Int
    let minDays: Int
    
    private var progress: Double {
        min(1.0, Double(daysCollected) / Double(minDays))
    }
    
    var body: some View {
        ProgressView(value: progress)
            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            .frame(height: 6)
            .scaleEffect(y: 0.8)
    }
}

// MARK: - Multi Date Picker
struct MultiDatePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDates: [Date]
    @State private var currentSelection = Date()
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Select Dates")
                    .font(.title2.bold())
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding(.horizontal)
            .padding(.top)
            
            DatePicker(
                "Select Date",
                selection: $currentSelection,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            
            Button("Add Date") {
                if !selectedDates.contains(currentSelection) {
                    selectedDates.append(currentSelection)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            
            List {
                Section("Selected Dates") {
                    ForEach(selectedDates.sorted(), id: \.self) { date in
                        HStack {
                            Text(date, style: .date)
                            Spacer()
                            Button(action: {
                                selectedDates.removeAll { $0 == date }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppDelegate())
    }
}
