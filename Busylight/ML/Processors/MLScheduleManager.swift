//
//  MLScheduleManager.swift
//  Busylight
//
//  Manager principal para Machine Learning - Predicción de categorías de día
//

import Foundation
import SwiftData
import Combine

// MARK: - Modelos de Datos

/// Configuración del sistema ML
@Model
class MLConfiguration {
    @Attribute(.unique) var id: UUID
    var isMLEnabled: Bool
    var notificationOnAutoTrain: Bool
    var lastTrainingDate: Date?
    var modelAccuracy: Double
    
    init() {
        self.id = UUID()
        self.isMLEnabled = true
        self.notificationOnAutoTrain = true
        self.modelAccuracy = 0.0
    }
}

/// Patrón de trabajo diario para ML
@Model
class MLWorkPattern {
    @Attribute(.unique) var id: UUID
    var date: Date
    var dayOfWeek: Int
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var isHoliday: Bool
    var sessionCount: Int
    var deepWorkMinutes: Int
    var calendarEventCount: Int
    
    var durationMinutes: Int {
        (endHour * 60 + endMinute) - (startHour * 60 + startMinute)
    }
    
    init(date: Date, dayOfWeek: Int, startHour: Int, startMinute: Int,
         endHour: Int, endMinute: Int, isHoliday: Bool, sessionCount: Int,
         deepWorkMinutes: Int, calendarEventCount: Int) {
        self.id = UUID()
        self.date = date
        self.dayOfWeek = dayOfWeek
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.isHoliday = isHoliday
        self.sessionCount = sessionCount
        self.deepWorkMinutes = deepWorkMinutes
        self.calendarEventCount = calendarEventCount
    }
}

/// Calendario de festivos
@Model
class HolidayCalendar {
    @Attribute(.unique) var id: UUID
    var date: Date
    var name: String
    var isEnabled: Bool
    
    init(date: Date, name: String, isEnabled: Bool) {
        self.id = UUID()
        self.date = date
        self.name = name
        self.isEnabled = isEnabled
    }
}

/// Feedback del usuario sobre categorización del día
@Model
class DayCategoryFeedback {
    @Attribute(.unique) var id: UUID
    var date: Date
    var predictedCategory: Int
    var actualCategory: Int
    var wasCorrect: Bool
    var notes: String?
    var timestamp: Date
    
    init(date: Date, predictedCategory: Int, actualCategory: Int, notes: String? = nil) {
        self.id = UUID()
        self.date = date
        self.predictedCategory = predictedCategory
        self.actualCategory = actualCategory
        self.wasCorrect = predictedCategory == actualCategory
        self.notes = notes
        self.timestamp = Date()
    }
}

// MARK: - MLScheduleManager

@MainActor
class MLScheduleManager: ObservableObject {
    static var _shared: MLScheduleManager?
    static var shared: MLScheduleManager {
        if _shared == nil {
            _shared = MLScheduleManager(container: PersistenceController.shared.container)
        }
        return _shared!
    }
    
    // MARK: - Published Properties
    @Published var isModelTrained = false
    @Published var modelAccuracy: Double = 0.0
    @Published var trainingDaysCollected: Int = 0
    @Published var todayCategory: DayCategory?
    @Published var todayConfidence: Double = 0.0
    @Published var configuration: MLConfiguration?
    
    // MARK: - Private Properties
    private var context: ModelContext
    private let minSamplesForTraining = 3
    private var currentDate: Date = Date()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(container: ModelContainer? = nil) {
        // Use provided container or fallback to PersistenceController
        let modelContainer = container ?? PersistenceController.shared.container
        self.context = ModelContext(modelContainer)
        
        loadConfiguration()
        updateTrainingStats()
        
        // Actualización diaria
        Task {
            await dailyUpdateLoop()
        }
    }
    
    /// Reset shared instance (useful for testing or when container changes)
    static func resetShared(container: ModelContainer? = nil) {
        _shared = nil
        _ = shared
    }
    
