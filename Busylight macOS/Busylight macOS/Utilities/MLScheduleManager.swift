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
    var isWorkHoliday: Bool
    
    init(date: Date, name: String, isWorkHoliday: Bool) {
        self.id = UUID()
        self.date = date
        self.name = name
        self.isWorkHoliday = isWorkHoliday
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
    static let shared = MLScheduleManager()
    
    // MARK: - Published Properties
    @Published var isModelTrained = false
    @Published var modelAccuracy: Double = 0.0
    @Published var trainingDaysCollected: Int = 0
    @Published var todayCategory: DayCategory?
    @Published var todayConfidence: Double = 0.0
    @Published var configuration: MLConfiguration?
    
    // MARK: - Private Properties
    private let context: ModelContext
    private let minSamplesForTraining = 3
    private var currentDate: Date = Date()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        let schema = Schema([MLWorkPattern.self, MLConfiguration.self, HolidayCalendar.self, DayCategoryFeedback.self])
        let container = try! ModelContainer(for: schema)
        self.context = ModelContext(container)
        
        loadConfiguration()
        updateTrainingStats()
        
        // Actualización diaria
        Task {
            await dailyUpdateLoop()
        }
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
    
    func predictTodayCategory() async {
        // Obtener datos actuales
        let dataCollector = DayDataCollector.shared
        dataCollector.updateMetrics()
        
        let meetings = dataCollector.meetingsToday
        let freeSlots = dataCollector.freeBlocks
        
        // Estimar minutos de reunión (aproximación)
        let estimatedMeetingMinutes = meetings * 45 // 45 min promedio por reunión
        
        // Hacer predicción
        if let prediction = await DayCategoryClassifierWrapper.shared.predictToday(
            meetings: meetings,
            totalMeetingMinutes: estimatedMeetingMinutes,
            freeTimeSlots: freeSlots
        ) {
            await MainActor.run {
                self.todayCategory = prediction.category
                self.todayConfidence = prediction.confidence
            }
            
            BusylightLogger.shared.info("📊 ML Prediction: \(prediction.category.displayName) (\(Int(prediction.confidence * 100))%)")
            
            // Notificar si es burnout risk
            if prediction.category == .burnoutRisk && configuration?.notificationOnAutoTrain == true {
                NotificationCenterManager.shared.showBurnoutWarningNotification()
            }
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
    
    func addHoliday(date: Date, name: String, isWorkHoliday: Bool) {
        let holiday = HolidayCalendar(date: date, name: name, isWorkHoliday: isWorkHoliday)
        context.insert(holiday)
        try? context.save()
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
