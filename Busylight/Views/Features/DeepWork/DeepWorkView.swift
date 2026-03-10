//
//  DeepWorkView.swift
//  Busylight
//
//  Deep Work mode UI with session timer and focus controls.
//  Allows setting focus duration and shows active session status.
//
//  Relationships:
//  - Uses: SmartFeaturesManager for deep work state and timer
//  - Uses: PomodoroManager (pauses when deep work starts)
//  - See: SmartFeaturesManager.swift for deep work logic
//

import SwiftUI

struct DeepWorkView: View {
    @StateObject private var smartFeatures = SmartFeaturesManager.shared
    @StateObject private var pomodoro = PomodoroManager.shared
    @State private var selectedDuration: Int = 90
    
    let durations = [30, 60, 90, 120, 180]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                if smartFeatures.isDeepWorkActive {
                    // Active Session View
                    activeSessionView
                } else {
                    // Configuration View
                    configurationView
                }
                
                // Benefits info
                benefitsSection
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
                    .fill(.purple.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24))
                    .foregroundStyle(.purple)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Deep Work")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                
                Text(smartFeatures.isDeepWorkActive ? "Modo concentración activo" : "Bloquea distracciones y enfócate")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if smartFeatures.isDeepWorkActive {
                DeepWorkBadge(minutes: smartFeatures.deepWorkRemainingMinutes)
            }
        }
    }
    
    // MARK: - Configuration View
    private var configurationView: some View {
        VStack(spacing: 20) {
            // Duration selection card
            LiquidCard(title: "Duración de la sesión", icon: "clock") {
                VStack(spacing: 16) {
                    // Duration buttons
                    HStack(spacing: 10) {
                        ForEach(durations, id: \.self) { duration in
                            DurationLiquidGlassButton(
                                minutes: duration,
                                isSelected: selectedDuration == duration
                            ) {
                                withAnimation(.spring()) {
                                    selectedDuration = duration
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Selected duration display
                    HStack {
                        Image(systemName: "hourglass")
                            .foregroundStyle(.purple)
                        Text("Sesión de \(selectedDuration) minutos")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(formattedEndTime(from: selectedDuration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Start button
            LiquidGlassActionButton(
                title: "Iniciar Deep Work",
                icon: "play.fill",
                color: .purple,
                isProminent: true
            ) {
                startDeepWork()
            }
            .frame(height: 60)
            
            // Warning about pomodoro
            if pomodoro.isRunning {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Pomodoro se pausará automáticamente")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }
    
    // MARK: - Active Session View
    private var activeSessionView: some View {
        VStack(spacing: 20) {
            // Timer card
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                
                VStack(spacing: 24) {
                    // Flame icon
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    
                    // Timer
                    VStack(spacing: 8) {
                        Text(formattedTime(smartFeatures.deepWorkRemainingMinutes))
                            .font(.system(size: 64, weight: .thin, design: .rounded))
                            .monospacedDigit()
                        
                        Text("minutos restantes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Progress bar - using scaleEffect instead of GeometryReader to avoid layout loops
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .scaleEffect(
                                x: max(0, min(CGFloat(smartFeatures.deepWorkRemainingMinutes) / CGFloat(selectedDuration), 1.0)),
                                y: 1.0,
                                anchor: .leading
                            )
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 40)
                    
                    // End button
                    LiquidGlassActionButton(
                        title: "Finalizar Sesión",
                        icon: "stop.fill",
                        color: .red,
                        isProminent: true,
                        action: { endDeepWork() }
                    )
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                }
                .padding(30)
            }
            .frame(height: 400)
            
            // Status card
            LiquidCard(title: "Estado actual", icon: "info.circle") {
                VStack(spacing: 12) {
                    StatusRowLiquidGlass(
                        icon: "pause.circle.fill",
                        title: "Pomodoro",
                        value: "Pausado",
                        color: .orange
                    )
                    
                    StatusRowLiquidGlass(
                        icon: "lightbulb.fill",
                        title: "Busylight",
                        value: "Rojo - No molestar",
                        color: .red
                    )
                    
                    StatusRowLiquidGlass(
                        icon: "moon.fill",
                        title: "Focus Mode",
                        value: "Activado",
                        color: .purple
                    )
                    
                    StatusRowLiquidGlass(
                        icon: "bell.slash.fill",
                        title: "Notificaciones",
                        value: "Silenciadas",
                        color: .gray
                    )
                }
            }
        }
    }
    
    // MARK: - Benefits Section
    private var benefitsSection: some View {
        LiquidCard(title: "Beneficios de Deep Work", icon: "star.fill") {
            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(icon: "target", text: "Mayor productividad y enfoque")
                BenefitRow(icon: "bolt", text: "Mejor calidad de trabajo")
                BenefitRow(icon: "clock", text: "Menos tiempo para completar tareas")
                BenefitRow(icon: "brain", text: "Mejor retención de información")
            }
        }
    }
    
    // MARK: - Actions
    private func startDeepWork() {
        smartFeatures.startDeepWorkMode(durationMinutes: selectedDuration)
        pomodoro.pause()
        
        NotificationCenterManager.shared.showDeepWorkStartNotification(duration: selectedDuration)
    }
    
    private func endDeepWork() {
        smartFeatures.endDeepWorkMode()
        
        NotificationCenterManager.shared.showDeepWorkEndNotification(completed: true)
    }
    
    // MARK: - Helpers
    private func formattedTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, mins)
        }
        return "\(mins)"
    }
    
    private func formattedEndTime(from minutes: Int) -> String {
        let endDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Termina a las \(formatter.string(from: endDate))"
    }
}

// MARK: - Supporting Views

struct DeepWorkBadge: View {
    let minutes: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.caption)
            Text("\(minutes) min")
                .font(.system(.caption, design: .rounded).weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.2))
        .clipShape(Capsule())
        .foregroundStyle(.orange)
    }
}

struct DurationLiquidGlassButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(minutes)")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text("min")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.purple.opacity(0.2) : Color.clear)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .foregroundStyle(isSelected ? .purple : .primary)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .scaleEffect(isHovered ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .focusable(false)
    }
}

struct StatusRowLiquidGlass: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.purple)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

// MARK: - Preview
struct DeepWorkView_Previews: PreviewProvider {
    static var previews: some View {
        DeepWorkView()
    }
}
