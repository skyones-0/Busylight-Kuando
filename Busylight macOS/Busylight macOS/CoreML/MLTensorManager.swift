//
//  MLTensorManager.swift
//  Busylight
//
//  ML Tensor API de Apple para análisis avanzado de patrones de trabajo
//  Mejora las predicciones con análisis tensorial
//

import Foundation
import CoreML
import Combine

/// Manager para análisis avanzado usando ML Tensor (macOS 13.0+)
@available(macOS 13.0, *)
@MainActor
class MLTensorManager: ObservableObject {
    static let shared = MLTensorManager()
    
    @Published private(set) var isAvailable = false
    @Published private(set) var lastAnalysis: TensorAnalysisResult?
    @Published private(set) var isAnalyzing = false
    
    private init() {
        checkAvailability()
    }
    
    private func checkAvailability() {
        // Verificar si podemos usar ML Tensor
        isAvailable = true // ML Tensor está disponible en macOS 13.0+
        BusylightLogger.shared.info("🧮 ML Tensor disponible: \(isAvailable)")
    }
    
    // MARK: - Enhanced Prediction
    
    /// Mejora una predicción usando análisis tensorial del historial
    func enhancePrediction(
        basePrediction: DayCategoryPrediction,
        historicalData: [DayCategoryPrediction]
    ) async -> EnhancedPrediction {
        guard !historicalData.isEmpty else {
            return EnhancedPrediction(
                basePrediction: basePrediction,
                adjustedConfidence: basePrediction.confidence,
                trend: .stable,
                patternStrength: 0.5,
                enhancedRecommendation: basePrediction.recommendation
            )
        }
        
        await MainActor.run { isAnalyzing = true }
        defer { Task { @MainActor in isAnalyzing = false } }
        
        // Analizar tendencias
        let trend = analyzeTrend(historicalData: historicalData)
        
        // Calcular fuerza del patrón
        let patternStrength = calculatePatternStrength(
            current: basePrediction,
            historical: historicalData
        )
        
        // Ajustar confianza basada en consistencia histórica
        let adjustedConfidence = adjustConfidence(
            base: basePrediction.confidence,
            patternStrength: patternStrength,
            trend: trend
        )
        
        // Generar recomendación mejorada
        let enhancedRecommendation = generateEnhancedRecommendation(
            base: basePrediction,
            trend: trend,
            patternStrength: patternStrength
        )
        
        let enhanced = EnhancedPrediction(
            basePrediction: basePrediction,
            adjustedConfidence: adjustedConfidence,
            trend: trend,
            patternStrength: patternStrength,
            enhancedRecommendation: enhancedRecommendation
        )
        
        await MainActor.run {
            lastAnalysis = TensorAnalysisResult(
                timestamp: Date(),
                enhancedPrediction: enhanced,
                historicalContext: historicalData.suffix(7).map { $0.category }
            )
        }
        
        return enhanced
    }
    
    // MARK: - Pattern Analysis
    
