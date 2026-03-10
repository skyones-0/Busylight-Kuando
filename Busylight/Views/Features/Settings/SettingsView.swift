//
//  SettingsView.swift
//  Busylight
//
//  Configuración de la app
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @StateObject private var mlManager = MLScheduleManager.shared
    @StateObject private var notifications = NotificationCenterManager.shared
    @AppStorage("appearanceMode") private var appearanceMode = 0
    @AppStorage("twentyTwentyEnabled") private var twentyTwentyEnabled = true
    
    @State private var showingClearDataConfirmation = false
    @State private var showingExportSheet = false
    
    var body: some View {
        Form {
            // MARK: - Appearance
            Section("Apariencia") {
                Picker("Tema", selection: $appearanceMode) {
                    Text("Sistema").tag(0)
                    Text("Claro").tag(1)
                    Text("Oscuro").tag(2)
                }
                .pickerStyle(.segmented)
            }
            
            // MARK: - Notifications
            Section("Notificaciones") {
                Toggle("Regla 20-20-20", isOn: $twentyTwentyEnabled)
                    .onChange(of: twentyTwentyEnabled) { oldValue, newValue in
                        if newValue {
                            notifications.startTwentyTwentyTimer()
                        } else {
                            notifications.stopTwentyTwentyTimer()
                        }
                    }
                
                Toggle("Alertas de Deep Work", isOn: .constant(true))
                Toggle("Predicciones del día", isOn: .constant(true))
            }
            
            // MARK: - ML Settings
            Section("Machine Learning") {
                Toggle("ML Habilitado", isOn: Binding(
                    get: { mlManager.configuration?.isMLEnabled ?? false },
                    set: { mlManager.updateConfiguration(isEnabled: $0) }
                ))
                
                NavigationLink("Calendarios de Festivos") {
                    HolidayCalendarsView()
                }
                
                Button("Exportar Dataset de Entrenamiento") {
                    showingExportSheet = true
                }
                
                Button("Agregar Datos de Demo") {
                    mlManager.generateDemoData()
                }
                .foregroundColor(.blue)
                
                Button("Limpiar Datos de Entrenamiento") {
                    showingClearDataConfirmation = true
                }
                .foregroundColor(.red)
            }
            
            // MARK: - Device
            Section("Dispositivo") {
                NavigationLink("Configuración de Busylight") {
                    DeviceSettingsView()
                }
            }
            
            // MARK: - About
            Section("Acerca de") {
                HStack {
                    Text("Versión")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Modelo ML")
                    Spacer()
                    Text("DayCategoryClassifier")
                        .foregroundColor(.secondary)
                }
                
                Link("Sitio Web", destination: URL(string: "https://skyones.co")!)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Configuración")
        .alert("¿Limpiar todos los datos?", isPresented: $showingClearDataConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Limpiar", role: .destructive) {
                mlManager.clearAllData()
            }
        } message: {
            Text("Esta acción eliminará todos los patrones de trabajo y el historial de entrenamiento. No se puede deshacer.")
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDatasetView()
        }
    }
}

// MARK: - Holiday Calendars View

struct HolidayCalendarsView: View {
    @StateObject private var mlManager = MLScheduleManager.shared
    @State private var showingAddCalendar = false
    
    var body: some View {
        List {
            ForEach(mlManager.getHolidayCalendars()) { calendar in
                HolidayCalendarRow(calendar: calendar)
            }
            .onDelete { indexSet in
                // Delete calendars
            }
        }
        .navigationTitle("Calendarios de Festivos")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddCalendar = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCalendar) {
            AddHolidayCalendarView()
        }
    }
}

struct HolidayCalendarRow: View {
    let calendar: HolidayCalendar
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(calendar.name)
                    .font(.headline)
                
                Text("\(calendar.customDates.count) fechas personalizadas")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if calendar.isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Add Holiday Calendar View

struct AddHolidayCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var countryCode = "US"
    
    let countries = [
        ("US", "🇺🇸 Estados Unidos"),
        ("MX", "🇲🇽 México"),
        ("ES", "🇪🇸 España"),
        ("CO", "🇨🇴 Colombia"),
        ("AR", "🇦🇷 Argentina")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Nombre", text: $name)
                
                Picker("País", selection: $countryCode) {
                    ForEach(countries, id: \.0) { code, name in
                        Text(name).tag(code)
                    }
                }
            }
            .navigationTitle("Nuevo Calendario")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        MLScheduleManager.shared.createHolidayCalendar(
                            name: name,
                            date: Date()
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Device Settings View

struct DeviceSettingsView: View {
    @EnvironmentObject var busylight: BusylightManager
    
    var body: some View {
        Form {
            Section("Estado") {
                HStack {
                    Text("Conexión")
                    Spacer()
                    Text(busylight.isConnected ? "Conectado" : "Desconectado")
                        .foregroundColor(busylight.isConnected ? .green : .red)
                }
            }
            
            Section("Colores") {
                ColorPresetButtons()
            }
            
            Section("Efectos") {
                Button("Test de Luz") {
                    busylight.red()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        busylight.green()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        busylight.blue()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        busylight.off()
                    }
                }
                
                Button("Pulso") {
                    busylight.yellow()
                }
            }
        }
        .navigationTitle("Configuración de Busylight")
    }
}

// MARK: - Color Preset Buttons

struct ColorPresetButtons: View {
    @EnvironmentObject var busylight: BusylightManager
    
    let colors: [(String, NSColor)] = [
        ("Rojo", .red),
        ("Verde", .green),
        ("Azul", .blue),
        ("Amarillo", .yellow),
        ("Cian", .cyan),
        ("Magenta", .magenta),
        ("Blanco", .white),
        ("Naranja", .orange),
        ("Morado", .purple),
        ("Rosa", .systemPink)
    ]
    
    private func colorForIndex(_ index: Int) -> Color {
        switch index {
        case 0: return .red
        case 1: return .green
        case 2: return .blue
        case 3: return .yellow
        case 4: return .cyan
        case 5: return .pink
        case 6: return .white
        case 7: return .orange
        case 8: return .purple
        case 9: return .pink
        default: return .gray
        }
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
            ForEach(Array(colors.enumerated()), id: \.offset) { index, item in
                let (name, _) = item
                Button(action: { 
                    switch index {
                    case 0: busylight.red()
                    case 1: busylight.green()
                    case 2: busylight.blue()
                    case 3: busylight.yellow()
                    case 4: busylight.blue()
                    case 5: busylight.off()
                    case 6: busylight.off()
                    case 7: busylight.yellow()
                    case 8: busylight.blue()
                    case 9: busylight.red()
                    default: break
                    }
                }) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorForIndex(index))
                        .frame(height: 40)
                        .overlay(
                            Text(name)
                                .font(.caption)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Export Dataset View

struct ExportDatasetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mlManager = MLScheduleManager.shared
    @State private var exportURL: URL?
    @State private var isExporting = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.text")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Exportar Dataset")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Exporta tus patrones de trabajo para entrenar el modelo externamente.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if isExporting {
                    ProgressView()
                        .padding()
                } else if let url = exportURL {
                    VStack(spacing: 12) {
                        Text("✅ Exportado exitosamente")
                            .foregroundColor(.green)
                        
                        Text(url.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button("Exportar a CSV") {
                        exportDataset()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
    
    private func exportDataset() {
        isExporting = true
        exportURL = URL(string: "file://" + mlManager.exportTrainingDataset()) ?? URL(string: "file:///tmp/export.csv")!
        isExporting = false
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
