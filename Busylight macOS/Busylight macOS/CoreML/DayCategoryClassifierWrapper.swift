//
//  DayCategoryClassifierWrapper.swift
//  Busylight
//
//  Wrapper para DayCategoryClassifier.mlmodel
//  Clasifica días laborales en 7 categorías: Rest, Calm, Balanced, Busy, Intense, DeepFocus, BurnoutRisk
//

import Foundation
import CoreML
import Combine

/// Estructura de entrada para predicción
struct DayInput {
    let dayOfWeek: Int           // 1-7 (Domingo=1)
    let isWeekend: Int           // 0 o 1
    let isHoliday: Int           // 0 o 1
    let totalMeetingCount: Int   // 0-10
    let hasImportantDeadline: Int // 0 o 1
    let backToBackMeetings: Int  // 0 o 1
    let freeTimeBlocks: Int      // 0-9 (bloques de 60+ min libres)
    let meetingDensityScore: Int // 0-100
    let interruptionRiskScore: Int // 0-100
    
    /// Crea input desde datos de calendario simplificados
    static func fromCalendarData(
        meetings: Int,
        totalMeetingMinutes: Int,
        freeTimeSlots: Int,
        date: Date = Date()
    ) -> DayInput {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday], from: date)
        let dayOfWeek = components.weekday ?? 2
        let isWeekend = (dayOfWeek == 1 || dayOfWeek == 7) ? 1 : 0
        
        // Calcular métricas derivadas
        let meetingDensity = min(100, (totalMeetingMinutes * 100) / 480) // % del día laboral
        let hasBackToBack = meetings >= 4 ? 1 : 0
        let interruptionRisk = min(100, meetings * 10 + meetingDensity / 2)
        let hasDeadline = meetingDensity > 70 ? 1 : 0
        
        return DayInput(
            dayOfWeek: dayOfWeek,
            isWeekend: isWeekend,
            isHoliday: 0,
            totalMeetingCount: min(10, meetings),
            hasImportantDeadline: hasDeadline,
            backToBackMeetings: hasBackToBack,
            freeTimeBlocks: min(9, freeTimeSlots),
            meetingDensityScore: meetingDensity,
            interruptionRiskScore: interruptionRisk
        )
    }
}

/// Resultado de predicción con metadata
struct DayCategoryPrediction {
    let category: DayCategory
    let confidence: Double
    let input: DayInput
    let timestamp: Date
    
    var emoji: String { category.emoji }
    var name: String { category.displayName }
    var color: String { category.color }
    var description: String { category.description }
    var recommendation: String { category.recommendation }
    var isHighRisk: Bool { category == .burnoutRisk }
}

/// Categorías de día laboral
enum DayCategory: Int, CaseIterable {
    case rest = 0
    case calm = 1
    case balanced = 2
    case busy = 3
    case intense = 4
    case deepFocus = 5
    case burnoutRisk = 6
    
    var emoji: String {
        switch self {
        case .rest: return "🌴"
        case .calm: return "🧘"
        case .balanced: return "⚡"
        case .busy: return "📅"
        case .intense: return "🔥"
        case .deepFocus: return "🎯"
        case .burnoutRisk: return "🚨"
        }
    }
    
    var displayName: String {
        switch self {
        case .rest: return "Descanso"
        case .calm: return "Tranquilo"
        case .balanced: return "Balanceado"
        case .busy: return "Ocupado"
        case .intense: return "Intenso"
        case .deepFocus: return "Foco Profundo"
        case .burnoutRisk: return "Riesgo Burnout"
        }
    }
    
    var color: String {
        switch self {
        case .rest: return "gray"
        case .calm: return "green"
        case .balanced: return "blue"
        case .busy: return "orange"
        case .intense: return "red"
        case .deepFocus: return "purple"
        case .burnoutRisk: return "pink"
        }
    }
    