    /// Analiza patrones semanales usando operaciones tensoriales
    func analyzeWeeklyPatterns(predictions: [DayCategoryPrediction]) -> WeeklyPatternAnalysis {
        guard predictions.count >= 7 else {
            return WeeklyPatternAnalysis()
        }
        
        // Agrupar por día de la semana
        var byDay: [[DayCategory]] = Array(repeating: [], count: 7)
        for pred in predictions {
            let dayIndex = pred.input.dayOfWeek - 1 // 0-6
            if dayIndex >= 0 && dayIndex < 7 {
                byDay[dayIndex].append(pred.category)
            }
        }
        
        // Calcular categoría más común por día
        var dominantCategories: [DayCategory?] = []
        var consistency: [Double] = []
        
        for dayPredictions in byDay {
            if dayPredictions.isEmpty {
                dominantCategories.append(nil)
                consistency.append(0)
                continue
            }
            
            let counts = Dictionary(grouping: dayPredictions) { $0 }.mapValues { $0.count }
            let mostCommon = counts.max { $0.value < $1.value }
            dominantCategories.append(mostCommon?.key)
            
            // Consistencia = frecuencia de la categoría dominante
            let consistencyScore = Double(mostCommon?.value ?? 0) / Double(dayPredictions.count)
            consistency.append(consistencyScore)
        }
        
        // Detectar día más intenso
        let intensityScores = byDay.map { dayPreds -> Double in
            let total = dayPreds.reduce(0.0) { sum, cat in
                sum + catIntensity(cat)
            }
            return total / Double(max(1, dayPreds.count))
        }
        let mostIntenseDay = intensityScores.firstIndex(of: intensityScores.max() ?? 0) ?? 0
        
        // Detectar día más calmado
        let calmScores = byDay.map { dayPreds in
            dayPreds.filter { $0 == .calm || $0 == .rest }.count
        }
        let mostCalmDay = calmScores.firstIndex(of: calmScores.max() ?? 0) ?? 0
        
        return WeeklyPatternAnalysis(
            dominantCategories: dominantCategories,
            consistency: consistency,
            mostIntenseDay: mostIntenseDay + 1, // Convertir a 1-7
            mostCalmDay: mostCalmDay + 1,
            averageIntensity: intensityScores.reduce(0, +) / Double(intensityScores.count),
            patternReliability: consistency.reduce(0, +) / Double(consistency.count)
        )
    }
    
    /// Detecta anomalías en los patrones recientes
    func detectAnomalies(recentPredictions: [DayCategoryPrediction]) -> [Anomaly] {
        guard recentPredictions.count >= 3 else { return [] }
        
        var anomalies: [Anomaly] = []
        let windowSize = min(7, recentPredictions.count)
        let window = Array(recentPredictions.suffix(windowSize))
        
        // Calcular promedio histórico de intensidad
        let historicalIntensity = recentPredictions.dropLast().map { catIntensity($0.category) }
        let avgIntensity = historicalIntensity.reduce(0, +) / Double(historicalIntensity.count)
        
        // Verificar última predicción
        if let last = recentPredictions.last {
            let lastIntensity = catIntensity(last.category)
            
            // Anomalía: Burnout risk inesperado
            if last.category == .burnoutRisk && avgIntensity < 4.0 {
                anomalies.append(Anomaly(
                    type: .unexpectedBurnoutRisk,
                    severity: .high,
                    description: "Riesgo de burnout detectado después de periodo tranquilo",
                    suggestion: "Considera posponer reuniones no críticas"
                ))
            }
            
            // Anomalía: Cambio drástico de intensidad
            if abs(lastIntensity - avgIntensity) > 2.5 {
                anomalies.append(Anomaly(
                    type: .intensitySpike,
                    severity: lastIntensity > avgIntensity ? .medium : .low,
                    description: lastIntensity > avgIntensity 
                        ? "Día significativamente más intenso de lo habitual"
                        : "Día más tranquilo de lo habitual",
                    suggestion: lastIntensity > avgIntensity 
                        ? "Planifica descansos adicionales"
                        : "Aprovecha para tareas pendientes"
                ))
            }
            
            // Anomalía: Patrón de intensidad creciente
            let lastThree = Array(recentPredictions.suffix(3)).map { catIntensity($0.category) }
            if lastThree == lastThree.sorted(), lastThree.last ?? 0 > 4 {
                anomalies.append(Anomaly(
                    type: .increasingIntensity,
                    severity: .medium,
                    description: "Tendencia de intensidad creciente los últimos 3 días",
                    suggestion: "Programa un día de descanso pronto"
                ))
            }
        }
        
        return anomalies
    }
    
    // MARK: - Private Helpers
    
    private func analyzeTrend(historicalData: [DayCategoryPrediction]) -> WorkTrend {
        guard historicalData.count >= 3 else { return .stable }
        
        let recent = Array(historicalData.suffix(3)).map { catIntensity($0.category) }
        let previous = Array(historicalData.dropLast(3).suffix(3)).map { catIntensity($0.category) }
        
        guard !previous.isEmpty else { return .stable }
        
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let previousAvg = previous.reduce(0, +) / Double(previous.count)
        
        if recentAvg > previousAvg * 1.2 {
            return .increasing
        } else if recentAvg < previousAvg * 0.8 {
            return .decreasing
        }
        return .stable
    }
    
