//
//  DayCategoryInsightsView.swift
//  Busylight
//
//  Vista de insights de categoría del día usando DayCategoryClassifier
//

import SwiftUI

struct DayCategoryInsightsView: View {
    @StateObject private var classifier = DayCategoryClassifierWrapper.shared
    @State private var tensorManager: MLTensorManager? = {
        if #available(macOS 13.0, *) {
            return MLTensorManager.shared
        }
        return nil
    }()
    
    @State private var meetings: Int = 4
    @State private var totalMeetingMinutes: Int = 180
    @State private var freeTimeSlots: Int = 3
    @State private var isAnalyzing = false
    @State private var enhancedPrediction: EnhancedPrediction?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerSection
            
            // Input controls
            inputSection
            
            // Prediction result
            if let prediction = classifier.lastPrediction {
                predictionCard(prediction)
                
                if let enhanced = enhancedPrediction {
                    enhancedInsightsCard(enhanced)
                }
            }
            
            // Statistics
            if !classifier.predictionHistory.isEmpty {
                statisticsSection
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            Task {
                await analyzeDay()
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("🧠 Análisis del Día")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Clasificación inteligente con ML")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if classifier.isModelLoaded {
                Label("Modelo CoreML cargado", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Label("Usando análisis estadístico", systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: 16) {
            Text("Datos del Calendario")
                .font(.headline)
            
            HStack(spacing: 20) {
                // Meetings
                VStack(alignment: .leading) {
                    Text("Reuniones: \(meetings)")
                        .font(.subheadline)
                    Slider(value: .init(
                        get: { Double(meetings) },
                        set: { meetings = Int($0) }
                    ), in: 0...10, step: 1)
                }
                .frame(maxWidth: .infinity)
                
                // Duration
                VStack(alignment: .leading) {
                    Text("Duración: \(totalMeetingMinutes) min")
                        .font(.subheadline)
                    Slider(value: .init(
                        get: { Double(totalMeetingMinutes) },
                        set: { totalMeetingMinutes = Int($0) }
                    ), in: 0...480, step: 15)
                }
                .frame(maxWidth: .infinity)
                
                // Free slots
                VStack(alignment: .leading) {
                    Text("Slots libres: \(freeTimeSlots)")
                        .font(.subheadline)
                    Slider(value: .init(
                        get: { Double(freeTimeSlots) },
                        set: { freeTimeSlots = Int($0) }
                    ), in: 0...8, step: 1)
                }
                .frame(maxWidth: .infinity)
            }
            
            Button(action: { Task { await analyzeDay() } }) {
                HStack {
                    Image(systemName: "brain.head.profile")
                    Text("Analizar Día")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: 200)
                .padding()
                .background(Color.blue.gradient)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .disabled(isAnalyzing)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func predictionCard(_ prediction: DayCategoryPrediction) -> some View {
        VStack(spacing: 16) {
            // Category display
            HStack(spacing: 16) {
                Text(prediction.emoji)
                    .font(.system(size: 60))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(prediction.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(prediction.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Confidence badge
                VStack {
                    Text("\(Int(prediction.confidence * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Confianza")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(confidenceColor(prediction.confidence).opacity(0.2))
                .cornerRadius(8)
            }
            
            Divider()
            
            // Recommendation
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text(prediction.recommendation)
                    .font(.subheadline)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(8)
            
            // Alert for high risk
            if prediction.isHighRisk {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("⚠️ Día de alto riesgo - Programa descansos obligatorios")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding()
                .background(Color.red.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(categoryColor(prediction.category), lineWidth: 2)
        )
    }
    
    @available(macOS 13.0, *)
    private func enhancedInsightsCard(_ enhanced: EnhancedPrediction) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Análisis Avanzado (ML Tensor)", systemImage: "cpu")
                .font(.headline)
            
            HStack(spacing: 20) {
                // Trend
                VStack(alignment: .leading) {
                    Text("Tendencia")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Image(systemName: trendIcon(enhanced.trend))
                        Text(trendText(enhanced.trend))
                    }
                    .font(.subheadline)
                }
                
                // Pattern strength
                VStack(alignment: .leading) {
                    Text("Consistencia")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ProgressView(value: enhanced.patternStrength)
                        .frame(width: 80)
                    Text("\(Int(enhanced.patternStrength * 100))%")
                        .font(.caption)
                }
                
                // Adjusted confidence
                VStack(alignment: .leading) {
                    Text("Confianza Ajustada")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(enhanced.adjustedConfidence * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            
            if enhanced.shouldShowAlert {
                Text(enhanced.enhancedRecommendation)
                    .font(.caption)
                    .padding(8)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estadísticas Históricas")
                .font(.headline)
            
            let stats = classifier.getStatistics()
            
            HStack(spacing: 16) {
                StatBox(
                    title: "Total",
                    value: "\(stats.totalPredictions)",
                    icon: "number.circle.fill",
                    color: .blue
                )
                
                StatBox(
                    title: "Balance",
                    value: "\(stats.workLifeBalanceScore)/100",
                    icon: "scale.3d",
                    color: stats.workLifeBalanceScore > 70 ? .green : (stats.workLifeBalanceScore > 40 ? .orange : .red)
                )
                
                StatBox(
                    title: "Riesgo Burnout",
                    value: "\(Int(stats.burnoutRiskPercentage))%",
                    icon: "exclamationmark.triangle.fill",
                    color: stats.burnoutRiskPercentage > 10 ? .red : .green
                )
            }
            
            // Category distribution
            if !stats.categoryDistribution.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Distribución de Categorías")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(DayCategory.allCases, id: \.self) { category in
                            if let count = stats.categoryDistribution[category], count > 0 {
                                VStack(spacing: 4) {
                                    Text(category.emoji)
                                        .font(.title3)
                                    Text("\(count)")
                                        .font(.caption)
                                }
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    
    private func analyzeDay() async {
        isAnalyzing = true
        
        let prediction = await classifier.predictToday(
            meetings: meetings,
            totalMeetingMinutes: totalMeetingMinutes,
            freeTimeSlots: freeTimeSlots
        )
        
        // Enhance with ML Tensor if available
        if #available(macOS 13.0, *), let tensorMgr = tensorManager {
            if let pred = prediction {
                enhancedPrediction = await tensorMgr.enhancePrediction(
                    basePrediction: pred,
                    historicalData: classifier.predictionHistory
                )
            }
        }
        
        isAnalyzing = false
    }
    
    // MARK: - Helpers
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence > 0.9 { return .green }
        if confidence > 0.7 { return .orange }
        return .red
    }
    
    private func categoryColor(_ category: DayCategory) -> Color {
        switch category {
        case .rest: return .gray
        case .calm: return .green
        case .balanced: return .blue
        case .busy: return .orange
        case .intense: return .red
        case .deepFocus: return .purple
        case .burnoutRisk: return .pink
        }
    }
    
    private func trendIcon(_ trend: WorkTrend) -> String {
        switch trend {
        case .increasing: return "arrow.up.circle.fill"
        case .decreasing: return "arrow.down.circle.fill"
        case .stable: return "equal.circle.fill"
        }
    }
    
    private func trendText(_ trend: WorkTrend) -> String {
        switch trend {
        case .increasing: return "Aumentando"
        case .decreasing: return "Disminuyendo"
        case .stable: return "Estable"
        }
    }
}


// MARK: - Preview

struct DayCategoryInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        DayCategoryInsightsView()
    }
}