    // MARK: - Configuration
    
    private func loadConfiguration() {
        let descriptor = FetchDescriptor<MLConfiguration>()
        configuration = (try? context.fetch(descriptor).first) ?? {
            let config = MLConfiguration()
            context.insert(config)
            try? context.save()
            return config
        }()
    }
    
    func updateConfiguration(isEnabled: Bool? = nil, notifications: Bool? = nil) {
        guard let config = configuration else { return }
        if let isEnabled = isEnabled { config.isMLEnabled = isEnabled }
        if let notifications = notifications { config.notificationOnAutoTrain = notifications }
        try? context.save()
        objectWillChange.send()
    }
    
    // MARK: - Daily Updates
    
    private func dailyUpdateLoop() async {
        while true {
            await collectAndPredictToday()
            
            // Esperar hasta la siguiente medianoche
            let now = Date()
            let calendar = Calendar.current
            if let nextMidnight = calendar.nextDate(
                after: now,
                matching: DateComponents(hour: 0, minute: 0, second: 0),
                matchingPolicy: .nextTime
            ) {
                let interval = nextMidnight.timeIntervalSince(now)
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            } else {
                try? await Task.sleep(nanoseconds: 60 * 60 * 1_000_000_000) // 1 hora fallback
            }
        }
    }
    
    private func collectAndPredictToday() async {
        currentDate = Date()
        
        guard configuration?.isMLEnabled == true else { return }
        
        // Predecir categoría del día
        await predictTodayCategory()
    }
    
    // MARK: - Prediction
    
    /// Historial de predicciones para análisis con ML Tensor
    private var predictionHistory: [DayCategoryPrediction] = []
    
    func predictTodayCategory() async {
        // Obtener datos actuales
        let dataCollector = DayDataCollector.shared
        dataCollector.updateMetrics()
        
        let meetings = dataCollector.meetingsToday
        let freeSlots = dataCollector.freeBlocks
        
        // Estimar minutos de reunión (aproximación)
        let estimatedMeetingMinutes = meetings * 45 // 45 min promedio por reunión
        
        // Hacer predicción base
        guard let prediction = await DayCategoryClassifierWrapper.shared.predictToday(
            meetings: meetings,
            totalMeetingMinutes: estimatedMeetingMinutes,
            freeTimeSlots: freeSlots
        ) else {
            BusylightLogger.shared.warning("⚠️ ML Prediction failed")
            return
        }
        
        // Guardar en historial
        predictionHistory.append(prediction)
        if predictionHistory.count > 30 { // Mantener últimas 30 predicciones
            predictionHistory.removeFirst()
        }
        
        // Mejorar con ML Tensor (macOS 13+)
        let finalCategory = prediction.category
        var finalConfidence = prediction.confidence
        //var enhancedRecommendation = prediction.recommendation

        if #available(macOS 13.0, *), predictionHistory.count >= 3 {
            let tensorManager = MLTensorManager.shared
            let enhanced = await tensorManager.enhancePrediction(
                basePrediction: prediction,
                historicalData: predictionHistory
            )
            
            finalConfidence = enhanced.adjustedConfidence
           // enhancedRecommendation = enhanced.enhancedRecommendation
            
            // Log de mejora
            if enhanced.trend != .stable {
                BusylightLogger.shared.info("📈 ML Tensor: Tendencia detectada - \(enhanced.trend)")
            }
            
            // Detectar anomalías
            let anomalies = tensorManager.detectAnomalies(recentPredictions: predictionHistory)
            for anomaly in anomalies {
                BusylightLogger.shared.warning("🚨 Anomalía detectada: \(anomaly.description)")
                
                // Notificar anomalías graves
                if anomaly.severity == .high {
                    NotificationCenterManager.shared.showInfoNotification(
                        title: "Patrón Inusual Detectado",
                        body: anomaly.suggestion
                    )
                }
            }
        }
        
