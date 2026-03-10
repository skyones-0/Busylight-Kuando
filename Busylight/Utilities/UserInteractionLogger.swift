//
//  UserInteractionLogger.swift
//  Busylight
//
//  Logger específico para trackear todas las interacciones del usuario
//

import Foundation

/// Logger dedicado para registrar todas las interacciones del usuario
final class UserInteractionLogger {
    static let shared = UserInteractionLogger()
    
    private init() {}
    
    // MARK: - Navigation
    
    func navigation(to view: String) {
        BusylightLogger.shared.info("[USER] Navegación a: \(view)")
    }
    
    // MARK: - Device Control
    
    func deviceColorChanged(color: String) {
        BusylightLogger.shared.info("[USER] Color cambiado a: \(color)")
    }
    
    func deviceJinglePlayed(number: Int) {
        BusylightLogger.shared.info("[USER] Jingle reproducido: #\(number)")
    }
    
    func deviceAction(action: String) {
        BusylightLogger.shared.info("[USER] Acción de dispositivo: \(action)")
    }
    
    // MARK: - Pomodoro
    
    func pomodoroStarted(phase: String, timeMinutes: Int) {
        BusylightLogger.shared.info("[USER] Pomodoro iniciado - Fase: \(phase), Tiempo: \(timeMinutes)min")
    }
    
    func pomodoroPaused(remainingTime: String) {
        BusylightLogger.shared.info("[USER] Pomodoro pausado - Tiempo restante: \(remainingTime)")
    }
    
    func pomodoroResumed() {
        BusylightLogger.shared.info("[USER] Pomodoro reanudado")
    }
    
    func pomodoroStopped() {
        BusylightLogger.shared.info("[USER] Pomodoro detenido")
    }
    
    func pomodoroPhaseCompleted(phase: String) {
        BusylightLogger.shared.info("[USER] Pomodoro - Fase completada: \(phase)")
    }
    
    func pomodoroConfigChanged(workTime: Int, shortBreak: Int, longBreak: Int, sets: Int) {
        BusylightLogger.shared.info("[USER] Configuración Pomodoro cambiada - Trabajo: \(workTime)m, Descanso corto: \(shortBreak)m, Descanso largo: \(longBreak)m, Sets: \(sets)")
    }
    
    // MARK: - Deep Work
    
    func deepWorkStarted(durationMinutes: Int) {
        BusylightLogger.shared.info("[USER] Deep Work iniciado - Duración: \(durationMinutes)min")
    }
    
    func deepWorkEnded(remainingMinutes: Int) {
        BusylightLogger.shared.info("[USER] Deep Work terminado - Minutos restantes: \(remainingMinutes)")
    }
    
    // MARK: - Work Profiles
    
    func profileChanged(to profile: String) {
        BusylightLogger.shared.info("[USER] Perfil de trabajo cambiado a: \(profile)")
    }
    
    // MARK: - Settings
    
    func settingChanged(setting: String, value: String) {
        BusylightLogger.shared.info("[USER] Ajuste cambiado - \(setting): \(value)")
    }
    
    func calendarSyncToggled(enabled: Bool) {
        BusylightLogger.shared.info("[USER] Sincronización de calendario: \(enabled ? "activada" : "desactivada")")
    }
    
    func workHoursChanged(start: Int, end: Int) {
        BusylightLogger.shared.info("[USER] Horario de trabajo cambiado: \(start):00 - \(end):00")
    }
    
    func workHoursToggled(enabled: Bool) {
        BusylightLogger.shared.info("[USER] Horario de trabajo: \(enabled ? "activado" : "desactivado")")
    }
    
    func dockVisibilityChanged(show: Bool) {
        BusylightLogger.shared.info("[USER] Visibilidad en Dock: \(show ? "mostrar" : "ocultar")")
    }
    
    func menuBarVisibilityChanged(show: Bool) {
        BusylightLogger.shared.info("[USER] Visibilidad en Menu Bar: \(show ? "mostrar" : "ocultar")")
    }
    
    // MARK: - ML Features
    
    func mlEnabledToggled(enabled: Bool) {
        BusylightLogger.shared.info("[USER] ML: \(enabled ? "activado" : "desactivado")")
    }
    
