//
//  MenuBarView.swift
//  Busylight
//
//  Menu bar popover UI with pomodoro timer, visibility toggles, and quick actions.
//  Supports both popover and detached window modes for fullscreen compatibility.
//
//  Relationships:
//  - Uses: AppDelegate (@EnvironmentObject) for dock/menubar visibility toggles
//  - Uses: PomodoroManager (timer display), SmartFeaturesManager (calendar status)
//  - Triggered by: AppDelegate.toggleMenu() when status item is clicked
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @ObservedObject var busylight: BusylightManager
    @ObservedObject private var pomodoroManager = PomodoroManager.shared
    @ObservedObject private var smartFeatures = SmartFeaturesManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Header con liquid glass
                //LiquidGlassHeader(busylight: busylight)

                // Calendar Activity Card (nuevo)
                if smartFeatures.calendarSyncEnabled {
                    LiquidGlassCalendarCard()
                }

                // Pomodoro Card
                LiquidGlassPomodoroCard(
                    busylight: busylight,
                    manager: pomodoroManager
                )
                
                // Visibility Card
                LiquidGlassVisibilityCard()
                


                // Actions - más compactos, justo después de Visibility
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
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.liquidGlass(color: .blue, prominent: true))
                    
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
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.liquidGlass(color: .red))
                }
            }
            .padding(10)
        }
        .frame(width: 220, height: 400)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Liquid Glass Header
struct LiquidGlassHeader: View {
    @ObservedObject var busylight: BusylightManager
    
    var body: some View {
//        HStack(spacing: 2) {
//            // Connection status indicator
//            ZStack {
//                Circle()
//                    .fill(busylight.isConnected ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
//                    .frame(width: 18, height: 18)
//
//                Circle()
//                    .fill(busylight.isConnected ? Color.green : Color.red)
//                    .frame(width: 6, height: 6)
//                    .shadow(color: (busylight.isConnected ? Color.green : Color.red).opacity(0.6), radius: 3)
//            }
//            
//            VStack(alignment: .leading, spacing: 0) {
//                Text(busylight.isConnected ? "Busylight Connected " : " Busylight Disconnected")
//                    .font(.system(.caption2, design: .rounded).weight(.semibold))
//                
////                Text(busylight.deviceName)
////                    .font(.system(.caption2, design: .rounded))
////                    .foregroundStyle(.secondary)
////                    .lineLimit(1)
////                    .truncationMode(.tail)
//            }
//            
//            Spacer()
//            
//            // Current color
//           // Circle()
//            //    .fill(busylight.color)
//            //    .frame(width: 14, height: 14)
//             //   .overlay(
//              //      Circle()
//             //           .stroke(.white.opacity(0.4), lineWidth: 1)
//              //  )
//              //  .shadow(color: busylight.color.opacity(0.4), radius: 3)
//        }
//        .padding(8)
//        .background(
//            ZStack {
//                RoundedRectangle(cornerRadius: 10)
//                    .fill(Material.thinMaterial)
//                
//                RoundedRectangle(cornerRadius: 10)
//                    .stroke(.white.opacity(0.15), lineWidth: 1)
//            }
//        )
    }
}