    var description: String {
        switch self {
        case .rest: return "Día libre para recargar energías"
        case .calm: return "Pocas reuniones, ideal para creatividad"
        case .balanced: return "Mix ideal de trabajo y reuniones"
        case .busy: return "Muchas reuniones pero manejable"
        case .intense: return "Día pesado, alta carga de trabajo"
        case .deepFocus: return "Deadline + tiempo para foco profundo"
        case .burnoutRisk: return "Demasiado intenso, necesitas cuidarte"
        }
    }
    
    var recommendation: String {
        switch self {
        case .rest: return "Disfruta tu descanso, desconecta completamente"
        case .calm: return "Aprovecha para tareas creativas y planificación"
        case .balanced: return "Buen ritmo, mantén el equilibrio"
        case .busy: return "Prioriza lo urgente, delega si es posible"
        case .intense: return "Usa Pomodoro y toma micro-descansos"
        case .deepFocus: return "Bloques de foco para el deadline principal"
        case .burnoutRisk: return "⚠️ Programa descansos obligatorios hoy"
        }
    }
}

/// Wrapper principal para el clasificador
@MainActor
class DayCategoryClassifierWrapper: ObservableObject {
    static let shared = DayCategoryClassifierWrapper()
    
    @Published var isModelLoaded = false
    @Published var lastPrediction: DayCategoryPrediction?
    @Published var predictionHistory: [DayCategoryPrediction] = []
    @Published var isProcessing = false
    
    private var model: MLModel?
    private let modelName = "DayCategoryClassifier"
    
    private init() {
        loadModel()
    }
    
    // MARK: - Model Loading
    
    private func loadModel() {
        BusylightLogger.shared.info("🧠 Cargando DayCategoryClassifier...")
        
        // Intentar cargar desde bundle
        let bundle = Bundle.main
        
        // Estrategia 1: .mlmodelc compilado
        if let modelURL = bundle.url(forResource: modelName, withExtension: "mlmodelc") {
            do {
                let config = MLModelConfiguration()
                config.computeUnits = .cpuAndNeuralEngine
                model = try MLModel(contentsOf: modelURL, configuration: config)
                isModelLoaded = true
                BusylightLogger.shared.info("✅ DayCategoryClassifier cargado (.mlmodelc)")
                return
            } catch {
                BusylightLogger.shared.info("❌ Error cargando .mlmodelc: \(error)")
            }
        }
        
        // Estrategia 2: .mlmodel sin compilar
        if let modelURL = bundle.url(forResource: modelName, withExtension: "mlmodel") {
            do {
                let compiledURL = try MLModel.compileModel(at: modelURL)
                let config = MLModelConfiguration()
                config.computeUnits = .cpuAndNeuralEngine
                model = try MLModel(contentsOf: compiledURL, configuration: config)
                isModelLoaded = true
                BusylightLogger.shared.info("✅ DayCategoryClassifier cargado (.mlmodel)")
                return
            } catch {
                BusylightLogger.shared.info("❌ Error compilando .mlmodel: \(error)")
            }
        }
        
        BusylightLogger.shared.info("⚠️ DayCategoryClassifier no encontrado. Se usará predicción estadística.")
    }
    
    // MARK: - Prediction API
    
    /// Predice la categoría del día actual
    func predictToday(meetings: Int, totalMeetingMinutes: Int, freeTimeSlots: Int) async -> DayCategoryPrediction? {
        let input = DayInput.fromCalendarData(
            meetings: meetings,
            totalMeetingMinutes: totalMeetingMinutes,
            freeTimeSlots: freeTimeSlots
        )
        return await predict(input: input)
    }
    
    /// Predice para cualquier fecha futura
    func predictDay(date: Date, meetings: Int, totalMeetingMinutes: Int, freeTimeSlots: Int) async -> DayCategoryPrediction? {
        let input = DayInput.fromCalendarData(
            meetings: meetings,
            totalMeetingMinutes: totalMeetingMinutes,
            freeTimeSlots: freeTimeSlots,
            date: date
        )
        return await predict(input: input)
    }
    
