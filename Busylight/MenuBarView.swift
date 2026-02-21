//
//  MenuBarView.swift
//  Busylight
//
//  Created by Jose Araujo on 20/02/26.
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @ObservedObject var busylight: BusylightManager
    @AppStorage("pomodoroWorkTime") private var workTime = 25
    @AppStorage("pomodoroShortBreak") private var shortBreak = 5
    @AppStorage("pomodoroLongBreak") private var longBreak = 15
    @AppStorage("pomodoroSets") private var sets = 3
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Circle()
                        .fill(busylight.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(busylight.isConnected ? "Connected" : "Disconnected")
                        .font(.caption)
                    Spacer()
                    Text(busylight.deviceName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // POMODORO
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pomodoro")
                        .font(.headline)
                    
                    HStack {
                        Text(String(format: "%02d:00", workTime))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Work")
                                .font(.caption.bold())
                                .foregroundColor(.red)
                            Text("Set 1/\(sets)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 4)
                                .cornerRadius(2)
                            
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: geo.size.width * 0.3, height: 4)
                                .cornerRadius(2)
                        }
                    }
                    .frame(height: 4)
                    
                    // Buttons
                    HStack(spacing: 8) {
                        Button {
                            BusylightLogger.shared.info("MenuBar: Start Pomodoro")
                        } label: {
                            Label("Start", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .controlSize(.small)
                        
                        Button {
                            BusylightLogger.shared.info("MenuBar: Pause Pomodoro")
                        } label: {
                            Label("Pause", systemImage: "pause.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    // Config badges
                    HStack(spacing: 6) {
                        ConfigBadge(icon: "briefcase.fill", value: workTime, color: .red)
                        ConfigBadge(icon: "cup.and.saucer.fill", value: shortBreak, color: .green)
                        ConfigBadge(icon: "sun.max.fill", value: longBreak, color: .yellow)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Divider()
                
                // Visibility
                VStack(alignment: .leading, spacing: 10) {
                    Text("Visibility")
                        .font(.headline)
                    
                    Toggle("Show in Dock", isOn: $appDelegate.showInDock)
                        .toggleStyle(.checkbox)
                    
                    Toggle("Show in Menu Bar", isOn: $appDelegate.showInMenuBar)
                        .toggleStyle(.checkbox)
                }
                
                Divider()
                
                // Quick Colors
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Colors")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 30))], spacing: 6) {
                        QuickColorButton(color: .red) {
                            BusylightLogger.shared.info("MenuBar: Red")
                            busylight.red()
                        }
                        QuickColorButton(color: .green) {
                            BusylightLogger.shared.info("MenuBar: Green")
                            busylight.green()
                        }
                        QuickColorButton(color: .blue) {
                            BusylightLogger.shared.info("MenuBar: Blue")
                            busylight.blue()
                        }
                        QuickColorButton(color: .yellow) {
                            BusylightLogger.shared.info("MenuBar: Yellow")
                            busylight.yellow()
                        }
                        QuickColorButton(color: .purple) {
                            BusylightLogger.shared.info("MenuBar: Purple")
                            busylight.purple()
                        }
                        QuickColorButton(color: .white) {
                            BusylightLogger.shared.info("MenuBar: White")
                            busylight.white()
                        }
                    }
                }
                
                Spacer(minLength: 12)
                
                // Actions
                Button {
                    BusylightLogger.shared.info("MenuBar: Abrir ventana principal")
                    NotificationCenter.default.post(name: .openMainWindow, object: nil)
                } label: {
                    Label("Open Main Window", systemImage: "arrow.up.forward.app")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    BusylightLogger.shared.info("MenuBar: Salir")
                    NSApp.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                        .frame(maxWidth: .infinity)
                }
                .foregroundColor(.red)
            }
            .padding()
        }
        .frame(width: 240, height: 420)
    }
}

// MARK: - MenuBar Supporting Views
struct ConfigBadge: View {
    let icon: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text("\(value)m")
        }
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
}

struct QuickColorButton: View {
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 26, height: 26)
        }
        .buttonStyle(.borderless)
    }
}
