//
//  ContentView.swift
//  Busylight
//
//  Created by Jose Araujo on 20/02/26.
//

import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case test = "Test"
    case pomodoro = "Pomodoro"
    case teams = "Teams"
    case configuration = "Configuration"
    case about = "About"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .test: return "lightbulb.fill"
        case .pomodoro: return "timer"
        case .teams: return "person.2.fill"
        case .configuration: return "gearshape.fill"
        case .about: return "info.circle.fill"
        }
    }
}

struct ContentView: View {
    @StateObject private var busylight = BusylightManager()
    @EnvironmentObject var appDelegate: AppDelegate
    @State private var selectedItem: SidebarItem = .test
    
    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .navigationTitle("Busylight")
            .frame(minWidth: 140, idealWidth: 150, maxWidth: 180)
        } detail: {
            switch selectedItem {
            case .test:
                TestView(busylight: busylight)
            case .pomodoro:
                PomodoroView(busylight: busylight)
            case .teams:
                TeamsView()
            case .configuration:
                ConfigurationView()
            case .about:
                AboutView(busylight: busylight)
            }
        }
        .frame(minWidth: 650, idealWidth: 750, maxWidth: 900,
               minHeight: 450, idealHeight: 550, maxHeight: 700)
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

// MARK: - Test View
struct TestView: View {
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
        ScrollView {
            VStack(spacing: 16) {
                StatusHeaderView(busylight: busylight)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Colors")
                        .font(.title3.bold())
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 70, maximum: 90), spacing: 8)
                    ], spacing: 8) {
                        ForEach(colors, id: \.name) { item in
                            ColorTestButton(
                                name: item.name,
                                color: item.color,
                                action: {
                                    BusylightLogger.shared.info("TestView: \(item.name) presionado")
                                    item.action()
                                }
                            )
                        }
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Jingles")
                        .font(.title3.bold())
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 45, maximum: 55), spacing: 6)
                    ], spacing: 6) {
                        ForEach(1...16, id: \.self) { number in
                            JingleButton(number: number) {
                                BusylightLogger.shared.info("TestView: Jingle \(number) presionado")
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
                
                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Pomodoro View
struct PomodoroView: View {
    @ObservedObject var busylight: BusylightManager
    @AppStorage("pomodoroWorkTime") private var workTime = 25
    @AppStorage("pomodoroShortBreak") private var shortBreak = 5
    @AppStorage("pomodoroLongBreak") private var longBreak = 15
    @AppStorage("pomodoroSets") private var sets = 3
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("KUANDO TIMER")
                        .font(.title2.bold())
                    Text("Get the most of your time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    Text("Current color:")
                        .font(.subheadline)
                    Circle()
                        .fill(busylight.color)
                        .frame(width: 16, height: 16)
                }
                
                // Config
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ConfigColumnHeader(title: "Work", icon: "briefcase.fill")
                        ConfigColumnHeader(title: "Short", icon: "cup.and.saucer.fill")
                        ConfigColumnHeader(title: "Long", icon: "sun.max.fill")
                        ConfigColumnHeader(title: "Sets", icon: "number")
                    }
                    
                    HStack(spacing: 8) {
                        CompactStepper(value: $workTime, suffix: "min")
                        CompactStepper(value: $shortBreak, suffix: "min")
                        CompactStepper(value: $longBreak, suffix: "min")
                        CompactStepper(value: $sets, suffix: "")
                    }
                }
                
                // Cards
                HStack(spacing: 10) {
                    CompactTimerCard(
                        time: String(format: "%02d:00", workTime),
                        color: .red,
                        icon: "lightbulb.fill"
                    )
                    CompactTimerCard(
                        time: String(format: "%02d:00", shortBreak),
                        color: .green,
                        icon: "cup.and.saucer.fill"
                    )
                    CompactTimerCard(
                        time: String(format: "%02d:00", longBreak),
                        color: .yellow,
                        icon: "sun.max.fill"
                    )
                    CompactTimerCard(
                        time: "\(sets)",
                        color: .black,
                        icon: "arrow.clockwise",
                        isNumber: true
                    )
                }
                
                HStack(spacing: 12) {
                    Button {
                        BusylightLogger.shared.info("Pomodoro: Start presionado")
                    } label: {
                        Label("Start", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.small)
                    
                    Button {
                        BusylightLogger.shared.info("Pomodoro: Pause presionado")
                    } label: {
                        Label("Pause", systemImage: "pause.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                Spacer()
            }
            .padding(20)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Teams View
struct TeamsView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isLoggedIn = false
    @State private var microsoftStatus = "Disconnected"
    @State private var teamsStatus = "Offline"
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                
                Text("Microsoft Teams")
                    .font(.title2.bold())
                
                Text("Sync presence status")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Account")
                        .font(.headline)
                    
                    TextField("Email", text: $username)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                    
                    Button {
                        BusylightLogger.shared.info("Teams: Login presionado")
                        isLoggedIn.toggle()
                        microsoftStatus = isLoggedIn ? "Connected" : "Disconnected"
                        teamsStatus = isLoggedIn ? "Available" : "Offline"
                    } label: {
                        Label(isLoggedIn ? "Disconnect" : "Login",
                              systemImage: isLoggedIn ? "xmark.circle" : "arrow.right.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(12)
            }
            .frame(width: 280)
            
            if isLoggedIn {
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Microsoft")
                                    .font(.subheadline)
                                Text(microsoftStatus)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            Text("Teams:")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $teamsStatus) {
                                Text("Available").tag("Available")
                                Text("Busy").tag("Busy")
                                Text("DND").tag("Do Not Disturb")
                                Text("Away").tag("Away")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 120)
                        }
                    }
                    .padding(12)
                }
                .frame(width: 280)
                .transition(.opacity)
            }
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Configuration View
struct ConfigurationView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @AppStorage("appearanceMode") private var appearanceMode = 0
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Appearance")
                        .font(.title3.bold())
                    
                    Picker("Theme", selection: $appearanceMode) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                    .onChange(of: appearanceMode) { _, newValue in
                        BusylightLogger.shared.info("Appearance: \(newValue)")
                    }
                    
                    Toggle("Show in Dock", isOn: $appDelegate.showInDock)
                    Toggle("Show in Menu Bar", isOn: $appDelegate.showInMenuBar)
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About View
struct AboutView: View {
    @ObservedObject var busylight: BusylightManager
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text("ABOUT")
                    .font(.title2.bold())
                
                VStack(alignment: .leading, spacing: 4) {
                    InfoRow(label: "Name:", value: "Busylight App")
                    InfoRow(label: "Version:", value: "1.0.0")
                    InfoRow(label: "Copyright:", value: "Sky One, 2026")
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("DEVICE")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: busylight.isConnected ? "lightbulb.fill" : "lightbulb.slash")
                            .foregroundColor(busylight.isConnected ? .green : .gray)
                        Text(busylight.isConnected ? busylight.deviceName : "No device")
                            .font(.callout)
                    }
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(Color(NSColor.controlBackgroundColor))
            
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "lightbulb.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                Text("Control Busylights colors, sound, and sync with Teams presence.")
                    .font(.callout)
                    .lineSpacing(2)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(Color.white.opacity(0.5))
        }
    }
}