    /// Predicción principal con input completo
    func predict(input: DayInput) async -> DayCategoryPrediction? {
        await MainActor.run { isProcessing = true }
        
        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }
        
        // Si el modelo está cargado, usar CoreML
        if let model = model, isModelLoaded {
            return await predictWithCoreML(input: input, model: model)
        }
        
        // Fallback: predicción estadística
        return predictStatistically(input: input)
    }
    
    // MARK: - CoreML Prediction
    
    private func predictWithCoreML(input: DayInput, model: MLModel) async -> DayCategoryPrediction? {
        do {
            let inputDict: [String: Any] = [
                "dayOfWeek": input.dayOfWeek,
                "isWeekend": input.isWeekend,
                "isHoliday": input.isHoliday,
                "totalMeetingCount": input.totalMeetingCount,
                "hasImportantDeadline": input.hasImportantDeadline,
                "backToBackMeetings": input.backToBackMeetings,
                "freeTimeBlocks": input.freeTimeBlocks,
                "meetingDensityScore": input.meetingDensityScore,
                "interruptionRiskScore": input.interruptionRiskScore
            ]
            
            let provider = try MLDictionaryFeatureProvider(dictionary: inputDict)
            let output = try await model.prediction(from: provider)
            
            guard let categoryValue = output.featureValue(for: "dayCategory")?.int64Value,
                  let category = DayCategory(rawValue: Int(categoryValue)) else {
                return nil
            }
            
            // Calcular confianza (simulada - CoreML no da probabilidades directamente)
            let confidence = calculateConfidence(input: input, category: category)
            
            let prediction = DayCategoryPrediction(
                category: category,
                confidence: confidence,
                input: input,
                timestamp: Date()
            )
            
            await MainActor.run {
                lastPrediction = prediction
                predictionHistory.append(prediction)
                // Mantener solo últimas 30 predicciones
                if predictionHistory.count > 30 {
                    predictionHistory.removeFirst()
                }
            }
            
            BusylightLogger.shared.info("🎯 Predicción: \(category.emoji) \(category.displayName) (confianza: \(Int(confidence * 100))%)")
            
            return prediction
            
        } catch {
            BusylightLogger.shared.info("❌ Error en predicción CoreML: \(error)")
            return predictStatistically(input: input)
        }
    }
    
    // MARK: - Statistical Fallback
    
    private func predictStatistically(input: DayInput) -> DayCategoryPrediction? {
        // Algoritmo basado en reglas para cuando no hay modelo
        var score = 0
        
        // Peso por cantidad de reuniones
        score += input.totalMeetingCount * 10
        
        // Peso por densidad
        score += input.meetingDensityScore / 10
        
        // Peso por interrupciones
        score += input.interruptionRiskScore / 10
        
        // Penalización por back-to-back
        if input.backToBackMeetings == 1 { score += 15 }
        
        // Bonus por tiempo libre
        score -= input.freeTimeBlocks * 5
        
        // Determinar categoría basada en score
        let category: DayCategory
        if input.isWeekend == 1 || input.isHoliday == 1 {
            category = .rest
        } else if score <= 10 {
            category = .calm
        } else if score <= 30 {
            category = .balanced
        } else if score <= 50 {
            category = .busy
        } else if score <= 70 {
            category = .intense
        } else if input.hasImportantDeadline == 1 {
            category = .deepFocus
        } else {
            category = .burnoutRisk
        }
        
        let prediction = DayCategoryPrediction(
            category: category,
            confidence: 0.75, // Confianza base para predicción estadística
            input: input,
            timestamp: Date()
        )
        
        Task { @MainActor in
            lastPrediction = prediction
            predictionHistory.append(prediction)
        }
        
        BusylightLogger.shared.info("📊 Predicción estadística: \(category.emoji) \(category.displayName)")
        
        return prediction
    }
    
    // MARK: - Confidence Calculation
    
    private func calculateConfidence(input: DayInput, category: DayCategory) -> Double {
        // Calcular confianza basada en qué tan "clara" es la categoría
        var confidence = 0.85 // Base
        
        // Ajustar según características del input
        switch category {
        case .rest:
            if input.isWeekend == 1 || input.isHoliday == 1 {
                confidence = 0.98
            }
        case .burnoutRisk:
            if input.totalMeetingCount >= 8 || input.meetingDensityScore > 80 {
                confidence = 0.95
            }
        case .deepFocus:
            if input.hasImportantDeadline == 1 && input.freeTimeBlocks >= 2 {
                confidence = 0.90
            }
        default:
            confidence = 0.85
        }
        
        return min(0.99, confidence)
    }
    
    // MARK: - Analytics
    
    /// Obtiene estadísticas de predicciones históricas
    func getStatistics() -> PredictionStatistics {
        let history = predictionHistory
        guard !history.isEmpty else { return PredictionStatistics() }
        
        let counts = Dictionary(grouping: history) { $0.category }
            .mapValues { $0.count }
        
        let avgConfidence = history.map { $0.confidence }.reduce(0, +) / Double(history.count)
        
        let burnoutCount = counts[.burnoutRisk] ?? 0
        let intenseCount = counts[.intense] ?? 0
        let restCount = counts[.rest] ?? 0
        
        return PredictionStatistics(
            totalPredictions: history.count,
            categoryDistribution: counts,
            averageConfidence: avgConfidence,
            burnoutRiskDays: burnoutCount,
            intenseDays: intenseCount,
            restDays: restCount,
            workLifeBalanceScore: calculateBalanceScore(restDays: restCount, intenseDays: intenseCount + burnoutCount, total: history.count)
        )
    }
    
    private func calculateBalanceScore(restDays: Int, intenseDays: Int, total: Int) -> Int {
        guard total > 0 else { return 50 }
        let restRatio = Double(restDays) / Double(total)
        let intenseRatio = Double(intenseDays) / Double(total)
        
        // Score óptimo: 10-20% rest, <20% intense
        let restScore = min(50, Int(restRatio * 200))
        let intensePenalty = Int(intenseRatio * 100)
        
        return max(0, min(100, 50 + restScore - intensePenalty))
    }
}