// MARK: - Liquid Glass Pomodoro Card
struct LiquidGlassPomodoroCard: View {
    @ObservedObject var busylight: BusylightManager
    @ObservedObject var manager: PomodoroManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: manager.currentPhase.icon)
                    .font(.caption2)
                    .foregroundStyle(manager.currentPhase.color)
                Spacer()
                
                // Phase badge con efectos
                PhaseLabel(
                    text: manager.currentPhase.rawValue,
                    color: manager.currentPhase.color,
                    isRunning: manager.isRunning
                )
                .font(.system(.caption2, design: .rounded))
            }
            .padding(.top, -4)

            // Timer display
            HStack {
                Text(manager.timeString)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(manager.isRunning ? manager.currentPhase.color : .primary)
                

                Spacer()
                
                VStack(alignment: .trailing, spacing: 0) {
                    // Phase label con efectos: glow + pulse + background capsule
//                    PhaseLabel(
//                        text: manager.currentPhase.rawValue,
//                        color: manager.currentPhase.color,
//                        isRunning: manager.isRunning
//                    )
                    Text("Set \(manager.currentSet)/\(manager.totalSets)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress bar glass
            CompactProgressBar(
                progress: manager.progress,
                color: manager.currentPhase.color
            )
            .frame(height: 4)


            // Control buttons - más compactos
            HStack(spacing: 1) {
                // Play button - activo solo cuando no está corriendo o está pausado
                Button {
                    HapticFeedback.prolonged()
                    manager.start()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "play.fill")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                }
                .buttonStyle(.liquidGlass(
                    color: (manager.isRunning && !manager.isPaused) ? .gray : .green,
                    prominent: !(manager.isRunning && !manager.isPaused)
                ))
                .disabled(manager.isRunning && !manager.isPaused)
                
                // Pause button - activo solo cuando está corriendo y no pausado
                Button {
                    HapticFeedback.prolonged()
                    manager.pause()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "pause.fill")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                }
                .buttonStyle(.liquidGlass(
                    color: (!manager.isRunning || manager.isPaused) ? .gray : .orange,
                    prominent: manager.isRunning && !manager.isPaused
                ))
                .disabled(!manager.isRunning || manager.isPaused)
                
                // Stop button - activo solo cuando está corriendo o pausado
                Button {
                    HapticFeedback.prolonged()
                    manager.stop()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "stop.fill")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                }
                .buttonStyle(.liquidGlass(
                    color: (!manager.isRunning && !manager.isPaused) ? .gray : .red,
                    prominent: manager.isRunning || manager.isPaused
                ))
                .disabled(!manager.isRunning && !manager.isPaused)
            }
            
            // Config badges - más pequeños
            HStack(spacing: 4) {
                LiquidGlassConfigBadge(icon: "briefcase.fill", value: manager.workTimeMinutes, color: .green)
                LiquidGlassConfigBadge(icon: "cup.and.saucer.fill", value: manager.shortBreakMinutes, color: .blue)
                LiquidGlassConfigBadge(icon: "sun.max.fill", value: manager.longBreakMinutes, color: .orange)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Phase Label con efectos visuales (Glow + Pulse + Background)
struct PhaseLabel: View {
    let text: String
    let color: Color
    let isRunning: Bool

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.6
    @State private var isHovered = false

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(isRunning ? color : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isRunning ? color.opacity(0.15) : Color.clear)
            .clipShape(Capsule())
            .onHover { hovering in
                isHovered = hovering
            }
            .brightness(isHovered && isRunning ? 0.1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

struct LiquidGlassConfigBadge: View {
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Liquid Glass Visibility Card
struct LiquidGlassVisibilityCard: View {
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
            
            HStack(spacing: 2) {
                LiquidGlassToggleRowMini(
                    icon: "dock.rectangle",
                    title: "Dock",
                    isOn: $appDelegate.showInDock
                )
                
                LiquidGlassToggleRowMini(
                    icon: "menubar.rectangle",
                    title: "Menu Bar",
                    isOn: $appDelegate.showInMenuBar
                )
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct LiquidGlassToggleRowMini: View {
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

// MARK: - Liquid Glass Quick Colors Card
struct LiquidGlassQuickColorButton: View {
    let color: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
        .frame(height: 26)
        .onHover { hovering in
            isHovered = hovering
        }
        .scaleEffect(isHovered ? 0.9 : 1.0)
        .shadow(color: color.opacity(isHovered ? 0.6 : 0.3), radius: isHovered ? 8 : 4, x: 0, y: 0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .focusable(false)
    }
}

// Compact Progress Bar - using scaleEffect instead of GeometryReader to avoid layout recursion
struct CompactProgressBar: View {
    let progress: Double
    let color: Color
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Material.thinMaterial)
                .frame(height: 4)
            
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(height: 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .scaleEffect(x: animatedProgress, y: 1.0, anchor: .leading)
        }
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

// MARK: - Liquid Glass Calendar Card
struct LiquidGlassCalendarCard: View {
    @State private var calendarStatus: CalendarStatus = .none
    @State private var hasCalendarAccess: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Calendar")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                Spacer()
            }
            
            // Status View
            CalendarStatusView(status: calendarStatus, hasCalendarAccess: hasCalendarAccess)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            // Leer valores iniciales sin observar
            calendarStatus = SmartFeaturesManager.shared.calendarStatus
            hasCalendarAccess = SmartFeaturesManager.shared.calendarAccessGranted
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CalendarStatusChanged"))) { _ in
            calendarStatus = SmartFeaturesManager.shared.calendarStatus
            hasCalendarAccess = SmartFeaturesManager.shared.calendarAccessGranted
        }
    }
    
    var calendarColor: Color {
        switch calendarStatus {
        case .inMeeting: return .red
        case .preparing: return .yellow
        case .available: return .green
        case .none: return .gray
        }
    }
}

// Componente separado para evitar recursion
struct CalendarStatusView: View {
    let status: CalendarStatus
    let hasCalendarAccess: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Status Row
            HStack(spacing: 6) {
                Circle()
                    .fill(calendarColor)
                    .frame(width: 8, height: 8)
                
                switch status {
                case .inMeeting(let title):
                    Text("In meeting: \(title.prefix(25))")
                        .font(.caption2)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                case .preparing(let title):
                    Text("Starting soon: \(title.prefix(25))")
                        .font(.caption2)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                case .available:
                    Text("✓ Available")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                case .none:
                    Text("No calendar access")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Next Event Preview
            if hasCalendarAccess, case .available = status {
                Divider().opacity(0.3)
                
                HStack(spacing: 4) {
                    Text("Next →")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Check main window")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .italic()
                    Spacer()
                }
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    var calendarColor: Color {
        switch status {
        case .inMeeting: return .red
        case .preparing: return .yellow
        case .available: return .green
        case .none: return .gray
        }
    }
}
