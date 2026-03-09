# Insights Dashboard ML

Sistema de Machine Learning para analizar y predecir la eficiencia del día de trabajo.

## 🎯 Propósito

Un **card de insight** que al inicio del día muestra:
- Qué tipo de día te espera (categoría)
- Tu nivel de productividad esperado (0-100)
- Capacidad de concentración (0-100)
- Nivel de estrés estimado (0-100)
- Estrategia recomendada para el día

## 📊 Categorías de Día

| ID | Categoría | Emoji | Descripción | % Dataset |
|----|-----------|-------|-------------|-----------|
| 0 | Descanso | 🌴 | Sin trabajo programado | 7% |
| 1 | Tranquilo | 🧘 | Pocas reuniones, día relax | 10% |
| 2 | Balanceado | ⚡ | Mix ideal trabajo-reuniones | 13% |
| 3 | Ocupado | 📅 | Muchas reuniones pero manejable | 20% |
| 4 | Intenso | 🔥 | Día pesado, alta carga | 37% |
| 5 | Foco Profundo | 🎯 | Deadline + tiempo para concentrarse | 8% |
| 6 | Burnout Risk | 🚨 | Demasiado, necesitas cuidarte | 4% |

## 📁 Archivos

```
CoreML Training Data/
├── generate_insight_dataset.py    # Generador de datos
├── training_data.csv              # 2,121 registros (70%)
├── validation_data.csv            # 454 registros (15%)
├── testing_data.csv               # 455 registros (15%)
├── complete_dataset.csv           # 3,030 registros (100%)
└── README.md                      # Este archivo
```

## 📋 Features (15 inputs)

Todas conocidas al **inicio del día** (después de revisar calendario):

### Básicas
- `dayOfWeek` - Día de la semana (1-7)
- `isWeekend` - Es fin de semana (0/1)
- `isHoliday` - Es feriado (0/1)

### Reuniones
- `totalMeetingCount` - Total reuniones del día (0-10)
- `earlyMeetingCount` - Reuniones antes 10am (0-5)
- `lateMeetingCount` - Reuniones después 4pm (0-3)
- `backToBackMeetings` - Reuniones consecutivas (0/1)

### Presión
- `hasImportantDeadline` - Tiene deadline hoy (0/1)
- `hasUrgentDeadline` - Deadline urgente (0/1)

### Distribución
- `externalEventCount` - Eventos externos (0-3)
- `videoCallCount` - Llamadas de video (0-10)
- `freeTimeBlocks` - Bloques libres de 60+ min (0-9)
- `potentialDeepWorkBlocks` - Bloques para trabajo profundo (0-6)

### Scores calculados
- `meetingDensityScore` - Densidad de reuniones (0-100)
- `interruptionRiskScore` - Riesgo de interrupciones (0-100)

## 🎯 Targets (5 modelos a entrenar)

Entrena **un modelo por target** en Create ML:

### 1. dayCategory (Clasificación)
```
Type: Classifier
Algorithm: Boosted Trees o Random Forest
Classes: 0-6 (7 categorías)
Expected Accuracy: 65-75%
```

### 2. productivityScore (Regresión)
```
Type: Regressor
Algorithm: Random Forest
Range: 0-100
Expected MAE: ±8-12 puntos
```

### 3. focusScore (Regresión)
```
Type: Regressor
Range: 0-100
Expected MAE: ±10-15 puntos
```

### 4. stressLevel (Regresión)
```
Type: Regressor
Range: 0-100
Expected MAE: ±12-18 puntos
```

### 5. recommendedStrategy (Clasificación)
```
Type: Classifier
Classes: 0-6
Expected Accuracy: 70-80%
```

## 🚀 Cómo usar en Create ML

### Paso 1: Entrenar modelo de Categoría

1. Abre **Create ML** (Xcode → Open Developer Tool → Create ML)
2. Crea **New Project** → **Tabular Classification**
3. Carga `training_data.csv`
4. Configura:
   - **Target**: `dayCategory`
   - **Features**: Seleccionar todas las 15 features
   - **Algorithm**: Boosted Trees (mejor para categorías)
5. Click **Train**
6. Exporta como `DayCategoryClassifier.mlmodel`

### Paso 2: Entrenar modelo de Productividad

1. Crea **New Project** → **Tabular Regressor**
2. Carga `training_data.csv`
3. Configura:
   - **Target**: `productivityScore`
   - **Features**: Las 15 features
4. Exporta como `ProductivityRegressor.mlmodel`

### Paso 3: Repetir para otros targets

Entrena modelos separados para:
- `focusScore` → `FocusRegressor.mlmodel`
- `stressLevel` → `StressRegressor.mlmodel`
- `recommendedStrategy` → `StrategyClassifier.mlmodel`

## 💻 Integración en Swift

### Estructura de datos

```swift
struct DayInsight {
    let category: DayCategory
    let productivityScore: Int  // 0-100
    let focusScore: Int         // 0-100
    let stressLevel: Int        // 0-100
    let recommendedStrategy: Strategy
    
    var description: String {
        return "\(category.emoji) \(category.rawValue)"
    }
}

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
    
    var rawValue: String {
        switch self {
        case .rest: return "Descanso"
        case .calm: return "Tranquilo"
        case .balanced: return "Balanceado"
        case .busy: return "Ocupado"
        case .intense: return "Intenso"
        case .deepFocus: return "Foco Profundo"
        case .burnoutRisk: return "Burnout Risk"
        }
    }
    
    var color: Color {
        switch self {
        case .rest: return .gray
        case .calm: return .green
        case .balanced: return .blue
        case .busy: return .orange
        case .intense: return .red
        case .deepFocus: return .purple
        case .burnoutRisk: return .pink
        }
    }
}

enum Strategy: Int {
    case rest = 0
    case creative = 1
    case routine = 2
    case prioritize = 3
    case pomodoro = 4
    case deepWork = 5
    case mandatoryBreaks = 6
    
    var description: String {
        switch self {
        case .rest: return "Disfruta tu día libre"
        case .creative: return "Aprovecha para tareas creativas"
        case .routine: return "Sigue tu rutina habitual"
        case .prioritize: return "Prioriza solo lo urgente"
        case .pomodoro: return "Usa técnica Pomodoro"
        case .deepWork: return "Bloques de foco profundo"
        case .mandatoryBreaks: return "Toma descansos obligatorios"
        }
    }
}
```

