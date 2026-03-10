//
//  DashboardView.swift
//  Busylight
//
//  Dashboard principal con Insights ML
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @StateObject private var mlManager = MLScheduleManager.shared
    @StateObject private var classifier = DayCategoryClassifierWrapper.shared
    @StateObject private var dataCollector = DayDataCollector.shared
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Today's Prediction Card
                todayPredictionCard
                
                // Stats Grid
                statsGrid
                
                // Quick Actions
                quickActionsSection
                
                // ML Insights (if available)
                if let category = mlManager.todayCategory {
                    insightsSection(category: category)
                }
            }
            .padding()
        }
        .navigationTitle("Panel")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: refreshData) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .onAppear {
            loadInitialData()
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hola!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(formattedDate())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(classifier.isModelLoaded ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                
                Text(classifier.isModelLoaded ? "ML Activo" : "Cargando ML...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Today's Prediction Card
    @ViewBuilder
    private var todayPredictionCard: some View {
        GlassCard(title: "Hoy", icon: "calendar") {
            VStack(spacing: 16) {
                if let category = mlManager.todayCategory {
                    predictionContent(category: category)
                } else {
                    noPredictionContent()
                }
            }
        }
    }
    
    private func predictionContent(category: DayCategory) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Text(category.emoji)
                    .font(.system(size: 60))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(category.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(mlManager.todayConfidence * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("confianza")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text(category.recommendation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
    
    private func noPredictionContent() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("Aún no hay predicción")
                .font(.headline)
            
            Text("El modelo necesita más datos para predecir")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Generar Predicción") {
                generatePrediction()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Reuniones",
                value: "\(dataCollector.meetingsToday)",
                icon: "person.3.fill",
                color: .blue
            )
            
            StatCard(
                title: "Tiempo Libre",
                value: "\(dataCollector.freeBlocks) bloques",
                icon: "clock.fill",
                color: .green
            )
            
            StatCard(
                title: "Densidad",
                value: "\(dataCollector.meetingDensity)%",
                icon: "chart.bar.fill",
                color: dataCollector.meetingDensity > 70 ? .red : .orange
            )
            
            StatCard(
                title: "Riesgo",
                value: "\(dataCollector.interruptionRisk)%",
                icon: "exclamationmark.triangle.fill",
                color: dataCollector.interruptionRisk > 70 ? .red : .yellow
            )
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        GlassCard(title: "Acciones Rápidas", icon: "bolt.fill") {
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Deep Work",
                    icon: "target",
                    color: .purple
                ) {
                    // Navigate to Deep Work
                }
                
                QuickActionButton(
                    title: "Pomodoro",
                    icon: "timer",
                    color: .blue
                ) {
                    // Navigate to Pomodoro
                }
                
                QuickActionButton(
                    title: "Feedback",
                    icon: "hand.thumbsup.fill",
                    color: .green
                ) {
                    showFeedbackDialog()
                }
            }
        }
    }
    
    // MARK: - Insights Section
    private func insightsSection(category: DayCategory) -> some View {
        GlassCard(title: "Insights ML", icon: "brain") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.blue)
                    
                    Text("Patrones detectados: \(mlManager.trainingDaysCollected) días")
                        .font(.subheadline)
                }
                
                if category == .burnoutRisk {
                    HStack {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .foregroundColor(.red)
                        
                        Text("¡Cuidado! Día de alto riesgo detectado")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                #if canImport(MLTensor)
                if #available(macOS 13.0, *) {
                    NavigationLink(destination: MLTensorInsightsView()) {
                        HStack {
                            Text("Ver Análisis Avanzado")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
                #endif
            }
        }
    }
    
    // MARK: - Actions
    private func loadInitialData() {
        Task {
            isLoading = true
            Task { await mlManager.predictTodayCategory() }
            dataCollector.updateMetrics()
            isLoading = false
        }
    }
    
    private func refreshData() {
        Task {
            isLoading = true
            dataCollector.updateMetrics()
            Task { await mlManager.predictTodayCategory() }
            try? await Task.sleep(nanoseconds: 500_000_000)
            isLoading = false
        }
    }
    
    private func generatePrediction() {
        Task {
            Task { await mlManager.predictTodayCategory() }
        }
    }
    
    private func showFeedbackDialog() {
        NotificationCenterManager.shared.showInfoNotification(
            title: "Feedback",
            body: "La predicción fue correcta?"
        )
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
}

// MARK: - Supporting Views

// Nota: StatCard está definido en MLTensorInsightsView.swift

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