// MARK: - Supporting Views
struct StatusHeaderView: View {
    @ObservedObject var busylight: BusylightManager
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(busylight.isConnected ? Color.green : Color.red)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(busylight.isConnected ? "Connected" : "Disconnected")
                    .font(.subheadline.bold())
                Text(busylight.deviceName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(busylight.color)
                .frame(width: 28, height: 28)
        }
        .padding(12)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
    }
}

struct ColorTestButton: View {
    let name: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 36, height: 36)
                Text(name)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
        }
        .buttonStyle(.plain)
        .padding(6)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct JingleButton: View {
    let number: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(.system(.callout, design: .rounded).bold())
                .frame(width: 45, height: 32)
        }
        .buttonStyle(.bordered)
        .tint(.accentColor)
        .controlSize(.small)
    }
}

struct ConfigColumnHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(.secondary)
    }
}

struct CompactStepper: View {
    @Binding var value: Int
    let suffix: String
    
    var body: some View {
        HStack(spacing: 2) {
            Text("\(value)\(suffix.isEmpty ? "" : " \(suffix)")")
                .font(.caption)
            Spacer()
            Stepper("", value: $value, in: 1...99)
                .labelsHidden()
                .controlSize(.small)
        }
        .padding(6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(4)
    }
}

struct CompactTimerCard: View {
    let time: String
    let color: Color
    let icon: String
    var isNumber: Bool = false
    
    var body: some View {
        VStack(spacing: 6) {
            Text(time)
                .font(.system(size: isNumber ? 24 : 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .background(color)
        .cornerRadius(6)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .trailing)
            Text(value)
                .font(.callout)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppDelegate())
    }
}
