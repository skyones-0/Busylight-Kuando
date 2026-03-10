//
//  SettingsView.swift
//  Busylight
//
//  Settings UI with liquid glass design. Manages AppSettings SwiftData model.
//  Settings are automatically synced to AppDelegate via ContentView onChange handlers.
//
//  Relationships:
//  - Stores: AppSettings (SwiftData) - appearance, dock/menubar, notifications, ML
//  - Syncs with: ContentView.swift (theme, dock/menubar), AppDelegate (dock/menubar)
//  - Uses: MLScheduleManager for ML training status
//  - Uses: NotificationCenterManager for notification toggles
//

import SwiftUI
import SwiftData
import EventKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettings: [AppSettings]
    @Query private var calendarConfigs: [CalendarConfiguration]
    @Query private var calendarEvents: [CalendarEvent]
    
    @StateObject private var mlManager = MLScheduleManager.shared
    @StateObject private var notifications = NotificationCenterManager.shared
    
    @State private var showingCalendarPicker = false
    @State private var showingHolidayPicker = false
    @State private var showingClearConfirmation = false

    @State private var eventStore = EKEventStore()
    @State private var availableCalendars: [EKCalendar] = []
    
    private var settings: AppSettings {
        appSettings.first ?? AppSettings()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Calendars Section
                calendarsSection
                
                // ML Section
                mlSection
                
                // Appearance Section
                appearanceSection
                
                // Notifications Section
                notificationsSection
                
                // Data Management
                dataSection
                
                // About
                aboutSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .task {
            await loadSettings()
            await requestCalendarAccess()
        }
        .sheet(isPresented: $showingCalendarPicker) {
            CalendarPickerView(
                eventStore: eventStore,
                availableCalendars: availableCalendars,
                selectedCalendars: Set(calendarConfigs.filter { $0.calendarType != "holiday" }.map { $0.calendarIdentifier })
            ) { selectedIds in
                updateSelectedCalendars(selectedIds)
            }
        }
        .sheet(isPresented: $showingHolidayPicker) {
            HolidayCalendarPickerView { countryCode in
                addHolidayCalendar(countryCode: countryCode)
            }
        }
        .alert("¿Limpiar todos los datos?", isPresented: $showingClearConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Limpiar", role: .destructive) {
                mlManager.clearAllData()
            }
        } message: {
            Text("Esta acción eliminará todos los patrones de trabajo y el historial de entrenamiento. No se puede deshacer.")
        }

    }
    func showCountryPicker() {
        // Notificación para mostrar picker o lógica que prefieras
      //  NotificationCenter.default.post(name: .showCountryPicker, object: nil)
    }


    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                
                Text("Personaliza tu experiencia")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Calendars Section
    private var calendarsSection: some View {
        LiquidCard(title: "Calendars & Events", icon: "calendar.badge.clock") {
            VStack(spacing: 16) {
                // Calendarios seleccionados
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Calendarios de Trabajo")
                            .font(.subheadline.weight(.medium))
                        Text("\(calendarConfigs.filter { $0.calendarType != "holiday" && $0.isEnabled }.count) seleccionados")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Seleccionar") {
                        showingCalendarPicker = true
                    }
                    .buttonStyle(.liquidGlass(color: .blue))
                }
                
                Divider()
                
                // Calendarios de festivos
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Calendario de Festivos")
                            .font(.subheadline.weight(.medium))
                        Text(calendarConfigs.first { $0.calendarType == "holiday" }?.calendarName ?? "No configurado")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Configurar") {
                        showingHolidayPicker = true
                    }
                    .buttonStyle(.liquidGlass(color: .orange))
                }
                
                Divider()
                
                // Auto-detect location
                LiquidGlassToggleRow(
                    icon: "location.fill",
                    title: "Detectar país automáticamente",
                    subtitle: "Usa GPS para suscribirte a festivos de tu país",
                    isOn: Binding(
                        get: { settings.autoDetectLocation },
                        set: { newValue in
                            settings.autoDetectLocation = newValue
                            settings.updatedAt = Date()
                            saveSettings()
                            if newValue {
                                Task { @MainActor in
                                    //locationManager.manualSelectCountry(code: "US")
                                    settings.detectedCountryCode = "US"
                                    settings.detectedCountryName = "Estados Unidos"
                                    settings.detectedCountryFlag = "🇺🇸"
                                    settings.updatedAt = Date()
                                    saveSettings()
                                }
                            }
                        }
                    )
                )
                
                Divider()
                
                // Auto sync
                LiquidGlassToggleRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Sincronización automática",
                    subtitle: "Actualiza eventos cada hora",
                    isOn: Binding(
                        get: { settings.autoSyncCalendars },
                        set: { newValue in
                            settings.autoSyncCalendars = newValue
                            settings.updatedAt = Date()
                            saveSettings()
                        }
                    )
                )
                
                // Last sync info
                if let lastSync = settings.lastCalendarSync {
                    HStack {
                        Text("Última sincronización:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(lastSync, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - ML Section
    private var mlSection: some View {
        LiquidCard(title: "Machine Learning", icon: "brain.head.profile") {
            VStack(spacing: 16) {
                // Status
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(mlManager.isModelTrained ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: mlManager.isModelTrained ? "checkmark.seal.fill" : "brain")
                            .font(.title3)
                            .foregroundStyle(mlManager.isModelTrained ? .green : .orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Smart Schedule Learning")
                            .font(.subheadline.weight(.medium))
                        Text(mlStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { settings.mlEnabled },
                        set: { newValue in
                            settings.mlEnabled = newValue
                            settings.updatedAt = Date()
                            mlManager.updateConfiguration(isEnabled: newValue)
                            saveSettings()
                        }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
                
                if settings.mlEnabled {
                    Divider()
                    
                    // Training data progress
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Datos recolectados")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(mlManager.trainingDaysCollected) días")
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                        
                        // Progress bar - using fixed fraction instead of GeometryReader to avoid layout loops
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    mlManager.trainingDaysCollected >= 14 ? Color.green : Color.orange
                                )
                                .frame(
                                    width: nil,
                                    height: 8
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .scaleEffect(x: min(CGFloat(mlManager.trainingDaysCollected) / 14.0, 1.0), y: 1.0, anchor: .leading)
                        }
                        .frame(height: 8)
                        
                        if mlManager.isModelTrained {
                            HStack {
                                Text("Precisión del modelo:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Int(mlManager.modelAccuracy * 100))%")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Auto options
                    LiquidGlassToggleRow(
                        icon: "wand.and.stars",
                        title: "Entrenamiento automático",
                        subtitle: "Entrena cuando hay suficientes datos",
                        isOn: Binding(
                            get: { settings.autoTrainingEnabled },
                            set: { newValue in
                                settings.autoTrainingEnabled = newValue
                                settings.updatedAt = Date()
                                _ = newValue // Use AppSettings for autoTraining
                                saveSettings()
                            }
                        )
                    )
                    
                    // Auto-adjust schedule feature removed - manual work hours only
                }
            }
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        LiquidCard(title: "Appearance", icon: "paintpalette") {
            VStack(spacing: 16) {
                // Theme picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tema")
                        .font(.subheadline.weight(.medium))
                    
                    Picker("Tema", selection: Binding(
                        get: { settings.appearanceMode },
                        set: { newValue in
                            settings.appearanceMode = newValue
                            settings.updatedAt = Date()
                            saveSettings()
                        }
                    )) {
                        Label("Sistema", systemImage: "macpro.gen1").tag(0)
                        Label("Claro", systemImage: "sun.max.fill").tag(1)
                        Label("Oscuro", systemImage: "moon.fill").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider()
                
                // Dock & Menu Bar
                LiquidGlassToggleRow(
                    icon: "dock.rectangle",
                    title: "Mostrar en Dock",
                    isOn: Binding(
                        get: { settings.showInDock },
                        set: { newValue in
                            settings.showInDock = newValue
                            settings.updatedAt = Date()
                            saveSettings()
                            UserInteractionLogger.shared.dockVisibilityChanged(show: newValue)
                        }
                    )
                )
                
                LiquidGlassToggleRow(
                    icon: "menubar.rectangle",
                    title: "Mostrar en Menu Bar",
                    isOn: Binding(
                        get: { settings.showInMenuBar },
                        set: { newValue in
                            settings.showInMenuBar = newValue
                            settings.updatedAt = Date()
                            saveSettings()
                            UserInteractionLogger.shared.menuBarVisibilityChanged(show: newValue)
                        }
                    )
                )
            }
        }
    }
    
    // MARK: - Notifications Section
    private var notificationsSection: some View {
        LiquidCard(title: "Notifications", icon: "bell.badge") {
            VStack(spacing: 8) {
                LiquidGlassToggleRow(
                    icon: "eye",
                    title: "Regla 20-20-20",
                    subtitle: "Descansa la vista cada 20 minutos",
                    isOn: Binding(
                        get: { settings.twentyTwentyEnabled },
                        set: { newValue in
                            settings.twentyTwentyEnabled = newValue
                            settings.updatedAt = Date()
                            saveSettings()
                            if newValue {
                                notifications.startTwentyTwentyTimer()
                            } else {
                                notifications.stopTwentyTwentyTimer()
                            }
                        }
                    )
                )
                
                LiquidGlassToggleRow(
                    icon: "target",
                    title: "Alertas de Deep Work",
                    isOn: Binding(
                        get: { settings.deepWorkNotificationsEnabled },
                        set: { newValue in
                            settings.deepWorkNotificationsEnabled = newValue
                            settings.updatedAt = Date()
                            saveSettings()
                        }
                    )
                )
                
                LiquidGlassToggleRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Predicciones del día",
                    isOn: Binding(
                        get: { settings.dayPredictionNotificationsEnabled },
                        set: { newValue in
                            settings.dayPredictionNotificationsEnabled = newValue
                            settings.updatedAt = Date()
                            saveSettings()
                        }
                    )
                )
                
                LiquidGlassToggleRow(
                    icon: "cup.and.saucer",
                    title: "Recordatorios de descanso",
                    isOn: Binding(
                        get: { settings.breakRemindersEnabled },
                        set: { newValue in
                            settings.breakRemindersEnabled = newValue
                            settings.updatedAt = Date()
                            saveSettings()
                        }
                    )
                )
            }
        }
    }
    
    // MARK: - Data Section
    private var dataSection: some View {
        LiquidCard(title: "Data Management", icon: "externaldrive") {
            VStack(spacing: 12) {
                LiquidGlassActionRow(
                    icon: "square.and.arrow.up",
                    title: "Exportar Dataset ML",
                    color: .blue
                ) {
                    // Export functionality - TODO: Implement export
                }
                
                LiquidGlassActionRow(
                    icon: "wand.and.stars",
                    title: "Generar Datos de Demo",
                    color: .purple
                ) {
                    mlManager.generateDemoData()
                }
                
                LiquidGlassActionRow(
                    icon: "trash",
                    title: "Limpiar Datos de Entrenamiento",
                    color: .red
                ) {
                    showingClearConfirmation = true
                }
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        LiquidCard(title: "About", icon: "info.circle") {
            HStack(spacing: 16) {
                // App Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: .orange.opacity(0.4), radius: 8)
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Busylight")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Link(destination: URL(string: "https://skyones.co")!) {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var mlStatusText: String {
        if !settings.mlEnabled {
            return "ML desactivado"
        }
        if mlManager.isModelTrained {
            return "Modelo entrenado - \(Int(mlManager.modelAccuracy * 100))% precisión"
        }
        return "Recolectando datos - \(mlManager.trainingDaysCollected) días"
    }
    
    // MARK: - Actions
    private func loadSettings() async {
        if appSettings.isEmpty {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
        }
    }
    
    private func saveSettings() {
        try? modelContext.save()
    }
    
    private func requestCalendarAccess() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .notDetermined {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                if granted {
                    await loadCalendars()
                }
            } catch {
                BusylightLogger.shared.error("Error requesting calendar access: \(error)")
            }
        } else if status == .fullAccess {
            await loadCalendars()
        }
    }
    
    @MainActor
    private func loadCalendars() async {
        availableCalendars = eventStore.calendars(for: .event)
            .filter { $0.allowsContentModifications }
            .sorted { $0.title < $1.title }
    }
    
    private func updateSelectedCalendars(_ selectedIds: Set<String>) {
        // Remove unselected calendars
        for config in calendarConfigs where config.calendarType != "holiday" {
            if !selectedIds.contains(config.calendarIdentifier) {
                modelContext.delete(config)
            }
        }
        
        // Add newly selected calendars
        for calendar in availableCalendars where selectedIds.contains(calendar.calendarIdentifier) {
            let exists = calendarConfigs.contains { $0.calendarIdentifier == calendar.calendarIdentifier }
            if !exists {
                let newConfig = CalendarConfiguration(
                    calendarIdentifier: calendar.calendarIdentifier,
                    calendarName: calendar.title,
                    calendarType: "work",
                    colorHex: calendar.cgColor?.toHex()
                )
                modelContext.insert(newConfig)
            }
        }
        
        // Sync events
        syncCalendarEvents()
        saveSettings()
    }
    
    private func addHolidayCalendar(countryCode: String) {
        // Remove existing holiday calendar
        for config in calendarConfigs where config.calendarType == "holiday" {
            modelContext.delete(config)
        }
        
        let country = CalendarConfiguration.supportedCountries.first { $0.code == countryCode }
        let holidayConfig = CalendarConfiguration(
            calendarIdentifier: "holidays.\(countryCode)",
            calendarName: "\(country?.flag ?? "🌎") Festivos \(country?.name ?? countryCode)",
            calendarType: "holiday"
        )
        modelContext.insert(holidayConfig)
        saveSettings()
        
        // Generate holidays for ML
        let holidays = HolidayData.holidays(for: countryCode, year: Calendar.current.component(.year, from: Date()))
        BusylightLogger.shared.info("Added \(holidays.count) holidays for \(countryCode)")
    }
    
    private func syncCalendarEvents() {
        let enabledConfigs = calendarConfigs.filter { $0.isEnabled && $0.calendarType != "holiday" }
        
        for config in enabledConfigs {
            guard let ekCalendar = availableCalendars.first(where: { $0.calendarIdentifier == config.calendarIdentifier }) else { continue }
            
            let predicate = eventStore.predicateForEvents(
                withStart: Date().addingTimeInterval(-30*24*60*60), // 30 days ago
                end: Date().addingTimeInterval(30*24*60*60), // 30 days ahead
                calendars: [ekCalendar]
            )
            
            let events = eventStore.events(matching: predicate)
            
            // Check for existing events
            let existingEventIds = Set(calendarEvents.map { $0.eventIdentifier })
            
            for event in events {
                if !existingEventIds.contains(event.eventIdentifier) {
                    let newEvent = CalendarEvent(
                        eventIdentifier: event.eventIdentifier,
                        title: event.title,
                        startDate: event.startDate,
                        endDate: event.endDate,
                        isAllDay: event.isAllDay,
                        calendarIdentifier: event.calendar.calendarIdentifier,
                        calendarName: event.calendar.title,
                        notes: event.notes,
                        location: event.location,
                        attendeeCount: event.attendees?.count ?? 0
                    )
                    newEvent.analyzeIfMeeting()
                    modelContext.insert(newEvent)
                }
            }
        }
        
        settings.lastCalendarSync = Date()
        saveSettings()
        BusylightLogger.shared.info("Synced calendar events")
    }
}

// MARK: - Supporting Views

struct LiquidGlassActionRow: View {
    @State private var isHovered = false
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .onHover { hovering in
                isHovered = hovering
            }
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

// MARK: - Helper Extensions

extension CGColor {
    func toHex() -> String? {
        guard let components = self.components, components.count >= 3 else { return nil }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .modelContainer(for: [AppSettings.self, CalendarConfiguration.self, CalendarEvent.self])
    }
}
