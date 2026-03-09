# Predicción de Productividad para Insights

**Nuevo enfoque**: En lugar de predecir horarios de entrada/salida, predecimos la **productividad del día**.

## 🎯 Propósito

Para el tab de **Insights**, mostrar al usuario al inicio del día:
- Qué tipo de día le espera (Light / Normal / Heavy)
- Cuántas horas probablemente trabajará
- Cuánto Deep Work podría lograr

## 📊 Modelos Entrenados

### 1. Categoría de Productividad (Clasificación)
```
Clases: 🌱 Light | ⚡ Normal | 🔥 Heavy
Accuracy: 69.3%
```

### 2. Horas de Trabajo (Regresión)
```
Error promedio: ±0.5 horas
```

### 3. Deep Work Minutes (Regresión)
```
Error promedio: ±43 minutos
```

## 📁 Archivos

| Archivo | Descripción |
|---------|-------------|
| `train_insights.py` | Script de entrenamiento |
| `ProductivityInsights.pkl` | Modelos entrenados |
| `insights_dataset.csv` | Dataset para Create ML |

## 🔧 Features de Entrada (6 features)

Todas conocidas al **inicio del día**:

```python
features = [
    'dayOfWeek',              # 1-7 (Domingo-Sábado)
    'isWeekend',              # 0 o 1
    'isHoliday',              # 0 o 1
    'totalMeetingCount',      # Número de reuniones
    'hasImportantDeadline',   # 0 o 1
    'earlyMeetingCount',      # Reuniones antes 10am
]
```

## 💻 Uso en Swift

```swift
import CoreML

class InsightsPredictor {
    var model: ProductivityClassifier?
    
    func predictToday(dayOfWeek: Int, totalMeetings: Int, 
                      hasDeadline: Bool, earlyMeetings: Int) -> DailyInsight {
        
        let input = ProductivityInput(
            dayOfWeek: dayOfWeek,
            isWeekend: (dayOfWeek == 1 || dayOfWeek == 7) ? 1 : 0,
            isHoliday: 0,
            totalMeetingCount: totalMeetings,
            hasImportantDeadline: hasDeadline ? 1 : 0,
            earlyMeetingCount: earlyMeetings
        )
        
        guard let output = try? model?.prediction(input: input) else {
            return DailyInsight(category: .normal, hours: 8, deepWork: 150)
        }
        
        let categories: [ProductivityCategory] = [.light, .normal, .heavy]
        let cat = categories[Int(output.productivityCategory)]
        
        return DailyInsight(
            category: cat,
            hours: output.predictedHours,
            deepWork: output.predictedDeepWork
        )
    }
}

struct DailyInsight {
    let category: ProductivityCategory
    let hours: Double
    let deepWork: Double
    
    var emoji: String {
        switch category {
        case .light: return "🌱"
        case .normal: return "⚡"
        case .heavy: return "🔥"
        }
    }
    
    var description: String {
        return "\(emoji) Día \(category.rawValue) • ~\(String(format: "%.1f", hours))h • ~\(Int(deepWork))min Deep Work"
    }
}
```

## 📱 UI para Insights

```swift
// Al inicio del día
VStack(alignment: .leading, spacing: 12) {
    Text("Predicción de hoy")
        .font(.headline)
    
    HStack {
        Image(systemName: insight.emoji)
        Text(insight.description)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(10)
    
    // Comparación con promedio
    HStack {
        Text("vs tu promedio:")
            .font(.caption)
        
        if insight.hours > userAverageHours {
            Label("+\(String(format: "%.1f", insight.hours - userAverageHours))h", 
                  systemImage: "arrow.up")
                .foregroundColor(.orange)
        } else {
            Label("-\(String(format: "%.1f", userAverageHours - insight.hours))h", 
                  systemImage: "arrow.down")
                .foregroundColor(.green)
        }
    }
    .font(.caption)
}
```

## 📊 Distribución de Datos

```
🌱 Light:   6.6%  (≤6h de trabajo)
⚡ Normal:  72.5% (7-8h de trabajo) ← Mayoría
🔥 Heavy:   20.9% (≥9h de trabajo)
```

## 🎯 Ejemplos

| Día | Reuniones | Deadline | Predicción |
|-----|-----------|----------|------------|
| Lunes tranquilo | 2 | No | ⚡ Normal, ~8.0h, ~137min |
| Lunes pesado | 5 | Sí | ⚡ Normal, ~8.2h, ~244min |
| Viernes light | 1 | No | ⚡ Normal, ~7.9h, ~147min |

## 🔗 Para Create ML

1. Abrir **Create ML**
2. Crear **Tabular Classifier** (para categoría) y **Tabular Regressor** (para horas/deep work)
3. Cargar `insights_dataset.csv`
4. Seleccionar targets: `productivityCategory`, `workDuration`, `deepWorkMinutes`
5. Entrenar y exportar modelos

## ⚡ Accuracy Esperado

| Métrica | Valor |
|---------|-------|
| Categoría correcta | 69% |
| Categoría ±1 | ~95% |
| Horas (MAE) | ±0.5h |
| Deep Work (MAE) | ±43min |

## 🎨 Beneficios para UI

1. **Simple**: 3 categorías claras (emojis)
2. **Accionable**: Usuario sabe qué esperar
3. **Sin preocupaciones**: No hay "hora exacta" que fallar
4. **Contextual**: Se compara con su propio promedio
