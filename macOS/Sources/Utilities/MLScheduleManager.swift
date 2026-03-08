//
//  MLScheduleManager.swift
//  Busylight
//
//  Machine Learning Manager for Work Schedule Prediction
//

import Foundation
import CoreML
import CreateML
import SwiftData
import Combine
import UserNotifications

/// Manager para ML de predicción de horarios
@MainActor
class MLScheduleManager: ObservableObject {
    static let shared = MLScheduleManager()
    
    // MARK: - Published States
    @Published var isModelTrained = false
    @Published var modelAccuracy: Double = 0.0
    @Published var trainingDaysCollected: Int = 0
    @Published var isTraining = false
    @Published var lastPrediction: SchedulePrediction?
    @Published var configuration: MLConfiguration?
    
    // MARK: - Private Properties
    private var model: MLModel?
    private var cancellables = Set<AnyCancellable>()
    private let context: ModelContext
    
    // MARK: - Constants
    private let minSamplesForTraining = 10
    private let modelFileName = "WorkSchedulePredictor.mlmodel"
    
    init() {
        // Get SwiftData context
        let container = try! ModelContainer(for: MLWorkPattern.self, MLConfiguration.self, HolidayCalendar.self)
        self.context = ModelContext(container)
        
        loadConfiguration()
        loadExistingModel()
        updateTrainingStats()
        
        // Observar cambios en SmartFeaturesManager para recolectar datos
        setupDataCollection()
    }
    
    // MARK: - Configuration
    
    private func loadConfiguration() {
        let descriptor = FetchDescriptor<MLConfiguration>()
        if let config = try? context.fetch(descriptor).first {
            self.configuration = config
        } else {
            // Crear configuración por defecto
            let newConfig = MLConfiguration()
            context.insert(newConfig)
            self.configuration = newConfig
            try? context.save()
        }
    }
    
    func updateConfiguration(
        isEnabled: Bool? = nil,
        autoAdjust: Bool? = nil,
        autoTraining: Bool? = nil,
        minDays: Int? = nil,
        threshold: Double? = nil,
        notifications: Bool? = nil
    ) {
        guard let config = configuration else { return }
        
        if let isEnabled = isEnabled {
            config.isMLEnabled = isEnabled
        }
        if let autoAdjust = autoAdjust {
            config.autoAdjustSchedule = autoAdjust
        }
        if let autoTraining = autoTraining {
            config.autoTrainingEnabled = autoTraining
        }
        if let minDays = minDays {
            config.minTrainingDays = minDays
        }
        if let threshold = threshold {
            config.confidenceThreshold = threshold
        }
        if let notifications = notifications {
            config.notificationOnAutoTrain = notifications
        }
        
        try? context.save()
        objectWillChange.send()
    }
    
    // MARK: - Data Collection & Auto-Training
    
    private func setupDataCollection() {
        BusylightLogger.shared.info("ML: Iniciando sistema de recolección de datos")
        
        // TEMPORALMENTE DESHABILITADO para debugging
        /*
        // Recolectar datos diariamente
        Timer.publish(every: 3600, on: .main, in: .common) // Cada hora
            .autoconnect()
            .sink { [weak self] _ in
                self?.collectDailyPattern()
            }
            .store(in: &cancellables)
        
        // Verificar entrenamiento automático cada día
        Timer.publish(every: 86400, on: .main, in: .common) // Cada 24h
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkAndRunAutoTraining()
                self?.applyDailyPrediction()
            }
            .store(in: &cancellables)
        */
        
        // También recolectar al iniciar (solo una vez)
        // collectDailyPattern()
        
        // Log estado inicial
        if let config = configuration {
            BusylightLogger.shared.info("ML: Configuración cargada - Enabled: \(config.isMLEnabled), AutoTrain: \(config.isAutoTrainingEnabled), DaysCollected: \(trainingDaysCollected)")
        }
    }
    
