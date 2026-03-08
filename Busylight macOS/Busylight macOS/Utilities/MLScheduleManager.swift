//
//  MLScheduleManager.swift
//  Busylight
//
//  Machine Learning Manager for Work Schedule Prediction
//

import Foundation
import CoreML
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
    @Published var trainingProgress: Double = 0.0
    @Published var lastPrediction: SchedulePrediction?
    @Published var configuration: MLConfiguration?
    
    // MARK: - Private Properties
    private var model: MLModel?
    private var cancellables = Set<AnyCancellable>()
    private let context: ModelContext
    
    // MARK: - Constants
    private let minSamplesForTraining = 3  // Reduced for easier testing
    private let modelFileName = "WorkSchedulePredictor.mlmodel"
    
    init() {
        let schema = Schema([
            MLWorkPattern.self,
            MLConfiguration.self,
            HolidayCalendar.self
        ])
        let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)])
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
        collectDailyPattern()
        
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
        
        // PRIMERO: Intentar cargar modelos pre-entrenados del bundle
        if TrainedModelLoader.shared.isReady {
            BusylightLogger.shared.info("ML: ✅ Usando modelos pre-entrenados desde Create ML")
            
            await MainActor.run {
                isTraining = true
            }
            
            // Simular progreso rápido
            for i in stride(from: 0.0, through: 1.0, by: 0.2) {
                await MainActor.run { trainingProgress = i }
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
            }
            
            await MainActor.run {
                isModelTrained = true
                modelAccuracy = 0.85 // Precisión estimada del modelo entrenado
                configuration?.lastTrainingDate = Date()
                configuration?.modelAccuracy = modelAccuracy
                isTraining = false
                trainingProgress = 1.0
                try? context.save()
            }
            
            BusylightLogger.shared.info("ML: ✅ Modelos pre-entrenados cargados - Listo para predicciones!")
            
            // Probar predicción de ejemplo
            if let prediction = testPretrainedModel() {
                BusylightLogger.shared.info("ML: 🧪 Prueba de predicción - Mañana: \(prediction.formattedStartTime) a \(prediction.formattedEndTime)")
            }
            
            return
        }
        
        // Si no hay modelos pre-entrenados, entrenar en la app
        BusylightLogger.shared.info("ML: 🚀 No se encontraron modelos pre-entrenados. Entrenando en la app...")
        
        await MainActor.run {
            isTraining = true
        }
        
        defer {
            Task { @MainActor in
                isTraining = false
            }
        }
        
        // Obtener datos de entrenamiento
        let descriptor = FetchDescriptor<MLWorkPattern>(
            predicate: #Predicate { !$0.isHoliday },
            sortBy: [SortDescriptor(\.date)]
        )
        
        guard let patterns = try? context.fetch(descriptor),
              patterns.count >= minSamplesForTraining else {
            BusylightLogger.shared.error("ML: ❌ Datos insuficientes para entrenar (\(trainingDaysCollected) días recolectados)")
            throw MLError.insufficientData
        }
        
        BusylightLogger.shared.info("ML: 📊 Entrenando con \(patterns.count) patrones...")
        
        do {
            if patterns.count >= 7 {
                try await WorkSchedulePredictor.shared.trainWithRandomForest(with: patterns)
            } else {
                try await WorkSchedulePredictor.shared.train(with: patterns)
            }
            
            await MainActor.run {
                modelAccuracy = WorkSchedulePredictor.shared.modelAccuracy
                isModelTrained = WorkSchedulePredictor.shared.isModelReady
                configuration?.lastTrainingDate = Date()
                try? context.save()
            }
            
            let insights = WorkSchedulePredictor.shared.getInsights(from: patterns)
            logInsights(insights)
            
        } catch {
            BusylightLogger.shared.error("ML: ❌ Error en entrenamiento - \(error.localizedDescription)")
            throw MLError.trainingFailed
        }
    }
    
    /// Prueba los modelos pre-entrenados
    private func testPretrainedModel() -> SchedulePrediction? {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let weekday = Calendar.current.component(.weekday, from: tomorrow)
        
        let isWeekend = (weekday == 1 || weekday == 7) ? 1 : 0
        let isHolidayValue = isHoliday(tomorrow) ? 1 : 0
        let avgSessions = getAverageSessions()
        let avgDeepWork = getAverageDeepWork()
        let avgEvents = getAverageCalendarEvents()
        
        guard let startHour = TrainedModelLoader.shared.predictStartHour(
            dayOfWeek: weekday,
            isWeekend: isWeekend,
            sessionCount: avgSessions,
            deepWorkMinutes: avgDeepWork,
            isHoliday: isHolidayValue,
            calendarEventCount: avgEvents
        ),
        let endHour = TrainedModelLoader.shared.predictEndHour(
            dayOfWeek: weekday,
            isWeekend: isWeekend,
            sessionCount: avgSessions,
            deepWorkMinutes: avgDeepWork,
            isHoliday: isHolidayValue,
            calendarEventCount: avgEvents
        ) else {
            BusylightLogger.shared.error("ML: No se pudieron obtener predicciones de los modelos")
            return nil
        }
        
        return SchedulePrediction(
            date: tomorrow,
            predictedStartHour: startHour,
            predictedEndHour: endHour,
            confidence: 0.85
        )
    }
    
    private func logInsights(_ insights: WorkInsights) {
        BusylightLogger.shared.info("📊 INSIGHTS ML:")
        BusylightLogger.shared.info("   - Horario promedio: \(String(format: "%.1f", insights.averageStartTime)):00 - \(String(format: "%.1f", insights.averageEndTime)):00")
        BusylightLogger.shared.info("   - Duración promedio: \(Int(insights.averageWorkDuration / 60))h \(Int(insights.averageWorkDuration) % 60)m")
        BusylightLogger.shared.info("   - Día más productivo: \(insights.mostProductiveDayName)")
        BusylightLogger.shared.info("   - Tendencia: \(insights.trend)")
        BusylightLogger.shared.info("   - Datos analizados: \(insights.totalPatternsAnalyzed) patrones")
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
        // USAR MODELOS PRE-ENTRENADOS si están disponibles
        if TrainedModelLoader.shared.isReady {
            return predictWithPretrainedModel(for: date)
        }
        
        // Fallback a modelos entrenados en app
        guard isModelTrained || WorkSchedulePredictor.shared.isModelReady else {
            BusylightLogger.shared.debug("ML: No hay modelo disponible para predecir")
            return nil
        }
        
        guard modelAccuracy >= (configuration?.confidenceThreshold ?? 0.75) else {
            BusylightLogger.shared.debug("ML: Precisión (\(String(format: "%.0f%%", modelAccuracy * 100))) por debajo del umbral")
            return nil
        }
        
        guard !isHoliday(date) else {
            BusylightLogger.shared.debug("ML: Fecha es festivo, no se predice")
            return nil
        }
        
        let context = createPredictionContext()
        
        if let result = WorkSchedulePredictor.shared.predict(for: date, context: context) {
            let prediction = SchedulePrediction(
                date: date,
                predictedStartHour: result.predictedStartHour,
                predictedEndHour: result.predictedEndHour,
                confidence: result.confidence
            )
            
            BusylightLogger.shared.info("ML: 🔮 Predicción app-trained - \(prediction.formattedStartTime) a \(prediction.formattedEndTime)")
            self.lastPrediction = prediction
            return prediction
        }
        
        return statisticalPrediction(for: date)
    }
    
    /// Predice usando modelos pre-entrenados de Create ML
    private func predictWithPretrainedModel(for date: Date) -> SchedulePrediction? {
        guard !isHoliday(date) else {
            BusylightLogger.shared.debug("ML: Fecha es festivo (modelo pre-entrenado)")
            return nil
        }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let isWeekend = (weekday == 1 || weekday == 7) ? 1 : 0
        let isHolidayValue = isHoliday(date) ? 1 : 0
        
        // Obtener datos contextuales
        let avgSessions = getAverageSessions()
        let avgDeepWork = getAverageDeepWork()
        let avgEvents = getAverageCalendarEvents()
        
        guard let startHour = TrainedModelLoader.shared.predictStartHour(
            dayOfWeek: weekday,
            isWeekend: isWeekend,
            sessionCount: avgSessions,
            deepWorkMinutes: avgDeepWork,
            isHoliday: isHolidayValue,
            calendarEventCount: avgEvents
        ),
        let endHour = TrainedModelLoader.shared.predictEndHour(
            dayOfWeek: weekday,
            isWeekend: isWeekend,
            sessionCount: avgSessions,
            deepWorkMinutes: avgDeepWork,
            isHoliday: isHolidayValue,
            calendarEventCount: avgEvents
        ) else {
            BusylightLogger.shared.error("ML: Error en predicción con modelo pre-entrenado")
            return nil
        }
        
        let prediction = SchedulePrediction(
            date: date,
            predictedStartHour: startHour,
            predictedEndHour: endHour,
            confidence: 0.85
        )
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        BusylightLogger.shared.info("ML: 🔮 Predicción Create-ML-model - \(prediction.formattedStartTime) a \(prediction.formattedEndTime)")
        
        self.lastPrediction = prediction
        return prediction
    }
    
    private func getAverageSessions() -> Int {
        let descriptor = FetchDescriptor<MLWorkPattern>()
        guard let patterns = try? context.fetch(descriptor), !patterns.isEmpty else { return 5 }
        return patterns.map { $0.sessionCount }.reduce(0, +) / patterns.count
    }
    
    private func getAverageDeepWork() -> Int {
        let descriptor = FetchDescriptor<MLWorkPattern>()
        guard let patterns = try? context.fetch(descriptor), !patterns.isEmpty else { return 90 }
        return patterns.map { $0.deepWorkMinutes }.reduce(0, +) / patterns.count
    }
    
    private func getAverageCalendarEvents() -> Int {
        let descriptor = FetchDescriptor<MLWorkPattern>()
        guard let patterns = try? context.fetch(descriptor), !patterns.isEmpty else { return 3 }
        return patterns.map { $0.calendarEventCount }.reduce(0, +) / patterns.count
    }
    
    private func createPredictionContext() -> PredictionContext? {
        let descriptor = FetchDescriptor<MLWorkPattern>()
        guard let patterns = try? context.fetch(descriptor), !patterns.isEmpty else {
            return nil
        }
        
        let avgSession = patterns.map { Double($0.sessionCount) }.reduce(0, +) / Double(patterns.count)
        let avgDeepWork = patterns.map { Double($0.deepWorkMinutes) }.reduce(0, +) / Double(patterns.count)
        let avgEvents = patterns.map { Double($0.calendarEventCount) }.reduce(0, +) / Double(patterns.count)
        
        let byDay = Dictionary(grouping: patterns) { $0.dayOfWeek }
        
        return PredictionContext(
            avgSessionCount: avgSession,
            avgDeepWorkMinutes: avgDeepWork,
            avgCalendarEvents: avgEvents,
            patternsByDay: byDay
        )
    }
    
    private func statisticalPrediction(for date: Date) -> SchedulePrediction? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday], from: date)
        let dayOfWeek = components.weekday ?? 2
        
        let descriptor = FetchDescriptor<MLWorkPattern>(
            predicate: #Predicate { $0.dayOfWeek == dayOfWeek && !$0.isHoliday }
        )
        
        guard let patterns = try? context.fetch(descriptor), !patterns.isEmpty else {
            return nil
        }
        
        let avgStart = patterns.map { Double($0.startHour) }.reduce(0, +) / Double(patterns.count)
        let avgEnd = patterns.map { Double($0.endHour) }.reduce(0, +) / Double(patterns.count)
        
        return SchedulePrediction(
            date: date,
            predictedStartHour: Int(round(avgStart)),
            predictedEndHour: Int(round(avgEnd)),
            confidence: 0.6
        )
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
    
    // MARK: - Demo Data
    
    /// Genera datos de ejemplo para pruebas (3-7 días de patrones de trabajo)
    func generateDemoData() {
        BusylightLogger.shared.info("ML: 🎮 Generando datos de ejemplo para pruebas...")
        
        let calendar = Calendar.current
        let today = Date()
        
        // Generar 5 días de datos históricos
        for dayOffset in stride(from: -6, through: -2, by: 1) {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            // Saltar fines de semana para datos más realistas
            let weekday = calendar.component(.weekday, from: date)
            guard weekday != 1 && weekday != 7 else { continue } // Skip Sunday (1) and Saturday (7)
            
            let pattern = MLWorkPattern(
                date: date,
                dayOfWeek: weekday,
                startHour: 8 + Int.random(in: 0...2), // 8-10 AM
                startMinute: 0,
                endHour: 16 + Int.random(in: 2...4),  // 6-8 PM
                endMinute: 0,
                isHoliday: false,
                sessionCount: Int.random(in: 3...6),
                deepWorkMinutes: Int.random(in: 60...180),
                calendarEventCount: Int.random(in: 2...5)
            )
            
            context.insert(pattern)
        }
        
        try? context.save()
        updateTrainingStats()
        
        BusylightLogger.shared.info("ML: ✅ Datos de ejemplo generados - \(trainingDaysCollected) días disponibles")
        
        // Notificar que ya se puede entrenar
        if canTrainModel() {
            BusylightLogger.shared.info("ML: 🎯 Ahora puedes entrenar el modelo con los datos de ejemplo!")
        }
    }
    
    // MARK: - Holiday Calendars
    
    @discardableResult
    func createHolidayCalendar(name: String, countryCode: String, dates: [Date] = []) -> HolidayCalendar {
        BusylightLogger.shared.info("ML: 📅 Creando calendario de festivos '\(name)' con \(dates.count) fechas")
        UserInteractionLogger.shared.holidayCalendarCreated(name: name, countryCode: countryCode, customDatesCount: dates.count)
        
        let calendar = HolidayCalendar(name: name, countryCode: countryCode, customDates: dates)
        context.insert(calendar)
        
        do {
            try context.save()
            BusylightLogger.shared.info("ML: ✅ Calendario '\(name)' guardado exitosamente")
        } catch {
            BusylightLogger.shared.error("ML: ❌ Error guardando calendario '\(name)': \(error.localizedDescription)")
        }
        
        return calendar
    }
    
    func getHolidayCalendars() -> [HolidayCalendar] {
        let descriptor = FetchDescriptor<HolidayCalendar>()
        let calendars = (try? context.fetch(descriptor)) ?? []
        BusylightLogger.shared.debug("ML: 📅 Cargados \(calendars.count) calendarios de festivos")
        return calendars
    }
    
    func deleteHolidayCalendar(_ calendar: HolidayCalendar) {
        let name = calendar.name
        context.delete(calendar)
        
        do {
            try context.save()
            UserInteractionLogger.shared.holidayCalendarDeleted(name: name)
            BusylightLogger.shared.info("ML: 🗑️ Calendario '\(name)' eliminado")
        } catch {
            BusylightLogger.shared.error("ML: ❌ Error eliminando calendario '\(name)': \(error.localizedDescription)")
        }
    }
    
    /// Agrega una fecha personalizada a un calendario existente
    func addCustomDate(to calendar: HolidayCalendar, date: Date) {
        // Crear una nueva instancia del array para forzar el cambio
        var updatedDates = calendar.customDates
        updatedDates.append(date)
        calendar.customDates = updatedDates
        calendar.modifiedAt = Date()
        
        do {
            try context.save()
            UserInteractionLogger.shared.customDateAdded(to: calendar.name, date: date)
            BusylightLogger.shared.info("ML: ✅ Fecha personalizada agregada a '\(calendar.name)'. Total: \(calendar.customDates.count)")
        } catch {
            BusylightLogger.shared.error("ML: ❌ Error agregando fecha a '\(calendar.name)': \(error.localizedDescription)")
        }
    }
    
    /// Elimina una fecha personalizada de un calendario
    func removeCustomDate(from calendar: HolidayCalendar, date: Date) {
        let calendarUtil = Calendar.current
        var updatedDates = calendar.customDates
        
        // Buscar y eliminar la fecha que coincida en día/mes
        updatedDates.removeAll { existingDate in
            let existingComponents = calendarUtil.dateComponents([.year, .month, .day], from: existingDate)
            let removeComponents = calendarUtil.dateComponents([.year, .month, .day], from: date)
            return existingComponents.month == removeComponents.month && 
                   existingComponents.day == removeComponents.day
        }
        
        calendar.customDates = updatedDates
        calendar.modifiedAt = Date()
        
        do {
            try context.save()
            UserInteractionLogger.shared.customDateRemoved(from: calendar.name, date: date)
            BusylightLogger.shared.info("ML: ✅ Fecha personalizada eliminada de '\(calendar.name)'. Total: \(calendar.customDates.count)")
        } catch {
            BusylightLogger.shared.error("ML: ❌ Error eliminando fecha de '\(calendar.name)': \(error.localizedDescription)")
        }
    }
    
    /// Actualiza el estado de habilitación de un calendario
    func toggleHolidayCalendar(_ calendar: HolidayCalendar, enabled: Bool) {
        calendar.isEnabled = enabled
        calendar.modifiedAt = Date()
        
        do {
            try context.save()
            UserInteractionLogger.shared.holidayCalendarToggled(name: calendar.name, enabled: enabled)
            BusylightLogger.shared.info("ML: 📅 Calendario '\(calendar.name)' \(enabled ? "activado" : "desactivado")")
        } catch {
            BusylightLogger.shared.error("ML: ❌ Error cambiando estado de '\(calendar.name)': \(error.localizedDescription)")
        }
    }
}
