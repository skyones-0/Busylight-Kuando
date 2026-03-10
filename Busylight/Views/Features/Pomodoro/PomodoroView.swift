//
//  PomodoroView.swift
//  Busylight
//
//  Vista Pomodoro con diseño glassmorphism moderno
//

import SwiftUI

struct PomodoroView: View {
    @StateObject private var pomodoro = PomodoroManager.shared
    @EnvironmentObject var busylight: BusylightManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header con título elegante
                headerSection
                
                // Timer circular principal con glass
                timerSection
                
                // Indicador de fases
                phaseIndicatorSection
                
                // Controles principales
                controlsSection
                
                // Configuración rápida
                if !pomodoro.isRunning {
                    quickConfigSection
                }
                
                // Estadísticas
                statsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(pomodoro.currentPhase.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: pomodoro.currentPhase.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(pomodoro.currentPhase.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Focus Session")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                
                Text(pomodoro.phaseDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Phase badge
            PhaseBadge(phase: pomodoro.currentPhase, isRunning: pomodoro.isRunning)
        }
    }
    
    // MARK: - Timer Section
    private var timerSection: some View {
        ZStack {
            // Fondo glass
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(pomodoro.currentPhase.color.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: pomodoro.currentPhase.color.opacity(0.2), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 20) {
                // Timer circular
                ZStack {
                    // Círculo de fondo
                    Circle()
                        .stroke(pomodoro.currentPhase.color.opacity(0.15), lineWidth: 20)
                        .frame(width: 220, height: 220)
                    
                    // Círculo de progreso
                    Circle()
                        .trim(from: 0, to: pomodoro.progress)
                        .stroke(
                            pomodoro.currentPhase.color.gradient,
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: pomodoro.progress)
                    
                    // Tiempo
                    VStack(spacing: 4) {
                        Text(pomodoro.timeString)
                            .font(.system(size: 56, weight: .thin, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                        
                        Text("Set \(pomodoro.currentSet) of \(pomodoro.totalSets)")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 30)
                
                // Botones de acción rápida
                HStack(spacing: 20) {
                    if pomodoro.isRunning || pomodoro.isPaused {
                        GlassIconButton(
                            icon: "stop.fill",
                            color: .red,
                            action: { pomodoro.stop() }
                        )
                        
                        GlassIconButton(
                            icon: pomodoro.isRunning ? "pause.fill" : "play.fill",
                            color: pomodoro.isRunning ? .orange : .green,
                            isLarge: true,
                            action: {
                                if pomodoro.isRunning {
                                    pomodoro.pause()
                                } else {
                                    pomodoro.start()
                                }
                            }
                        )
                        
                        GlassIconButton(
                            icon: "forward.fill",
                            color: .blue,
                            action: { pomodoro.skip() }
                        )
                    } else {
                        GlassActionButton(
                            title: "Start Focus",
                            icon: "play.fill",
                            color: pomodoro.currentPhase.color,
                            isProminent: true
                        ) {
                            pomodoro.start()
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .frame(height: pomodoro.isRunning || pomodoro.isPaused ? 380 : 340)
    }
    
    // MARK: - Phase Indicator
    private var phaseIndicatorSection: some View {
        GlassCard(title: "Session Progress", icon: "chart.line.uptrend.xyaxis") {
            VStack(spacing: 16) {
                // Indicador visual de sets
                HStack(spacing: 8) {
                    ForEach(1...pomodoro.totalSets, id: \.self) { set in
                        HStack(spacing: 4) {
                            // Work indicator
                            PhaseDot(
                                isActive: set < pomodoro.currentSet || (set == pomodoro.currentSet && pomodoro.currentPhase == .work),
                                isCurrent: set == pomodoro.currentSet && pomodoro.currentPhase == .work,
                                color: .green
                            )
                            
                            // Break indicator (excepto después del último set)
                            if set < pomodoro.totalSets {
                                PhaseDot(
                                    isActive: set < pomodoro.currentSet || (set == pomodoro.currentSet && pomodoro.currentPhase != .work),
                                    isCurrent: set == pomodoro.currentSet && pomodoro.currentPhase != .work,
                                    color: set % 4 == 0 ? .orange : .blue
                                )
                            }
                        }
                    }
                }
                
                // Leyenda
                HStack(spacing: 16) {
                    LegendItem(color: .green, label: "Work")
                    LegendItem(color: .blue, label: "Short Break")
                    LegendItem(color: .orange, label: "Long Break")
                }
            }
        }
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        HStack(spacing: 12) {
            if !pomodoro.isRunning && !pomodoro.isPaused {
                // Botones de duración rápida
                DurationQuickButton(minutes: 15, isSelected: pomodoro.workTimeMinutes == 15) {
                    pomodoro.setDuration(15)
                }
                
                DurationQuickButton(minutes: 25, isSelected: pomodoro.workTimeMinutes == 25) {
                    pomodoro.setDuration(25)
                }
                
                DurationQuickButton(minutes: 45, isSelected: pomodoro.workTimeMinutes == 45) {
                    pomodoro.setDuration(45)
                }
                
                DurationQuickButton(minutes: 60, isSelected: pomodoro.workTimeMinutes == 60) {
                    pomodoro.setDuration(60)
                }
            }
        }
    }
    
    // MARK: - Quick Config Section
    private var quickConfigSection: some View {
        GlassCard(title: "Quick Settings", icon: "slider.horizontal.3") {
            VStack(spacing: 16) {
                // Work duration slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "briefcase.fill")
                            .foregroundStyle(.green)
                        Text("Work Duration")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(pomodoro.workTimeMinutes) min")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.green)
                    }
                    
                    CustomSlider(
                        value: Binding(
                            get: { Double(pomodoro.workTimeMinutes) },
                            set: { pomodoro.workTimeMinutes = Int($0) }
                        ),
                        range: 5...60,
                        step: 5,
                        color: .green
                    )
                }
                
                Divider()
                
                // Sets stepper
                HStack {
                    Image(systemName: "number")
                        .foregroundStyle(.purple)
                    Text("Number of Sets")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button {
                            if pomodoro.configuredSets > 1 {
                                pomodoro.configuredSets -= 1
                                pomodoro.updateConfiguration()
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Text("\(pomodoro.configuredSets)")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .frame(minWidth: 30)
                        
                        Button {
                            if pomodoro.configuredSets < 8 {
                                pomodoro.configuredSets += 1
                                pomodoro.updateConfiguration()
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Divider()
                
                // Break durations
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Short Break")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $pomodoro.shortBreakMinutes) {
                            ForEach([3, 5, 10, 15], id: \.self) { min in
                                Text("\(min) min").tag(min)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Long Break")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $pomodoro.longBreakMinutes) {
                            ForEach([10, 15, 20, 30], id: \.self) { min in
                                Text("\(min) min").tag(min)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }
            }
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            GlassStatCard(
                value: "\(pomodoro.sessionsCompleted)",
                label: "Completed",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            GlassStatCard(
                value: formattedTotalTime(),
                label: "Total Focus",
                icon: "clock.fill",
                color: .blue
            )
            
            GlassStatCard(
                value: "\(pomodoro.streak)",
                label: "Day Streak",
                icon: "flame.fill",
                color: .orange
            )
        }
    }
    
    // MARK: - Helpers
    private func formattedTotalTime() -> String {
        let hours = pomodoro.totalFocusTime / 3600
        let minutes = (pomodoro.totalFocusTime % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Supporting Views

struct PhaseBadge: View {
    let phase: PomodoroPhase
    let isRunning: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isRunning ? phase.color : .gray)
                .frame(width: 8, height: 8)
            
            Text(isRunning ? "Active" : "Ready")
                .font(.system(.caption, design: .rounded).weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isRunning ? phase.color.opacity(0.15) : Color.gray.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(isRunning ? phase.color.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .foregroundStyle(isRunning ? phase.color : .secondary)
    }
}

struct PhaseDot: View {
    let isActive: Bool
    let isCurrent: Bool
    let color: Color
    
    var body: some View {
        Circle()
            .fill(isActive ? color : Color.gray.opacity(0.2))
            .frame(width: isCurrent ? 14 : 10, height: isCurrent ? 14 : 10)
            .overlay(
                Circle()
                    .stroke(isCurrent ? color.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .shadow(color: isActive ? color.opacity(0.4) : Color.clear, radius: isCurrent ? 4 : 0)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct DurationQuickButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(minutes)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text("min")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
            .foregroundStyle(isSelected ? .green : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let color: Color
    
    var body: some View {
        Slider(value: $value, in: range, step: step)
            .tint(color)
            .padding(.horizontal, 4)
    }
}

struct GlassStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Material.thinMaterial)
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            }
        )
    }
}

// MARK: - Preview
struct PomodoroView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroView()
            .environmentObject(BusylightManager())
    }
}