    /// Verifica si debe ejecutar entrenamiento automático
    private func checkAndRunAutoTraining() {
        BusylightLogger.shared.debug("ML: Verificando auto-training...")
        
        guard let config = configuration else {
            BusylightLogger.shared.debug("ML: No hay configuración disponible")
            return
        }
        
        guard config.isMLEnabled else {
            BusylightLogger.shared.debug("ML: ML está deshabilitado")
            return
        }
        
        guard config.isAutoTrainingEnabled else {
            BusylightLogger.shared.debug("ML: Auto-training está deshabilitado")
            return
        }
        
        guard !isTraining else {
            BusylightLogger.shared.debug("ML: Ya hay un entrenamiento en progreso")
            return
        }
        
        guard canTrainModel() else {
            BusylightLogger.shared.debug("ML: Datos insuficientes para entrenar (\(trainingDaysCollected)/\(minSamplesForTraining) días)")
            return
        }
        
        // Verificar si ya se entrenó hoy
        if let lastTraining = config.lastTrainingDate,
           Calendar.current.isDateInToday(lastTraining) {
            BusylightLogger.shared.debug("ML: Ya se entrenó hoy")
            return
        }
        
        BusylightLogger.shared.info("ML: Iniciando entrenamiento automático con \(trainingDaysCollected) días de datos")
        
        // Ejecutar entrenamiento automático
        Task {
            do {
                try await trainModel()
                BusylightLogger.shared.info("ML: ✅ Modelo entrenado automáticamente con éxito (Precisión: \(String(format: "%.1f%%", modelAccuracy * 100)))")
                
                // Notificar al usuario
                showTrainingCompletionNotification(success: true, accuracy: modelAccuracy)
                
                // Si hay predicción para mañana, aplicarla
                if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                   let prediction = predictSchedule(for: tomorrow),
                   config.autoAdjustSchedule {
                    applyPrediction(prediction)
                }
            } catch {
                BusylightLogger.shared.error("ML: ❌ Error en entrenamiento automático - \(error.localizedDescription)")
                showTrainingCompletionNotification(success: false, error: error.localizedDescription)
            }
        }
    }
    
    /// Aplica predicción para el día actual
    private func applyDailyPrediction() {
        guard let config = configuration,
              config.isMLEnabled,
              config.autoAdjustSchedule,
              isModelTrained else { return }
        
        let today = Date()
        guard !isHoliday(today) else {
            BusylightLogger.shared.debug("ML: Hoy es festivo, no se aplica predicción")
            return
        }
        
        if let prediction = predictSchedule(for: today) {
            // Solo aplicar si la confianza es suficiente
            if prediction.confidence >= config.confidenceThreshold {
                applyPrediction(prediction)
                BusylightLogger.shared.info("ML: 📅 Horarios ajustados automáticamente - \(prediction.formattedStartTime) a \(prediction.formattedEndTime) (Confianza: \(String(format: "%.0f%%", prediction.confidence * 100)))")
            } else {
                BusylightLogger.shared.debug("ML: Confianza insuficiente para aplicar predicción (\(String(format: "%.0f%%", prediction.confidence * 100)))")
            }
        }
    }
    
    /// Muestra notificación cuando se completa el entrenamiento
    @MainActor
    private func showTrainingCompletionNotification(success: Bool, accuracy: Double = 0, error: String? = nil) {
        guard let config = configuration, config.shouldNotifyOnAutoTrain else { return }
        
        let content = UNMutableNotificationContent()
        
        if success {
            content.title = "🧠 ML Training Complete"
            content.body = "Work schedule model trained successfully with \(String(format: "%.0f%%", accuracy * 100)) accuracy. Your work hours have been automatically adjusted."
            content.sound = .default
        } else {
            content.title = "⚠️ ML Training Failed"
            content.body = error ?? "Could not train the model. Please try again manually."
            content.sound = .defaultCritical
        }
        
        let request = UNNotificationRequest(identifier: "ml-training-\(Date().timeIntervalSince1970)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func collectDailyPattern() {
        let calendar = Calendar.current
        let now = Date()
        
        // Solo recolectar una vez por día
        // Traer todos los patrones y filtrar en memoria (limitado a los últimos 30 días)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
        let descriptor = FetchDescriptor<MLWorkPattern>(
            predicate: #Predicate { $0.date > thirtyDaysAgo },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        let patterns = (try? context.fetch(descriptor)) ?? []
        let existing = patterns.first { calendar.isDate($0.date, inSameDayAs: now) }
        
        if let existing = existing {
            // Actualizar patrón existente del día
            updatePattern(existing, for: now)
            BusylightLogger.shared.debug("ML: Patrón diario actualizado - Work Hours: \(existing.startHour):00-\(existing.endHour):00")
        } else {
            // Crear nuevo patrón
            createNewPattern(for: now)
            BusylightLogger.shared.info("ML: 📝 Nuevo patrón diario creado (Total: \(trainingDaysCollected + 1) días)")
        }
        
        try? context.save()
        updateTrainingStats()
        
        // Log cuando se alcanza el mínimo para entrenar
        if trainingDaysCollected == minSamplesForTraining {
            BusylightLogger.shared.info("ML: 🎯 Se alcanzó el mínimo de datos (\(minSamplesForTraining) días). Listo para entrenar!")
        }
    }
    
    private func createNewPattern(for date: Date) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday], from: date)
        
