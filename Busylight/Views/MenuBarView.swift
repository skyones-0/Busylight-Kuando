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
    @ObservedObject private var pomodoroManager = PomodoroManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Header con glassmorphism
                GlassHeader(busylight: busylight)
                
                // Pomodoro Card
                GlassPomodoroCard(
                    busylight: busylight,
                    manager: pomodoroManager
                )
                
                // Visibility Card
                GlassVisibilityCard()
                
                // Quick Colors
               // GlassQuickColorsCard(busylight: busylight)
                
                Spacer(minLength: 4)
                
                // Actions - más compactos
                HStack(spacing: 8) {
                    Button {
                        BusylightLogger.shared.info("MenuBar: Abrir ventana principal")
                        NotificationCenter.default.post(name: .openMainWindow, object: nil)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.forward.app")
                                .font(.caption)
                            Text("Open")
                                .font(.system(.caption, design: .rounded).weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.smallGradient(color: .accentColor, prominent: true))
                    
                    Button {
                        BusylightLogger.shared.info("MenuBar: Salir")
                        NSApp.terminate(nil)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "power")
                                .font(.caption)
                            Text("Quit")
                                .font(.system(.caption, design: .rounded).weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.smallGradient(color: .red))
                }
            }
            .padding(10)
        }
        .frame(width: 220, height: 400)
        .background(
            ZStack {
                // Background con blur
                Color(NSColor.controlBackgroundColor).opacity(0.8)
                
                // Gradient blobs sutiles
                GeometryReader { geo in
                    Circle()
                        .fill(Color.purple.opacity(0.08))
                        .blur(radius: 40)
                        .frame(width: 120, height: 120)
                        .offset(x: -20, y: -20)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.06))
                        .blur(radius: 50)
                        .frame(width: 140, height: 140)
                        .offset(x: geo.size.width * 0.4, y: geo.size.height * 0.3)
                }
            }
        )
    }
}

// MARK: - Glass Header
struct GlassHeader: View {
    @ObservedObject var busylight: BusylightManager
    
    var body: some View {
        HStack(spacing: 8) {
            // Connection status indicator
            ZStack {
                Circle()
                    .fill(busylight.isConnected ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Circle()
                    .fill(busylight.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .shadow(color: (busylight.isConnected ? Color.green : Color.red).opacity(0.6), radius: 3)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(busylight.isConnected ? "Connected" : "Disconnected")
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                
                Text(busylight.deviceName)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            Spacer()
            
            // Current color
            Circle()
                .fill(busylight.color)
                .frame(width: 14, height: 14)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: busylight.color.opacity(0.4), radius: 3)
        }
        .padding(8)
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

// MARK: - Glass Pomodoro Card
struct GlassPomodoroCard: View {
    @ObservedObject var busylight: BusylightManager
    @ObservedObject var manager: PomodoroManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: manager.currentPhase.icon)
                    .font(.caption2)
                    .foregroundStyle(manager.currentPhase.color)
                Text("Focus")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                Spacer()
                
                // Phase badge
                GlassStatusBadge(
                    text: manager.currentPhase.rawValue,
                    isActive: manager.isRunning,
                    icon: manager.currentPhase.icon
                )
                .font(.system(.caption2, design: .rounded))
            }
            
            // Timer display
            HStack {
                Text(manager.timeString)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(manager.isRunning ? manager.currentPhase.color : .primary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 0) {
                    Text(manager.currentPhase.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(manager.currentPhase.color)
                    Text("Set \(manager.currentSet)/\(manager.totalSets)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress bar glass
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Material.thinMaterial)
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
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
                        .frame(width: geo.size.width * manager.progress, height: 4)
                        .shadow(color: manager.currentPhase.color.opacity(0.4), radius: 2)
                        .animation(.linear(duration: 0.5), value: manager.progress)
                }
            }
            .frame(height: 4)
            
            // Control buttons - más compactos
            HStack(spacing: 6) {
                Button {
                    manager.start()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "play.fill")
                            .font(.caption2)
                       // Text(manager.isPaused ? "Resume" : "Start")
                            .font(.system(.caption2, design: .rounded).weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.smallGradient(color: .green, prominent: true))
                .disabled(manager.isRunning && !manager.isPaused)
                .opacity(manager.isRunning && !manager.isPaused ? 0.5 : 1)
                
                Button {
                    manager.pause()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "pause.fill")
                            .font(.caption2)
                       // Text("Pause")
                            .font(.system(.caption2, design: .rounded).weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.smallGradient)
                .disabled(!manager.isRunning || manager.isPaused)
                .opacity(!manager.isRunning || manager.isPaused ? 0.5 : 1)
                
                Button {
                    manager.stop()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "stop.fill")
                            .font(.caption2)
                        //Text("Stop")
                            .font(.system(.caption2, design: .rounded).weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.smallGradient(color: .red))
            }
            
            // Config badges - más pequeños
            HStack(spacing: 4) {
                GlassConfigBadge(icon: "briefcase.fill", value: manager.workTimeMinutes, color: .green)
                GlassConfigBadge(icon: "cup.and.saucer.fill", value: manager.shortBreakMinutes, color: .blue)
                GlassConfigBadge(icon: "sun.max.fill", value: manager.longBreakMinutes, color: .orange)
            }
        }
        .padding(10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Material.thinMaterial)
                
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                
                // Top highlight
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.1), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        )
    }
}

struct GlassConfigBadge: View {
    let icon: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 7))
                .foregroundStyle(color)
            Text("\(value)m")
                .font(.system(.caption2, design: .rounded).weight(.medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Material.thinMaterial)
                
                RoundedRectangle(cornerRadius: 3)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            }
        )
    }
}

// MARK: - Glass Visibility Card
struct GlassVisibilityCard: View {
    @EnvironmentObject var appDelegate: AppDelegate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "eye.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
                Text("Visibility")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
            }
            
            VStack(spacing: 4) {
                GlassToggleRowMini(
                    icon: "dock.rectangle",
                    title: "Dock",
                    isOn: $appDelegate.showInDock
                )
                
                GlassToggleRowMini(
                    icon: "menubar.rectangle",
                    title: "Menu Bar",
                    isOn: $appDelegate.showInMenuBar
                )
            }
        }
        .padding(8)
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

struct GlassToggleRowMini: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 14)
            
            Text(title)
                .font(.system(.caption2, design: .rounded))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .scaleEffect(0.7)
        }
    }
}

// MARK: - Glass Quick Colors Card
struct GlassQuickColorButton: View {
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Glow
                Circle()
                    .fill(color)
                    .blur(radius: isHovered ? 4 : 0)
                    .opacity(isHovered ? 0.5 : 0)
                    .frame(width: 22, height: 22)
                
                // Main circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.9), color],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 12
                        )
                    )
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: color.opacity(0.5), radius: isHovered ? 4 : 2, x: 0, y: 1)
            }
            .scaleEffect(isHovered ? 1.1 : 1)
        }
        .buttonStyle(.plain)
        .frame(height: 26)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
