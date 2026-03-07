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
            VStack(alignment: .leading, spacing: 14) {
                // Header con glassmorphism
                GlassHeader(busylight: busylight)
                
                // Pomodoro Card
                GlassPomodoroCard(
                    busylight: busylight,
                    workTime: workTime,
                    sets: sets
                )
                
                // Visibility Card
                GlassVisibilityCard()
                
                // Quick Colors
                GlassQuickColorsCard(busylight: busylight)
                
                Spacer(minLength: 8)
                
                // Actions
                VStack(spacing: 8) {
                    Button {
                        BusylightLogger.shared.info("MenuBar: Abrir ventana principal")
                        NotificationCenter.default.post(name: .openMainWindow, object: nil)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.forward.app")
                            Text("Open Main Window")
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.glass(color: .accentColor, prominent: true))
                    
                    Button {
                        BusylightLogger.shared.info("MenuBar: Salir")
                        NSApp.terminate(nil)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "power")
                            Text("Quit")
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.glass(color: .red))
                }
            }
            .padding(14)
        }
        .frame(width: 260, height: 480)
        .background(
            ZStack {
                // Background con blur
                Color(NSColor.controlBackgroundColor).opacity(0.8)
                
                // Gradient blobs sutiles
                GeometryReader { geo in
                    Circle()
                        .fill(Color.purple.opacity(0.08))
                        .blur(radius: 40)
                        .frame(width: 150, height: 150)
                        .offset(x: -30, y: -30)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.06))
                        .blur(radius: 50)
                        .frame(width: 180, height: 180)
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
        HStack(spacing: 10) {
            // Connection status indicator
            ZStack {
                Circle()
                    .fill(busylight.isConnected ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Circle()
                    .fill(busylight.isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                    .shadow(color: (busylight.isConnected ? Color.green : Color.red).opacity(0.6), radius: 4)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(busylight.isConnected ? "Connected" : "Disconnected")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                
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
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: busylight.color.opacity(0.4), radius: 4)
        }
        .padding(10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.thinMaterial)
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            }
        )
    }
}

// MARK: - Glass Pomodoro Card
struct GlassPomodoroCard: View {
    @ObservedObject var busylight: BusylightManager
    let workTime: Int
    let sets: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text("Focus Timer")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Spacer()
            }
            
            // Timer display
            HStack {
                Text(String(format: "%02d:00", workTime))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Work")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                    Text("Set 1/\(sets)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress bar glass
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Material.thinMaterial)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.8), .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.3, height: 6)
                        .shadow(color: .green.opacity(0.4), radius: 3)
                }
            }
            .frame(height: 6)
            
            // Control buttons
            HStack(spacing: 8) {
                Button {
                    BusylightLogger.shared.info("MenuBar: Start Pomodoro")
                    busylight.green()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.caption)
                        Text("Start")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.glass(color: .green, prominent: true))
                
                Button {
                    BusylightLogger.shared.info("MenuBar: Pause Pomodoro")
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pause.fill")
                            .font(.caption)
                        Text("Pause")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.glass)
            }
            
            // Config badges
            HStack(spacing: 6) {
                GlassConfigBadge(icon: "briefcase.fill", value: workTime, color: .red)
                GlassConfigBadge(icon: "cup.and.saucer.fill", value: 5, color: .blue)
                GlassConfigBadge(icon: "sun.max.fill", value: 15, color: .orange)
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
                
                // Top highlight
                RoundedRectangle(cornerRadius: 12)
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
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundStyle(color)
            Text("\(value)m")
                .font(.system(.caption2, design: .rounded).weight(.medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Material.thinMaterial)
                
                RoundedRectangle(cornerRadius: 4)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            }
        )
    }
}

// MARK: - Glass Visibility Card
struct GlassVisibilityCard: View {
    @EnvironmentObject var appDelegate: AppDelegate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "eye.fill")
                    .font(.caption)
                    .foregroundStyle(.accent)
                Text("Visibility")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            
            VStack(spacing: 8) {
                GlassToggleRowMini(
                    icon: "dock.rectangle",
                    title: "Show in Dock",
                    isOn: $appDelegate.showInDock
                )
                
                GlassToggleRowMini(
                    icon: "menubar.rectangle",
                    title: "Show in Menu Bar",
                    isOn: $appDelegate.showInMenuBar
                )
            }
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.thinMaterial)
                
                RoundedRectangle(cornerRadius: 12)
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
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            
            Text(title)
                .font(.system(.caption, design: .rounded))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .scaleEffect(0.8)
        }
    }
}

// MARK: - Glass Quick Colors Card
struct GlassQuickColorsCard: View {
    @ObservedObject var busylight: BusylightManager
    
    let colors: [(color: Color, action: () -> Void)] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "paintpalette.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("Quick Colors")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                GlassQuickColorButton(color: .red) {
                    BusylightLogger.shared.info("MenuBar: Red")
                    busylight.red()
                }
                GlassQuickColorButton(color: .green) {
                    BusylightLogger.shared.info("MenuBar: Green")
                    busylight.green()
                }
                GlassQuickColorButton(color: .blue) {
                    BusylightLogger.shared.info("MenuBar: Blue")
                    busylight.blue()
                }
                GlassQuickColorButton(color: .yellow) {
                    BusylightLogger.shared.info("MenuBar: Yellow")
                    busylight.yellow()
                }
                GlassQuickColorButton(color: .purple) {
                    BusylightLogger.shared.info("MenuBar: Purple")
                    busylight.purple()
                }
                GlassQuickColorButton(color: .white) {
                    BusylightLogger.shared.info("MenuBar: White")
                    busylight.white()
                }
            }
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.thinMaterial)
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            }
        )
    }
}

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
                    .blur(radius: isHovered ? 6 : 0)
                    .opacity(isHovered ? 0.5 : 0)
                    .frame(width: 28, height: 28)
                
                // Main circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.9), color],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 15
                        )
                    )
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: color.opacity(0.5), radius: isHovered ? 6 : 2, x: 0, y: 2)
            }
            .scaleEffect(isHovered ? 1.15 : 1)
        }
        .buttonStyle(.plain)
        .frame(height: 32)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
