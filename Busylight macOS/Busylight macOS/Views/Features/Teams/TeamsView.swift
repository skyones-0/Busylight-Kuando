//
//  TeamsView.swift
//  Busylight
//
//  Integración con Microsoft Teams
//

import SwiftUI

struct TeamsView: View {
    @State private var isConnected = false
    @State private var userName = ""
    @State private var status: TeamsStatus = .offline
    @State private var activities: [TeamsActivity] = []
    
    enum TeamsStatus: String {
        case available = "Disponible"
        case busy = "Ocupado"
        case doNotDisturb = "No Molestar"
        case away = "Ausente"
        case offline = "Desconectado"
        
        var color: Color {
            switch self {
            case .available: return .green
            case .busy: return .red
            case .doNotDisturb: return .purple
            case .away: return .orange
            case .offline: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .available: return "checkmark.circle.fill"
            case .busy: return "circle.fill"
            case .doNotDisturb: return "minus.circle.fill"
            case .away: return "moon.fill"
            case .offline: return "circle"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            headerSection
            
            if !isConnected {
                // Connect View
                connectView
            } else {
                // Connected View
                connectedView
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.badge.key.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("Microsoft Teams")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Sincroniza tu estado con Teams")
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Connect View
    private var connectView: some View {
        VStack(spacing: 24) {
            // Features list
            VStack(alignment: .leading, spacing: 12) {
                TeamsFeatureRow(icon: "arrow.triangle.2.circlepath", text: "Sincronización bidireccional de estado")
                TeamsFeatureRow(icon: "calendar", text: "Detecta reuniones automáticamente")
                TeamsFeatureRow(icon: "lightbulb.fill", text: "Actualiza Busylight según tu estado")
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
            
            // Connect button
            Button(action: connectTeams) {
                HStack {
                    Image(systemName: "link")
                    Text("Conectar con Teams")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: 300)
                .padding()
                .background(Color.purple.gradient)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Text("Requiere inicio de sesión en Microsoft 365")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Connected View
    private var connectedView: some View {
        VStack(spacing: 24) {
            // User Card
            GlassCard(title: "Usuario", icon: "person.circle") {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userName.isEmpty ? "Usuario Conectado" : userName)
                            .font(.headline)
                        
                        HStack(spacing: 6) {
                            Image(systemName: status.icon)
                                .foregroundColor(status.color)
                            
                            Text(status.rawValue)
                                .font(.subheadline)
                                .foregroundColor(status.color)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: disconnectTeams) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Status Selector
            GlassCard(title: "Estado", icon: "info.circle") {
                VStack(spacing: 12) {
                    ForEach([TeamsStatus.available, .busy, .doNotDisturb, .away], id: \.self) { teamStatus in
                        StatusButton(
                            status: teamStatus,
                            isSelected: status == teamStatus
                        ) {
                            changeStatus(to: teamStatus)
                        }
                    }
                }
            }
            
            // Today's Activities
            if !activities.isEmpty {
                GlassCard(title: "Actividades de Hoy", icon: "calendar") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(activities) { activity in
                            ActivityRow(activity: activity)
                        }
                    }
                }
            }
            
            // Sync Settings
            GlassCard(title: "Sincronización", icon: "arrow.triangle.2.circlepath") {
                VStack(spacing: 12) {
                    Toggle("Sincronizar automáticamente", isOn: .constant(true))
                    Toggle("Detectar reuniones", isOn: .constant(true))
                    Toggle("Sincronizar con Busylight", isOn: .constant(true))
                }
            }
        }
    }
    
    // MARK: - Actions
    private func connectTeams() {
        // Simulate connection
        isConnected = true
        userName = "Usuario Demo"
        status = .available
        
        // Sample activities
        activities = [
            TeamsActivity(time: "09:00", title: "Daily Standup", type: .meeting),
            TeamsActivity(time: "11:30", title: "Revisión de diseño", type: .meeting),
            TeamsActivity(time: "14:00", title: "Llamada con cliente", type: .call)
        ]
    }
    
    private func disconnectTeams() {
        isConnected = false
        userName = ""
        activities = []
    }
    
    private func changeStatus(to newStatus: TeamsStatus) {
        status = newStatus
        
        // Sync with Busylight
        let busylight = BusylightManager.shared
        switch newStatus {
        case .available:
            busylight.green()
        case .busy, .doNotDisturb:
            busylight.red()
        case .away:
            busylight.yellow()
        case .offline:
            busylight.off()
        }
    }
}

// MARK: - Supporting Types

struct TeamsFeatureRow: View {
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

struct StatusButton: View {
    let status: TeamsView.TeamsStatus
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: status.icon)
                    .foregroundColor(status.color)
                
                Text(status.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.purple.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct TeamsActivity: Identifiable {
    let id = UUID()
    let time: String
    let title: String
    let type: ActivityType
    
    enum ActivityType {
        case meeting, call, focus
        
        var icon: String {
            switch self {
            case .meeting: return "video.fill"
            case .call: return "phone.fill"
            case .focus: return "moon.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .meeting: return .blue
            case .call: return .green
            case .focus: return .purple
            }
        }
    }
}

struct ActivityRow: View {
    let activity: TeamsActivity
    
    var body: some View {
        HStack {
            Image(systemName: activity.type.icon)
                .foregroundColor(activity.type.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct TeamsView_Previews: PreviewProvider {
    static var previews: some View {
        TeamsView()
    }
}