    func mlTrainingStarted() {
        BusylightLogger.shared.info("[USER] ML: Entrenamiento iniciado manualmente")
    }
    
    func mlTrainingCompleted(accuracy: Double) {
        BusylightLogger.shared.info("[USER] ML: Entrenamiento completado - Precisión: \(String(format: "%.1f%%", accuracy * 100))")
    }
    
    func mlAutoAdjustToggled(enabled: Bool) {
        BusylightLogger.shared.info("[USER] ML Auto-ajuste: \(enabled ? "activado" : "desactivado")")
    }
    
    func mlDemoDataGenerated() {
        BusylightLogger.shared.info("[USER] ML: Datos de ejemplo generados")
    }
    
    func mlDataCleared() {
        BusylightLogger.shared.info("[USER] ML: Datos eliminados")
    }
    
    // MARK: - Holiday Calendar
    
    func holidayCalendarCreated(name: String, countryCode: String, customDatesCount: Int) {
        BusylightLogger.shared.info("[USER] Calendario de festivos creado: \(name) (\(countryCode)) con \(customDatesCount) fechas personalizadas")
    }
    
    func holidayCalendarDeleted(name: String) {
        BusylightLogger.shared.info("[USER] Calendario de festivos eliminado: \(name)")
    }
    
    func holidayCalendarToggled(name: String, enabled: Bool) {
        BusylightLogger.shared.info("[USER] Calendario de festivos '\(name)': \(enabled ? "activado" : "desactivado")")
    }
    
    func customDateAdded(to calendarName: String, date: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        BusylightLogger.shared.info("[USER] Fecha personalizada agregada a '\(calendarName)': \(formatter.string(from: date))")
    }
    
    func customDateRemoved(from calendarName: String, date: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        BusylightLogger.shared.info("[USER] Fecha personalizada eliminada de '\(calendarName)': \(formatter.string(from: date))")
    }
    
    // MARK: - Teams
    
    func teamsConnectionToggled(connected: Bool) {
        BusylightLogger.shared.info("[USER] Teams: \(connected ? "conectado" : "desconectado")")
    }
    
    func teamsStatusChanged(to status: String) {
        BusylightLogger.shared.info("[USER] Teams estado cambiado a: \(status)")
    }
    
    // MARK: - API/Webhook
    
    func apiServerToggled(enabled: Bool) {
        BusylightLogger.shared.info("[USER] API Server: \(enabled ? "iniciado" : "detenido")")
    }
    
    func apiRequestReceived(endpoint: String, method: String) {
        BusylightLogger.shared.info("[USER/API] Petición recibida: \(method) \(endpoint)")
    }
    
    // MARK: - App Lifecycle
    
    func appLaunched() {
        BusylightLogger.shared.info("[USER] App iniciada")
    }
    
    func appTerminated() {
        BusylightLogger.shared.info("[USER] App terminada")
    }
    
    func windowBroughtToFront() {
        BusylightLogger.shared.info("[USER] Ventana traída al frente desde menu bar")
    }
    
    // MARK: - Detailed UI Interactions
    
    func buttonPressed(_ buttonName: String, in view: String) {
        BusylightLogger.shared.info("[USER/BUTTON] '\(buttonName)' presionado en \(view)")
    }
    
    func optionSelected(_ option: String, from options: String, in view: String) {
        BusylightLogger.shared.info("[USER/OPTION] '\(option)' seleccionado de '\(options)' en \(view)")
    }
    
    func stepperChanged(value: Int, name: String) {
        BusylightLogger.shared.info("[USER/STEPPER] \(name): \(value)")
    }
    
    func toggleChanged(isOn: Bool, name: String) {
        BusylightLogger.shared.info("[USER/TOGGLE] \(name): \(isOn ? "ON" : "OFF")")
    }
    
    func tabChanged(to tab: String, in view: String) {
        BusylightLogger.shared.info("[USER/TAB] Cambio a '\(tab)' en \(view)")
    }
    
    func menuItemSelected(_ item: String, from menu: String) {
        BusylightLogger.shared.info("[USER/MENU] '\(item)' seleccionado de '\(menu)'")
    }
}