### ViewModel

```swift
import CoreML

class InsightsViewModel: ObservableObject {
    @Published var todayInsight: DayInsight?
    @Published var isLoading = false
    
    // Modelos CoreML
    var categoryModel: DayCategoryClassifier?
    var productivityModel: ProductivityRegressor?
    var focusModel: FocusRegressor?
    var stressModel: StressRegressor?
    var strategyModel: StrategyClassifier?
    
    init() {
        loadModels()
    }
    
    func loadModels() {
        // Cargar modelos desde bundle
        categoryModel = try? DayCategoryClassifier(configuration: MLModelConfiguration())
        productivityModel = try? ProductivityRegressor(configuration: MLModelConfiguration())
        focusModel = try? FocusRegressor(configuration: MLModelConfiguration())
        stressModel = try? StressRegressor(configuration: MLModelConfiguration())
        strategyModel = try? StrategyClassifier(configuration: MLModelConfiguration())
    }
    
    func analyzeToday(calendarEvents: [CalendarEvent]) {
        isLoading = true
        
        // Extraer features del calendario
        let features = extractFeatures(from: calendarEvents)
        
        // Predecir con cada modelo
        do {
            let categoryInput = DayCategoryClassifierInput(
                dayOfWeek: features.dayOfWeek,
                isWeekend: features.isWeekend,
                isHoliday: features.isHoliday,
                totalMeetingCount: features.totalMeetings,
                earlyMeetingCount: features.earlyMeetings,
                lateMeetingCount: features.lateMeetings,
                hasImportantDeadline: features.hasDeadline,
                hasUrgentDeadline: features.hasUrgentDeadline,
                backToBackMeetings: features.backToBack,
                externalEventCount: features.externalEvents,
                videoCallCount: features.videoCalls,
                freeTimeBlocks: features.freeBlocks,
                potentialDeepWorkBlocks: features.deepWorkBlocks,
                meetingDensityScore: features.meetingDensity,
                interruptionRiskScore: features.interruptionRisk
            )
            
            let categoryOutput = try categoryModel?.prediction(input: categoryInput)
            let productivityOutput = try productivityModel?.prediction(input: /* ... */)
            // ... otros modelos
            
            todayInsight = DayInsight(
                category: DayCategory(rawValue: Int(categoryOutput?.dayCategory ?? 2)) ?? .balanced,
                productivityScore: Int(productivityOutput?.productivityScore ?? 70),
                focusScore: Int(focusOutput?.focusScore ?? 80),
                stressLevel: Int(stressOutput?.stressLevel ?? 30),
                recommendedStrategy: Strategy(rawValue: Int(strategyOutput?.recommendedStrategy ?? 2)) ?? .routine
            )
        } catch {
            print("Error en predicción: \(error)")
        }
        
        isLoading = false
    }
}
```

### UI Component

```swift
struct InsightsCard: View {
    @ObservedObject var viewModel: InsightsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Análisis del día")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            
            if let insight = viewModel.todayInsight {
                // Categoría principal
                HStack(spacing: 12) {
                    Text(insight.category.emoji)
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading) {
                        Text(insight.category.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(insight.category.color)
                        
                        Text(insight.recommendedStrategy.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Scores
                HStack(spacing: 20) {
                    ScoreView(
                        title: "Productividad",
                        value: insight.productivityScore,
                        color: .blue
                    )
                    
                    ScoreView(
                        title: "Focus",
                        value: insight.focusScore,
                        color: .green
                    )
                    
                    ScoreView(
                        title: "Estrés",
                        value: insight.stressLevel,
                        color: insight.stressLevel > 70 ? .red : .orange
                    )
                }
                
                // Alerta si es burnout risk
                if insight.category == .burnoutRisk {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Día muy intenso - programa descansos obligatorios")
                    }
                    .padding()
                    .background(Color.pink.opacity(0.2))
                    .cornerRadius(8)
                }
            } else {
                Button("Analizar mi día") {
                    viewModel.analyzeToday(calendarEvents: fetchCalendarEvents())
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct ScoreView: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Barra de progreso
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.2))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value) / 100, height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}
```

## 📊 Expected Performance

| Modelo | Métrica | Valor Esperado |
|--------|---------|----------------|
| Categoría | Accuracy | 65-75% |
| Productividad | MAE | ±8-12 puntos |
| Focus | MAE | ±10-15 puntos |
| Estrés | MAE | ±12-18 puntos |
| Estrategia | Accuracy | 70-80% |

## 🎨 Tips de UI/UX

1. **Colores dinámicos**: Usa colores según la categoría
2. **Animaciones**: Anima las barras de progreso al cargar
3. **Contexto**: Muestra comparación con el promedio del usuario
4. **Accionable**: La estrategia debe ser específica y útil
5. **Alertas suaves**: Burnout risk no debe alarmar, sino sugerir cuidado

## 🔄 Regenerar datos

Si necesitas más datos o diferente distribución:

```bash
cd "CoreML Training Data"
python3 generate_insight_dataset.py
```

Modifica los parámetros en el script para ajustar la distribución.
