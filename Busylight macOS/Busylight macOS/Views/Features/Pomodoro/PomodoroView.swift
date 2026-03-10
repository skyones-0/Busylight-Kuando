//
//  PomodoroView.swift
//  Busylight
//
//  Vista completa del temporizador Pomodoro
//

import SwiftUI

struct PomodoroView: View {
    @StateObject private var pomodoro = PomodoroManager.shared
    @EnvironmentObject var busylight: BusylightManager
    @State private var selectedDuration: Int = 25
    
    let durations = [15, 25, 45]
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            headerSection
            
            // Timer Display
            timerDisplay
            
            // Duration Selector (solo cuando no está activo)
            if pomodoro.timerState == .idle {
                durationSelector
            }
            
            // Status Card
            statusCard
            
            // Controls
            controlsSection
            
            // Stats
            statsSection
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("⏱️ Pomodoro")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(pomodoro.phaseDescription)
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Timer Display
    private var timerDisplay: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.1)
                .foregroundColor(timerColor)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    timerColor.gradient,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            
            // Time text
            VStack(spacing: 8) {
                Text(formattedTime)
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                
                if pomodoro.timerState != .idle {
                    Text("Set \(pomodoro.currentSet) de \(pomodoro.maxSets)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 300, height: 300)
        .padding()
    }
    
    // MARK: - Duration Selector
    private var durationSelector: some View {
        VStack(spacing: 12) {
            Text("Duración")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                ForEach(durations, id: \.self) { duration in
                    DurationButton(
                        duration: duration,
                        isSelected: selectedDuration == duration
                    ) {
                        selectedDuration = duration
                        pomodoro.setDuration(duration)
                    }
                }
            }
        }
    }
    
    // MARK: - Status Card
    private var statusCard: some View {
        GlassCard(title: "Estado", icon: "info.circle.fill") {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 12, height: 12)
                        
                        Text(statusText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    if pomodoro.timerState != .idle {
                        Text("Tiempo restante: \(formattedTimeRemaining)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Phase indicator
                HStack(spacing: 4) {
                    ForEach(0..<pomodoro.maxSets * 2, id: \.self) { index in
                        Circle()
                            .fill(phaseColor(for: index))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }
    
    // MARK: - Controls
    private var controlsSection: some View {
        HStack(spacing: 20) {
            // Reset button
            Button(action: { pomodoro.reset() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 60, height: 60)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(pomodoro.timerState == .idle)
            
            // Main button (Start/Pause/Resume)
            Button(action: toggleTimer) {
                Image(systemName: mainButtonIcon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
                    .background(mainButtonColor.gradient)
                    .clipShape(Circle())
                    .shadow(radius: 10)
            }
            .buttonStyle(.plain)
            
            // Skip button
            Button(action: { pomodoro.skip() }) {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 60, height: 60)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(pomodoro.timerState == .idle)
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatBox(
                title: "Completados",
                value: "\(pomodoro.sessionsCompleted)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatBox(
                title: "Tiempo Total",
                value: formattedTotalTime,
                icon: "clock.fill",
                color: .blue
            )
            
            StatBox(
                title: "Racha",
                value: "\(pomodoro.streak) días",
                icon: "flame.fill",
                color: .orange
            )
        }
    }
    
    // MARK: - Helpers
    private var progress: Double {
        guard pomodoro.totalTime > 0 else { return 0 }
        return 1.0 - (Double(pomodoro.timeRemaining) / Double(pomodoro.totalTime))
    }
    
    private var formattedTime: String {
        let minutes = pomodoro.timeRemaining / 60
        let seconds = pomodoro.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var formattedTimeRemaining: String {
        let minutes = pomodoro.timeRemaining / 60
        return "\(minutes) min"
    }
    
    private var formattedTotalTime: String {
        let totalMinutes = pomodoro.totalFocusTime / 60
        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        } else {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
    
    private var timerColor: Color {
        switch pomodoro.currentPhase {
        case .work: return .blue
        case .shortBreak: return .green
        case .longBreak: return .purple
        }
    }
    
    private var statusColor: Color {
        switch pomodoro.timerState {
        case .running: return .green
        case .paused: return .orange
        case .idle: return .secondary
        }
    }
    
    private var statusText: String {
        switch pomodoro.timerState {
        case .running: return "En progreso"
        case .paused: return "Pausado"
        case .idle: return "Listo para iniciar"
        }
    }
    
    private var mainButtonIcon: String {
        switch pomodoro.timerState {
        case .idle: return "play.fill"
        case .running: return "pause.fill"
        case .paused: return "play.fill"
        }
    }
    
    private var mainButtonColor: Color {
        switch pomodoro.timerState {
        case .idle: return .blue
        case .running: return .orange
        case .paused: return .green
        }
    }
    
    private func toggleTimer() {
        switch pomodoro.timerState {
        case .idle:
            pomodoro.start()
            BusylightManager.shared.red() // Busy during work
        case .running:
            pomodoro.pause()
            BusylightManager.shared.yellow() // Available when paused
        case .paused:
            pomodoro.resume()
            BusylightManager.shared.red()
        }
    }
    
    private func phaseColor(for index: Int) -> Color {
        let currentIndex = (pomodoro.currentSet - 1) * 2 + (pomodoro.currentPhase == .work ? 0 : 1)
        if index < currentIndex {
            return .green
        } else if index == currentIndex {
            return pomodoro.currentPhase == .work ? .blue : .green
        } else {
            return .secondary.opacity(0.3)
        }
    }
}

// MARK: - Supporting Views

struct DurationButton: View {
    let duration: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(duration) min")
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Preview

struct PomodoroView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroView()
            .environmentObject(BusylightManager())
    }
}