        await MainActor.run {
            self.todayCategory = finalCategory
            self.todayConfidence = finalConfidence
        }
        
        BusylightLogger.shared.info("📊 ML Prediction: \(finalCategory.displayName) (\(Int(finalConfidence * 100))%)")
        
        // Notificar si es burnout risk
        if finalCategory == .burnoutRisk && configuration?.notificationOnAutoTrain == true {
            NotificationCenterManager.shared.showBurnoutWarningNotification()
        }
    }
    
    // MARK: - Training Stats
    
    func updateTrainingStats() {
        let descriptor = FetchDescriptor<MLWorkPattern>()
        let patterns = (try? context.fetch(descriptor)) ?? []
        
        trainingDaysCollected = patterns.count
        isModelTrained = patterns.count >= minSamplesForTraining
        modelAccuracy = configuration?.modelAccuracy ?? 0.0
    }
    
    // MARK: - Data Collection
    
    func collectDailyPattern(
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        sessionCount: Int,
        deepWorkMinutes: Int
    ) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        let pattern = MLWorkPattern(
            date: Date(),
            dayOfWeek: weekday,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            isHoliday: isTodayHoliday(),
            sessionCount: sessionCount,
            deepWorkMinutes: deepWorkMinutes,
            calendarEventCount: DayDataCollector.shared.meetingsToday
        )
        
        context.insert(pattern)
        try? context.save()
        
        updateTrainingStats()
        
        BusylightLogger.shared.info("📊 Pattern collected: \(pattern.date)")
    }
    
    // MARK: - Feedback
    
    func submitFeedback(predictedCategory: DayCategory, actualCategory: DayCategory, notes: String? = nil) {
        let feedback = DayCategoryFeedback(
            date: Date(),
            predictedCategory: predictedCategory.rawValue,
            actualCategory: actualCategory.rawValue,
            notes: notes
        )
        
        context.insert(feedback)
        try? context.save()
        
        BusylightLogger.shared.info("📝 Feedback submitted: Predicted \(predictedCategory.displayName), Actual \(actualCategory.displayName)")
    }
    
    // MARK: - Holiday Management
    
    func isTodayHoliday() -> Bool {
        let descriptor = FetchDescriptor<HolidayCalendar>()
        let holidays = (try? context.fetch(descriptor)) ?? []
        
        let calendar = Calendar.current
        return holidays.contains { holiday in
            calendar.isDate(holiday.date, inSameDayAs: Date())
        }
    }
    
    func addHoliday(date: Date, name: String, isEnabled: Bool) {
        let holiday = HolidayCalendar(date: date, name: name, isEnabled: isEnabled)
        context.insert(holiday)
        try? context.save()
    }
    
    // MARK: - ML Tensor Analytics (macOS 13+)
    
    @available(macOS 13.0, *)
    func getWeeklyPatternAnalysis() -> WeeklyPatternAnalysis? {
        guard predictionHistory.count >= 7 else { return nil }
        return MLTensorManager.shared.analyzeWeeklyPatterns(predictions: predictionHistory)
    }
    
    @available(macOS 13.0, *)
    func getRecentAnomalies() -> [Anomaly] {
        guard predictionHistory.count >= 3 else { return [] }
        return MLTensorManager.shared.detectAnomalies(recentPredictions: predictionHistory)
    }
    
    // MARK: - Analytics
    
    func getWeeklyPatterns() -> [MLWorkPattern] {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<MLWorkPattern>(
            predicate: #Predicate { pattern in
                pattern.date >= oneWeekAgo
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func getCategoryAccuracy() -> Double {
        let descriptor = FetchDescriptor<DayCategoryFeedback>()
        let feedbacks = (try? context.fetch(descriptor)) ?? []
        
        guard !feedbacks.isEmpty else { return 0.0 }
        
        let correctCount = feedbacks.filter { $0.wasCorrect }.count
        return Double(correctCount) / Double(feedbacks.count)
    }
}

// MARK: - DayDataCollector

/// Recolecta datos del día actual para predicciones ML
@MainActor
class DayDataCollector: ObservableObject {
    static let shared = DayDataCollector()
    
    @Published var meetingsToday: Int = 0
    @Published var hasDeadline: Bool = false
    @Published var backToBackCount: Int = 0
    @Published var freeBlocks: Int = 0
    @Published var meetingDensity: Int = 0
    @Published var interruptionRisk: Int = 0
    
    private init() {
        updateMetrics()
    }
    
    func updateMetrics() {
        let smartFeatures = SmartFeaturesManager.shared
        let pomodoro = PomodoroManager.shared
        
        // Estimar reuniones basado en pomodoros
        meetingsToday = pomodoro.currentSet / 2
        
        // Detectar deadline
        hasDeadline = smartFeatures.deepWorkRemainingMinutes > 0
        
        // Calcular métricas derivadas
        backToBackCount = meetingsToday >= 4 ? 1 : 0
        freeBlocks = max(0, 9 - meetingsToday)
        meetingDensity = min(100, (meetingsToday * 100) / 9)
        
        // Calcular riesgo de interrupción
        var risk = meetingDensity
        if hasDeadline { risk += 20 }
        if backToBackCount > 0 { risk += 15 }
        interruptionRisk = min(100, risk)
    }
}

// MARK: - Additional Methods (for SettingsView compatibility)

extension MLScheduleManager {
    func generateDemoData() {
        // Generate sample patterns for demo
        let calendar = Calendar.current
        for dayOffset in -30..<0 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            
            let pattern = MLWorkPattern(
                date: date,
                dayOfWeek: weekday,
                startHour: 8 + Int.random(in: 0...2),
                startMinute: 0,
                endHour: 17 + Int.random(in: 0...3),
                endMinute: 0,
                isHoliday: false,
                sessionCount: Int.random(in: 3...8),
                deepWorkMinutes: Int.random(in: 60...180),
                calendarEventCount: Int.random(in: 2...6)
            )
            context.insert(pattern)
        }
        try? context.save()
        updateTrainingStats()
        BusylightLogger.shared.info("📊 Demo data generated")
    }
    
    func clearAllData() {
        let patternsDescriptor = FetchDescriptor<MLWorkPattern>()
        let feedbackDescriptor = FetchDescriptor<DayCategoryFeedback>()
        
        if let patterns = try? context.fetch(patternsDescriptor) {
            for pattern in patterns { context.delete(pattern) }
        }
        if let feedbacks = try? context.fetch(feedbackDescriptor) {
            for feedback in feedbacks { context.delete(feedback) }
        }
        
        try? context.save()
        updateTrainingStats()
        BusylightLogger.shared.info("🗑️ All ML data cleared")
    }
    
    func getHolidayCalendars() -> [HolidayCalendar] {
        let descriptor = FetchDescriptor<HolidayCalendar>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func createHolidayCalendar(name: String, date: Date) {
        let holiday = HolidayCalendar(
            date: date,
            name: name,
            isEnabled: true
        )
        context.insert(holiday)
        try? context.save()
    }
    
    func exportTrainingDataset() -> String {
        let descriptor = FetchDescriptor<MLWorkPattern>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        guard let patterns = try? context.fetch(descriptor) else {
            return "No data available"
        }
        
        var csv = "date,dayOfWeek,startHour,endHour,sessionCount,deepWorkMinutes\\n"
        for pattern in patterns {
            csv += "\(pattern.date),\(pattern.dayOfWeek),\(pattern.startHour),\(pattern.endHour),\(pattern.sessionCount),\(pattern.deepWorkMinutes)\\n"
        }
        return csv
    }
}

// MARK: - HolidayCalendar Extension

extension HolidayCalendar {
    var customDates: [Date] {
        // Return array with just this holiday's date
        return [date]
    }
}