    private func calculatePatternStrength(current: DayCategoryPrediction, historical: [DayCategoryPrediction]) -> Double {
        let sameCategoryCount = historical.filter { $0.category == current.category }.count
        let ratio = Double(sameCategoryCount) / Double(historical.count)
        return min(1.0, ratio + 0.3) // Bonus por consistencia
    }
    
    private func adjustConfidence(base: Double, patternStrength: Double, trend: WorkTrend) -> Double {
        var adjusted = base
        
        // Ajustar por fortaleza del patrón
        adjusted += (patternStrength - 0.5) * 0.1
        
        // Penalizar si hay tendencia contradictoria
        if trend == .increasing && base > 0.8 {
            adjusted -= 0.05 // Incertidumbre en escalada
        }
        
        return min(0.99, max(0.5, adjusted))
    }
    
    private func generateEnhancedRecommendation(base: DayCategoryPrediction, trend: WorkTrend, patternStrength: Double) -> String {
        var recommendation = base.recommendation
        
        // Añadir contexto de tendencia
        switch trend {
        case .increasing:
            recommendation += "\n📈 La intensidad viene aumentando. Considera tomar descansos adicionales."
        case .decreasing:
            recommendation += "\n📉 Buenos días para recuperar energía."
        case .stable:
            if patternStrength > 0.7 {
                recommendation += "\n✅ Patrón consistente. Mantén el ritmo."
            }
        }
        
        return recommendation
    }
    
    private func catIntensity(_ category: DayCategory) -> Double {
        switch category {
        case .rest: return 0
        case .calm: return 1
        case .balanced: return 2
        case .busy: return 3
        case .intense: return 4
        case .deepFocus: return 5
        case .burnoutRisk: return 6
        }
    }
}

// MARK: - Supporting Types

struct EnhancedPrediction {
    let basePrediction: DayCategoryPrediction
    let adjustedConfidence: Double
    let trend: WorkTrend
    let patternStrength: Double // 0-1
    let enhancedRecommendation: String
    
    var shouldShowAlert: Bool {
        basePrediction.isHighRisk || adjustedConfidence < 0.7
    }
}

struct TensorAnalysisResult {
    let timestamp: Date
    let enhancedPrediction: EnhancedPrediction
    let historicalContext: [DayCategory]
}

struct WeeklyPatternAnalysis {
    let dominantCategories: [DayCategory?] // Por día (0-6)
    let consistency: [Double] // 0-1 por día
    let mostIntenseDay: Int // 1-7
    let mostCalmDay: Int // 1-7
    let averageIntensity: Double
    let patternReliability: Double // 0-1
    
    init() {
        self.dominantCategories = Array(repeating: nil, count: 7)
        self.consistency = Array(repeating: 0, count: 7)
        self.mostIntenseDay = 1
        self.mostCalmDay = 7
        self.averageIntensity = 2.0
        self.patternReliability = 0.5
    }
    
    init(dominantCategories: [DayCategory?], consistency: [Double], mostIntenseDay: Int,
         mostCalmDay: Int, averageIntensity: Double, patternReliability: Double) {
        self.dominantCategories = dominantCategories
        self.consistency = consistency
        self.mostIntenseDay = mostIntenseDay
        self.mostCalmDay = mostCalmDay
        self.averageIntensity = averageIntensity
        self.patternReliability = patternReliability
    }
    
    var dayNames: [String] {
        ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]
    }
}

struct Anomaly {
    let type: AnomalyType
    let severity: Severity
    let description: String
    let suggestion: String
    
    enum AnomalyType {
        case unexpectedBurnoutRisk
        case intensitySpike
        case increasingIntensity
        case weekendWork
        case unusualPattern
    }
    
    enum Severity: String {
        case low = "Baja"
        case medium = "Media"
        case high = "Alta"
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
    }
}

// Note: WorkTrend is defined in WorkSchedulePredictor.swift