// MARK: - Statistics

struct PredictionStatistics {
    let totalPredictions: Int
    let categoryDistribution: [DayCategory: Int]
    let averageConfidence: Double
    let burnoutRiskDays: Int
    let intenseDays: Int
    let restDays: Int
    let workLifeBalanceScore: Int // 0-100
    
    init() {
        self.totalPredictions = 0
        self.categoryDistribution = [:]
        self.averageConfidence = 0
        self.burnoutRiskDays = 0
        self.intenseDays = 0
        self.restDays = 0
        self.workLifeBalanceScore = 50
    }
    
    init(totalPredictions: Int, categoryDistribution: [DayCategory: Int], averageConfidence: Double,
         burnoutRiskDays: Int, intenseDays: Int, restDays: Int, workLifeBalanceScore: Int) {
        self.totalPredictions = totalPredictions
        self.categoryDistribution = categoryDistribution
        self.averageConfidence = averageConfidence
        self.burnoutRiskDays = burnoutRiskDays
        self.intenseDays = intenseDays
        self.restDays = restDays
        self.workLifeBalanceScore = workLifeBalanceScore
    }
    
    var mostCommonCategory: DayCategory? {
        categoryDistribution.max { $0.value < $1.value }?.key
    }
    
    var burnoutRiskPercentage: Double {
        guard totalPredictions > 0 else { return 0 }
        return Double(burnoutRiskDays) / Double(totalPredictions) * 100
    }
}

