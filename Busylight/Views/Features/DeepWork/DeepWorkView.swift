//
//  DeepWorkView.swift
//  Busylight
//
//  Vista de Deep Work Mode
//

import SwiftUI

struct DeepWorkView: View {
    @StateObject private var smartFeatures = SmartFeaturesManager.shared
    @StateObject private var pomodoro = PomodoroManager.shared
    @State private var selectedDuration: Int = 90
    @State private var isConfiguring = true
    
    let durations = [60, 90, 120, 180]
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            headerSection
            
            if isConfiguring || !smartFeatures.isDeepWorkActive {
                // Configuration View
                configurationView
            } else {
                // Active Session View
                activeSessionView
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("🎯 Deep Work")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Modo de trabajo profundo y enfocado")
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Configuration View
    private var configurationView: some View {
        VStack(spacing: 32) {
            // Icon
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.purple)
                .symbolRenderingMode(.hierarchical)
            
            // Description
            VStack(spacing: 12) {
                Text("Bloquea distracciones")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Durante el Deep Work:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    FeatureRow(icon: "pause.circle.fill", text: "Pomodoro se pausa automáticamente")
                    FeatureRow(icon: "moon.fill", text: "Activar modo No Molestar")
                    FeatureRow(icon: "lightbulb.fill", text: "Luz roja de ocupado")
                    FeatureRow(icon: "bell.slash.fill", text: "Silenciar notificaciones")
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Duration Selector
            VStack(spacing: 12) {
                Text("Duración de la sesión")
                    .font(.headline)
                
                Picker("Duración", selection: $selectedDuration) {
                    ForEach(durations, id: \.self) { duration in
                        Text("\(duration) minutos").tag(duration)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 400)
            }
            
            // Start Button
            Button(action: startDeepWork) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Iniciar Deep Work")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: 300)
                .padding()
                .background(Color.purple.gradient)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Active Session View
    private var activeSessionView: some View {
        VStack(spacing: 32) {
            // Status Badge
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.purple)
                Text("Deep Work Activo")
                    .font(.headline)
                    .foregroundColor(.purple)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(20)
            
            // Timer
            VStack(spacing: 16) {
                Text("Tiempo restante")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(formattedMinutes(smartFeatures.deepWorkRemainingMinutes))
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundColor(.purple)
                
                Text("Minutos restantes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Current Status
            GlassCard(title: "Estado Actual", icon: "info.circle") {
                VStack(alignment: .leading, spacing: 12) {
                    StatusRow(icon: "pause.circle", title: "Pomodoro", value: "Pausado automáticamente")
                    StatusRow(icon: "lightbulb", title: "Busylight", value: "Rojo - No molestar")
                    StatusRow(icon: "moon", title: "Focus", value: "Modo concentración activo")
                }
            }
            .frame(maxWidth: 400)
            
            // End Button
            Button(action: endDeepWork) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Finalizar Sesión")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: 300)
                .padding()
                .background(Color.red.gradient)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
        }
    }
    
    // MARK: - Actions
    private func startDeepWork() {
        smartFeatures.startDeepWorkMode(durationMinutes: selectedDuration)
        pomodoro.pause()
        isConfiguring = false
        
        NotificationCenterManager.shared.showDeepWorkStartNotification(duration: selectedDuration)
    }
    
    private func endDeepWork() {
        smartFeatures.endDeepWorkMode()
        isConfiguring = true
        
        NotificationCenterManager.shared.showDeepWorkEndNotification(completed: true)
    }
    
    // MARK: - Helpers
    private func formattedMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%02d:%02d", hours, mins)
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct StatusRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

struct DeepWorkView_Previews: PreviewProvider {
    static var previews: some View {
        DeepWorkView()
    }
}
