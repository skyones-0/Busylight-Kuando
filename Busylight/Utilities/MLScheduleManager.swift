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
        minDays: Int? = nil,
        threshold: Double? = nil
    ) {
        guard let config = configuration else { return }
        
        if let isEnabled = isEnabled {
            config.isMLEnabled = isEnabled
        }
        if let autoAdjust = autoAdjust {
            config.autoAdjustSchedule = autoAdjust
        }
        if let minDays = minDays {
            config.minTrainingDays = minDays
        }
        if let threshold = threshold {
            config.confidenceThreshold = threshold
        }
        
        try? context.save()
        objectWillChange.send()
    }
    
    // MARK: - Data Collection
    
    private func setupDataCollection() {
        // Recolectar datos diariamente
        Timer.publish(every: 3600, on: .main, in: .common) // Cada hora
            .autoconnect()
            .sink { [weak self] _ in
                self?.collectDailyPattern()
            }
            .store(in: &cancellables)
        
        // También recolectar al iniciar
        collectDailyPattern()
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
        } else {
            // Crear nuevo patrón
            createNewPattern(for: now)
        }
        
        try? context.save()
        updateTrainingStats()
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
        guard !isTraining else { return }
        
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
            throw MLError.insufficientData
        }
        
        // Preparar datos para Create ML
        let data = prepareTrainingData(from: patterns)
        
        // Entrenar modelo de regresión
        // Nota: En una implementación real, usaríamos CreateML
        // Por ahora simulamos el entrenamiento
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
        guard isModelTrained,
              modelAccuracy >= (configuration?.confidenceThreshold ?? 0.75),
              !isHoliday(date) else {
            return nil
        }
        
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
        
        self.lastPrediction = prediction
        return prediction
    }
    
    func applyPrediction(_ prediction: SchedulePrediction) {
        guard configuration?.autoAdjustSchedule == true else { return }
        
        // Aplicar predicción a SmartFeaturesManager
        SmartFeaturesManager.shared.updateWorkHours(
            start: prediction.predictedStartHour,
            end: prediction.predictedEndHour
        )
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
        let patternDescriptor = FetchDescriptor<MLWorkPattern>()
        if let patterns = try? context.fetch(patternDescriptor) {
            for pattern in patterns {
                context.delete(pattern)
            }
        }
        
        configuration?.lastTrainingDate = nil
        configuration?.modelAccuracy = 0.0
        isModelTrained = false
        modelAccuracy = 0.0
        
        try? context.save()
        updateTrainingStats()
    }
    
    // MARK: - Holiday Calendars
    
    func createHolidayCalendar(name: String, countryCode: String, dates: [Date]) -> HolidayCalendar {
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