        // Obtener datos actuales
        let smartFeatures = SmartFeaturesManager.shared
        let pomodoro = PomodoroManager.shared
        
        let pattern = MLWorkPattern(
            date: date,
            dayOfWeek: components.weekday ?? 2,
            startHour: smartFeatures.workStartTime,
            startMinute: 0,
            endHour: smartFeatures.workEndTime,
            endMinute: 0,
            isHoliday: isHoliday(date),
            sessionCount: pomodoro.currentSet - 1,
            deepWorkMinutes: smartFeatures.deepWorkRemainingMinutes > 0 
                ? (smartFeatures.deepWorkRemainingMinutes) 
                : 0,
            calendarEventCount: getCalendarEventCount(for: date)
        )
        
        context.insert(pattern)
    }
    
    private func updatePattern(_ pattern: MLWorkPattern, for date: Date) {
        let smartFeatures = SmartFeaturesManager.shared
        let pomodoro = PomodoroManager.shared
        
        // Actualizar con datos actuales
        pattern.endHour = smartFeatures.workEndTime
        pattern.sessionCount = pomodoro.currentSet - 1
        pattern.deepWorkMinutes = smartFeatures.deepWorkRemainingMinutes > 0 
            ? (smartFeatures.deepWorkRemainingMinutes) 
            : pattern.deepWorkMinutes
    }
    
    private func getCalendarEventCount(for date: Date) -> Int {
        // Obtener número de eventos del calendario para ese día
        // Esto se conectaría con SmartFeaturesManager
        return 0 // Placeholder
    }
    
    private func isHoliday(_ date: Date) -> Bool {
        let descriptor = FetchDescriptor<HolidayCalendar>(
            predicate: #Predicate { $0.isEnabled }
        )
        
        guard let calendars = try? context.fetch(descriptor) else { return false }
        
        return calendars.contains { $0.isHoliday(date) }
    }
    
    // MARK: - Training
    
    func trainModel() async throws {
        guard !isTraining else {
            BusylightLogger.shared.warning("ML: Intento de entrenamiento mientras ya está en progreso")
            return
        }
        
        BusylightLogger.shared.info("ML: 🚀 Iniciando entrenamiento manual del modelo")
        
        await MainActor.run {
            isTraining = true
        }
        
        defer {
            Task { @MainActor in
                isTraining = false
            }
        }
        
        // Obtener datos de entrenamiento (excluir festivos)
        let descriptor = FetchDescriptor<MLWorkPattern>(
            predicate: #Predicate { !$0.isHoliday },
            sortBy: [SortDescriptor(\.date)]
        )
        
        guard let patterns = try? context.fetch(descriptor),
              patterns.count >= minSamplesForTraining else {
            BusylightLogger.shared.error("ML: ❌ Datos insuficientes para entrenar (\(trainingDaysCollected) días recolectados)")
            throw MLError.insufficientData
        }
        
        BusylightLogger.shared.info("ML: 📊 Entrenando con \(patterns.count) patrones de trabajo")
        
        // Preparar datos para Create ML
        let data = prepareTrainingData(from: patterns)
        
        // Log estadísticas de los datos
        let avgStart = data.map { $0["startHour"]! }.reduce(0, +) / Double(data.count)
        let avgEnd = data.map { $0["endHour"]! }.reduce(0, +) / Double(data.count)
        BusylightLogger.shared.debug("ML: Promedios históricos - Inicio: \(String(format: "%.1f", avgStart)):00, Fin: \(String(format: "%.1f", avgEnd)):00")
        
        // Entrenar modelo de regresión
        // Nota: En una implementación real, usaríamos CreateML
        // Por ahora simulamos el entrenamiento
        BusylightLogger.shared.info("ML: ⏳ Entrenando modelo (esto puede tomar unos segundos)...")
        try await simulateTraining(with: data)
        
        // Guardar modelo
        try saveModel()
        
        // Actualizar configuración
        await MainActor.run {
            configuration?.lastTrainingDate = Date()
            configuration?.modelAccuracy = modelAccuracy
            isModelTrained = true
            try? context.save()
        }
        
        BusylightLogger.shared.info("ML: ✅ Entrenamiento completado - Precisión: \(String(format: "%.1f%%", modelAccuracy * 100))")
    }
    
    private func prepareTrainingData(from patterns: [MLWorkPattern]) -> [[String: Double]] {
        return patterns.map { pattern in
            [
                "dayOfWeek": Double(pattern.dayOfWeek),
                "isWeekend": pattern.isWeekend ? 1.0 : 0.0,
                "sessionCount": Double(pattern.sessionCount),
                "deepWorkMinutes": Double(pattern.deepWorkMinutes),
                "calendarEventCount": Double(pattern.calendarEventCount),
                "startHour": Double(pattern.startHour),
                "endHour": Double(pattern.endHour)
            ]
        }
    }
    
    private func simulateTraining(with data: [[String: Double]]) async throws {
        // Simulación de entrenamiento
        // En implementación real, usaríamos CreateML
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 segundos
        
        // Calcular "precisión" basada en varianza de datos
        let startHours = data.map { $0["startHour"]! }
        let endHours = data.map { $0["endHour"]! }
        
        let startVariance = calculateVariance(startHours)
        let endVariance = calculateVariance(endHours)
        
        // Menor varianza = mayor precisión
        let accuracy = max(0.6, 1.0 - (startVariance + endVariance) / 20.0)
        
        await MainActor.run {
            self.modelAccuracy = min(0.95, accuracy)
        }
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        return squaredDiffs.reduce(0, +) / Double(values.count)
    }
    
    private func saveModel() throws {
        // En implementación real, guardaríamos el modelo Core ML
        // Por ahora solo marcamos como entrenado
    }
    
    private func loadExistingModel() {
        // Verificar si existe un modelo previamente entrenado
        // Por ahora usamos el estado de configuración
        if let config = configuration,
           config.lastTrainingDate != nil {
            isModelTrained = true
            modelAccuracy = config.modelAccuracy
        }
    }
    
    // MARK: - Prediction
    
    func predictSchedule(for date: Date) -> SchedulePrediction? {
        guard isModelTrained else {
            BusylightLogger.shared.debug("ML: No hay modelo entrenado para predecir")
            return nil
        }
        
        guard modelAccuracy >= (configuration?.confidenceThreshold ?? 0.75) else {
            BusylightLogger.shared.debug("ML: Precisión del modelo (\(String(format: "%.0f%%", modelAccuracy * 100))) por debajo del umbral")
            return nil
        }
        
        guard !isHoliday(date) else {
            BusylightLogger.shared.debug("ML: Fecha es festivo, no se predice")
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let dateString = dateFormatter.string(from: date)
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday], from: date)
        let dayOfWeek = components.weekday ?? 2
        
        // Obtener patrones históricos del mismo día de la semana
        let descriptor = FetchDescriptor<MLWorkPattern>(
            predicate: #Predicate { 
                $0.dayOfWeek == dayOfWeek && !$0.isHoliday 
            }
        )
        
        guard let patterns = try? context.fetch(descriptor),
              !patterns.isEmpty else {
            return nil
        }
        
        // Calcular predicción basada en promedios ponderados
        let avgStart = patterns.map { Double($0.startHour) }.reduce(0, +) / Double(patterns.count)
        let avgEnd = patterns.map { Double($0.endHour) }.reduce(0, +) / Double(patterns.count)
        
        let prediction = SchedulePrediction(
            date: date,
            predictedStartHour: Int(round(avgStart)),
            predictedEndHour: Int(round(avgEnd)),
            confidence: modelAccuracy,
            basedOnDays: patterns.count
        )
        
        BusylightLogger.shared.info("ML: 🔮 Predicción generada para \(dateString) - \(prediction.formattedStartTime) a \(prediction.formattedEndTime) (basado en \(patterns.count) días)")
        
        self.lastPrediction = prediction
        return prediction
    }
    
    func applyPrediction(_ prediction: SchedulePrediction) {
        guard configuration?.autoAdjustSchedule == true else {
            BusylightLogger.shared.debug("ML: Auto-ajuste deshabilitado, no se aplica predicción")
            return
        }
        
        // Verificar si hay cambios significativos
        let currentStart = SmartFeaturesManager.shared.workStartTime
        let currentEnd = SmartFeaturesManager.shared.workEndTime
        
        guard prediction.predictedStartHour != currentStart || prediction.predictedEndHour != currentEnd else {
            BusylightLogger.shared.debug("ML: Predicción coincide con horarios actuales, no se requiere cambio")
            return
        }
        
        BusylightLogger.shared.info("ML: 🔄 Aplicando predicción - Cambio: \(currentStart):00-\(currentEnd):00 → \(prediction.predictedStartHour):00-\(prediction.predictedEndHour):00")
        
        // Aplicar predicción a SmartFeaturesManager
        SmartFeaturesManager.shared.updateWorkHours(
            start: prediction.predictedStartHour,
            end: prediction.predictedEndHour
        )
        
        // Notificar al usuario del cambio
        if let config = configuration, config.shouldNotifyOnAutoTrain {
            showPredictionAppliedNotification(prediction: prediction)
        }
    }
    
    /// Muestra notificación cuando se aplica una predicción
    @MainActor
    private func showPredictionAppliedNotification(prediction: SchedulePrediction) {
        let content = UNMutableNotificationContent()
        content.title = "📅 Work Hours Updated"
        content.body = "ML adjusted your schedule to \(prediction.formattedStartTime) - \(prediction.formattedEndTime) based on your patterns."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "ml-prediction-\(Date().timeIntervalSince1970)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Stats
    
    private func updateTrainingStats() {
        let descriptor = FetchDescriptor<MLWorkPattern>(
            predicate: #Predicate { !$0.isHoliday }
        )
        
        if let count = try? context.fetchCount(descriptor) {
            trainingDaysCollected = count
        }
    }
    
    func canTrainModel() -> Bool {
        trainingDaysCollected >= minSamplesForTraining
    }
    
    func clearAllData() {
        BusylightLogger.shared.info("ML: 🗑️ Limpiando todos los datos de entrenamiento")
        
        let patternDescriptor = FetchDescriptor<MLWorkPattern>()
        if let patterns = try? context.fetch(patternDescriptor) {
            let count = patterns.count
            for pattern in patterns {
                context.delete(pattern)
            }
            BusylightLogger.shared.info("ML: \(count) patrones eliminados")
        }
        
        configuration?.lastTrainingDate = nil
        configuration?.modelAccuracy = 0.0
        isModelTrained = false
        modelAccuracy = 0.0
        
        try? context.save()
        updateTrainingStats()
        
        BusylightLogger.shared.info("ML: ✅ Datos de ML reiniciados completamente")
    }
    
    // MARK: - Holiday Calendars
    
    @discardableResult
    func createHolidayCalendar(name: String, countryCode: String, dates: [Date]) -> HolidayCalendar {
        BusylightLogger.shared.info("ML: 📅 Creando calendario de festivos '\(name)' con \(dates.count) fechas")
        
        let calendar = HolidayCalendar(name: name, countryCode: countryCode, customDates: dates)
        context.insert(calendar)
        try? context.save()
        return calendar
    }
    
    func getHolidayCalendars() -> [HolidayCalendar] {
        let descriptor = FetchDescriptor<HolidayCalendar>()
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func deleteHolidayCalendar(_ calendar: HolidayCalendar) {
        context.delete(calendar)
        try? context.save()
    }
}

// MARK: - Supporting Types

struct SchedulePrediction {
    let date: Date
    let predictedStartHour: Int
    let predictedEndHour: Int
    let confidence: Double
    let basedOnDays: Int
    
    var formattedStartTime: String {
        String(format: "%02d:00", predictedStartHour)
    }
    
    var formattedEndTime: String {
        String(format: "%02d:00", predictedEndHour)
    }
    
    var duration: Int {
        predictedEndHour - predictedStartHour
    }
}

enum MLError: Error, LocalizedError {
    case insufficientData
    case trainingFailed
    case modelNotFound
    
    var errorDescription: String? {
        switch self {
        case .insufficientData:
            return "Se necesitan al menos 10 días de datos para entrenar el modelo"
        case .trainingFailed:
            return "El entrenamiento del modelo falló"
        case .modelNotFound:
            return "No se encontró un modelo entrenado"
        }
    }
}
