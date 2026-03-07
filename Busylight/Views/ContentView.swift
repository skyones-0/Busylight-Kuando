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
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .opacity(0.5)
                            .scaleEffect(1.5)
                            .animation(.easeOut(duration: 1).repeatForever(autoreverses: true), value: busylight.isConnected)
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

// MARK: - Pomodoro View (Glassmorphism)
struct PomodoroView: View {
    @ObservedObject var busylight: BusylightManager
    @ObservedObject private var manager = PomodoroManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 4) {
                HStack(spacing: 10) {
                    Image(systemName: "timer")
                        .font(.largeTitle)
                        .foregroundStyle(manager.currentPhase.color)
                    
                    Text("Focus Timer")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                }
                
                Text("Stay productive with timed sessions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Main Timer Display
            GlassCard(title: "Current Session", icon: manager.currentPhase.icon) {
                VStack(spacing: 16) {
                    // Phase and Set Info
                    HStack {
                        GlassStatusBadge(
                            text: manager.currentPhase.rawValue,
                            isActive: manager.isRunning,
                            icon: manager.currentPhase.icon
                        )
                        
                        Spacer()
                        
                        Text("Set \(manager.currentSet)/\(manager.totalSets)")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    // Timer Display
                    Text(manager.timeString)
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(manager.currentPhase.color)
                        .shadow(color: manager.currentPhase.color.opacity(0.3), radius: 10)
                    
                    // Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Material.thinMaterial)
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            manager.currentPhase.color.opacity(0.8),
                                            manager.currentPhase.color
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * manager.progress, height: 8)
                                .shadow(color: manager.currentPhase.color.opacity(0.4), radius: 4)
                                .animation(.linear(duration: 0.5), value: manager.progress)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 20)
            
            // Timer Display Cards (Configuration Preview)
            HStack(spacing: 12) {
                GlassTimerCard(
                    time: String(format: "%02d:00", manager.workTimeMinutes),
                    color: .green,
                    icon: "briefcase.fill"
                )
                
                GlassTimerCard(
                    time: String(format: "%02d:00", manager.shortBreakMinutes),
                    color: .blue,
                    icon: "cup.and.saucer.fill"
                )
                
                GlassTimerCard(
                    time: String(format: "%02d:00", manager.longBreakMinutes),
                    color: .orange,
                    icon: "sun.max.fill"
                )
                
                GlassTimerCard(
                    time: "\(manager.configuredSets)",
                    color: .purple,
                    icon: "arrow.clockwise",
                    isNumber: true
                )
            }
            .padding(.horizontal, 20)
            
            // Configuration
            GlassCard(title: "Configuration", icon: "slider.horizontal.3") {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ConfigLabel(icon: "briefcase.fill", title: "Work")
                        ConfigLabel(icon: "cup.and.saucer.fill", title: "Short")
                        ConfigLabel(icon: "sun.max.fill", title: "Long")
                        ConfigLabel(icon: "number", title: "Sets")
                    }
                    
                    HStack(spacing: 10) {
                        GlassStepper(value: $manager.workTimeMinutes, suffix: "min", range: 1...60)
                            .onChange(of: manager.workTimeMinutes) { manager.updateConfiguration() }
                        GlassStepper(value: $manager.shortBreakMinutes, suffix: "min", range: 1...30)
                            .onChange(of: manager.shortBreakMinutes) { manager.updateConfiguration() }
                        GlassStepper(value: $manager.longBreakMinutes, suffix: "min", range: 1...60)
                            .onChange(of: manager.longBreakMinutes) { manager.updateConfiguration() }
                        GlassStepper(value: $manager.configuredSets, suffix: "", range: 1...10)
                            .onChange(of: manager.configuredSets) { manager.updateConfiguration() }
                    }
                }
            }
            .padding(.horizontal, 20)
            .disabled(manager.isRunning)
            .opacity(manager.isRunning ? 0.6 : 1)
            
            // Control Buttons
            HStack(spacing: 16) {
                Button {
                    manager.start()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: manager.isPaused ? "play.fill" : "play.fill")
                        Text(manager.isPaused ? "Resume" : "Start")
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.waveButton(color: .green, prominent: true))
                .disabled(manager.isRunning && !manager.isPaused)
                .opacity(manager.isRunning && !manager.isPaused ? 0.5 : 1)
                
                Button {
                    manager.pause()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pause.fill")
                        Text("Pause")
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.waveButton)
                .disabled(!manager.isRunning || manager.isPaused)
                .opacity(!manager.isRunning || manager.isPaused ? 0.5 : 1)
                
                Button {
                    manager.stop()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.waveButton(color: .red))
                .disabled(!manager.isRunning && !manager.isPaused)
                .opacity(!manager.isRunning && !manager.isPaused ? 0.5 : 1)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
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
                    .buttonStyle(.glassButton(color: isLoggedIn ? .red : .blue, prominent: !isLoggedIn))
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppDelegate())
    }
}
