//
//  WorkProfilesView.swift
//  Busylight
//
//  Perfiles de trabajo para diferentes contextos
//

import SwiftUI

struct WorkProfilesView: View {
    @State private var profiles: [WorkProfileConfig] = WorkProfileConfig.defaultProfiles
    @State private var selectedProfile: WorkProfileConfig?
    @State private var showingAddProfile = false
    @State private var editingProfile: WorkProfileConfig?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerSection
            
            // Profiles Grid
            profilesGrid
            
            // Active Profile Info
            if let profile = selectedProfile {
                activeProfileSection(profile: profile)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingAddProfile) {
            EditProfileView(profile: nil) { newProfile in
                profiles.append(newProfile)
            }
        }
        .sheet(item: $editingProfile) { profile in
            EditProfileView(profile: profile) { updatedProfile in
                if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
                    profiles[index] = updatedProfile
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Perfiles de Trabajo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Configuraciones para diferentes contextos")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { showingAddProfile = true }) {
                Image(systemName: "plus")
                    .font(.title2)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Profiles Grid
    private var profilesGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(profiles) { profile in
                ProfileCard(
                    profile: profile,
                    isSelected: selectedProfile?.id == profile.id
                ) {
                    selectProfile(profile)
                } onEdit: {
                    editingProfile = profile
                }
            }
        }
    }
    
    // MARK: - Active Profile Section
    private func activeProfileSection(profile: WorkProfileConfig) -> some View {
        GlassCard(title: "Perfil Activo: \(profile.name)", icon: profile.icon) {
            VStack(alignment: .leading, spacing: 16) {
                // Settings
                VStack(alignment: .leading, spacing: 12) {
                    SettingRow(icon: "clock", title: "Horario", value: profile.workHours)
                    SettingRow(icon: "bell", title: "Notificaciones", value: profile.notificationMode)
                    SettingRow(icon: "lightbulb", title: "Luz predeterminada", value: profile.defaultLightColor)
                    SettingRow(icon: "timer", title: "Pomodoro", value: "\(profile.pomodoroDuration) min")
                }
                
                Divider()
                
                // Apply button
                Button(action: { applyProfile(profile) }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Aplicar Perfil")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(profile.color.gradient)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Actions
    private func selectProfile(_ profile: WorkProfileConfig) {
        selectedProfile = profile
    }
    
    private func applyProfile(_ profile: WorkProfileConfig) {
        // Apply work hours to AppStorage through SmartFeaturesManager
        SmartFeaturesManager.shared.workStartTime = profile.workStartHour
        SmartFeaturesManager.shared.workEndTime = profile.workEndHour
        
        // Apply Pomodoro duration
        PomodoroManager.shared.workTimeMinutes = profile.pomodoroDuration
        
        // Apply light color
        let color = profile.nsColor
        switch profile.defaultLightColor {
        case "Rojo": BusylightManager.shared.red()
        case "Verde": BusylightManager.shared.green()
        case "Azul": BusylightManager.shared.blue()
        case "Amarillo": BusylightManager.shared.yellow()
        case "Morado": BusylightManager.shared.purple()
        default: BusylightManager.shared.blue()
        }
        
        NotificationCenterManager.shared.showInfoNotification(
            title: "Perfil Aplicado",
            body: "Se aplicó el perfil \(profile.name)"
        )
    }
}

// MARK: - Work Profile Model

struct WorkProfileConfig: Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var color: Color
    var workStartHour: Int
    var workEndHour: Int
    var notificationMode: String
    var defaultLightColor: String
    var pomodoroDuration: Int
    
    var workHours: String {
        "\(workStartHour):00 - \(workEndHour):00"
    }
    
    var nsColor: NSColor? {
        switch defaultLightColor {
        case "Rojo": return .red
        case "Verde": return .green
        case "Azul": return .blue
        case "Amarillo": return .yellow
        case "Morado": return .purple
        default: return .blue
        }
    }
    
    static let defaultProfiles: [WorkProfileConfig] = [
        WorkProfileConfig(
            name: "Oficina",
            icon: "building.2.fill",
            color: .blue,
            workStartHour: 9,
            workEndHour: 18,
            notificationMode: "Todas",
            defaultLightColor: "Azul",
            pomodoroDuration: 25
        ),
        WorkProfileConfig(
            name: "Casa",
            icon: "house.fill",
            color: .green,
            workStartHour: 8,
            workEndHour: 17,
            notificationMode: "Importantes",
            defaultLightColor: "Verde",
            pomodoroDuration: 25
        ),
        WorkProfileConfig(
            name: "Focus",
            icon: "target",
            color: .purple,
            workStartHour: 6,
            workEndHour: 14,
            notificationMode: "Silencio",
            defaultLightColor: "Rojo",
            pomodoroDuration: 50
        ),
        WorkProfileConfig(
            name: "Reuniones",
            icon: "person.3.fill",
            color: Color.orange,
            workStartHour: 9,
            workEndHour: 18,
            notificationMode: "Solo llamadas",
            defaultLightColor: "Amarillo",
            pomodoroDuration: 15
        )
    ]
}

// MARK: - Profile Card

struct ProfileCard: View {
    let profile: WorkProfileConfig
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Image(systemName: profile.icon)
                    .font(.system(size: 40))
                    .foregroundColor(profile.color)
                
                Text(profile.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(profile.workHours)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? profile.color : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    let profile: WorkProfileConfig?
    let onSave: (WorkProfileConfig) -> Void
    
    @State private var name: String
    @State private var workStartHour: Int
    @State private var workEndHour: Int
    @State private var pomodoroDuration: Int
    
    init(profile: WorkProfileConfig?, onSave: @escaping (WorkProfileConfig) -> Void) {
        self.profile = profile
        self.onSave = onSave
        
        _name = State(initialValue: profile?.name ?? "Nuevo Perfil")
        _workStartHour = State(initialValue: profile?.workStartHour ?? 9)
        _workEndHour = State(initialValue: profile?.workEndHour ?? 18)
        _pomodoroDuration = State(initialValue: profile?.pomodoroDuration ?? 25)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Información") {
                    TextField("Nombre", text: $name)
                }
                
                Section("Horario") {
                    Stepper("Inicio: \(workStartHour):00", value: $workStartHour, in: 5...12)
                    Stepper("Fin: \(workEndHour):00", value: $workEndHour, in: 13...23)
                }
                
                Section("Pomodoro") {
                    Picker("Duración", selection: $pomodoroDuration) {
                        Text("15 min").tag(15)
                        Text("25 min").tag(25)
                        Text("50 min").tag(50)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(profile == nil ? "Nuevo Perfil" : "Editar Perfil")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let newProfile = WorkProfileConfig(
                            name: name,
                            icon: profile?.icon ?? "briefcase.fill",
                            color: profile?.color ?? .blue,
                            workStartHour: workStartHour,
                            workEndHour: workEndHour,
                            notificationMode: profile?.notificationMode ?? "Todas",
                            defaultLightColor: profile?.defaultLightColor ?? "Azul",
                            pomodoroDuration: pomodoroDuration
                        )
                        onSave(newProfile)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Setting Row

struct SettingRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

struct WorkProfilesView_Previews: PreviewProvider {
    static var previews: some View {
        WorkProfilesView()
    }
}
