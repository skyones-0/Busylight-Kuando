# Busylight ML Training Data

Dataset y scripts para entrenar el modelo de predicción de horarios de trabajo.

## 🎯 Versión Final (V11)

**Estrategia**: Predicción de hora de entrada (`startHour`) con duración típica del usuario.

**Accuracy esperado**:
- Start Hour exacto: **74%**
- Start Hour ±1h: **97%**
- End Hour (calculado): **54%** exacto, **92%** ±1h

---

## 📁 Archivos

### Datasets (para Create ML)

| Archivo | Registros | Descripción |
|---------|-----------|-------------|
| `training_data.csv` | 1,400 | Dataset de entrenamiento |
| `validation_data.csv` | 300 | Dataset de validación |
| `testing_data.csv` | 300 | Dataset de prueba |
| `full_dataset.csv` | 2,000 | Dataset completo |
| `work_schedule_FINAL_for_createml.csv` | 1,400 | Dataset optimizado para Create ML |

### Scripts

| Archivo | Descripción |
|---------|-------------|
| `train_model.py` | Script de entrenamiento y evaluación |
| `generate_dataset.py` | Generador de datos sintéticos realistas |

---

## 📊 Estructura del Dataset

### Features (13 - todas automáticas)

```
# Temporales (sistema)
dayOfWeek          # 1=Domingo, 2=Lunes, ..., 7=Sábado
isWeekend          # 0 o 1
isHoliday          # 0 o 1

# Calendario (integración Calendar.app)
totalMeetingCount       # Número de reuniones del día
hasImportantDeadline    # 0 o 1
earlyMeetingCount       # Reuniones antes de 10am

# Trabajo (tu app las mide)
sessionCount       # Número de sesiones pomodoro
deepWorkMinutes    # Minutos de trabajo profundo
taskCompleted      # Tareas completadas

# Calculadas automáticamente
deepWorkEfficiency      # deepWork / (deepWork + shallowWork)
meetingDensity          # reuniones / 10
earlyMeetingRatio       # earlyMeetings / totalMeetings
intensityRatio          # deepWork / (meetings * 60)
```

### Targets

```
startHour          # 0, 7, 8, 9, 10, 11 (hora de entrada)
workDuration       # 0, 7, 8, 9 (horas trabajadas)
endHour            # Calculado: start + duration
```

---

## 🚀 Uso en Create ML

### Paso 1: Entrenar modelo de Start Hour

1. Abrir **Create ML** ( Xcode > Open Developer Tool > Create ML)
2. Crear nuevo proyecto: **Tabular Classification**
3. Cargar: `work_schedule_FINAL_for_createml.csv`
4. Configuración:
   - **Target**: `startHour`
   - **Features**: Seleccionar todas excepto `workDuration` y `endHour`
   - **Algorithm**: Random Forest
   - **Validation**: Automatic (20%)
5. Click en **Train**
6. Exportar como: `StartHourPredictor.mlmodel`

### Paso 2: (Opcional) Entrenar modelo de Duration

Si quieres predecir duración en lugar de usar el promedio:

1. Mismo proceso pero **Target**: `workDuration`
2. Exportar como: `DurationPredictor.mlmodel`

---

## 💻 Integración en Swift

```swift
import CoreML

class SchedulePredictor {
    // Configuración del usuario (calculada de promedio histórico)
    let userBaseHour: Int = 9        // Hora base configurada
    let typicalDuration: Int = 8     // Duración promedio del usuario
    
    // Modelo CoreML
    var startHourModel: MLModel?
    
    init() {
        // Cargar modelo
        guard let modelURL = Bundle.main.url(forResource: "StartHourPredictor", 
                                              withExtension: "mlmodelc"),
              let model = try? MLModel(contentsOf: modelURL) else {
            print("Error cargando modelo")
            return
        }
        self.startHourModel = model
    }
    
    func predictSchedule(dayOfWeek: Int, 
                         totalMeetings: Int,
                         hasDeadline: Int,
                         deepWorkMinutes: Int) -> (start: Int, end: Int)? {
        
        guard let model = startHourModel else { return nil }
        
        // Calcular features automáticas
        let efficiency = Double(deepWorkMinutes) / 480.0
        let meetingDensity = Double(totalMeetings) / 10.0
        
        // Input para el modelo
        let input: [String: MLFeatureValue] = [
            "dayOfWeek": .int64(dayOfWeek),
            "isWeekend": .int64(dayOfWeek == 1 || dayOfWeek == 7 ? 1 : 0),
            "isHoliday": .int64(0),
            "totalMeetingCount": .int64(totalMeetings),
            "hasImportantDeadline": .int64(hasDeadline),
            "earlyMeetingCount": .int64(0),
            "sessionCount": .int64(deepWorkMinutes / 90),
            "deepWorkMinutes": .int64(deepWorkMinutes),
            "taskCompleted": .int64(deepWorkMinutes / 50),
            "deepWorkEfficiency": .double(efficiency),
            "meetingDensity": .double(meetingDensity),
            "earlyMeetingRatio": .double(0),
            "intensityRatio": .double(0)
        ]
        
        // Predecir
        do {
            let provider = try MLDictionaryFeatureProvider(dictionary: input)
            let output = try model.prediction(from: provider)
            let startHour = Int(output.featureValue(for: "startHour")?.int64Value ?? 9)
            
            // Calcular end
            let endHour = startHour > 0 ? startHour + typicalDuration : 0
            
            return (startHour, endHour)
        } catch {
            print("Error en predicción: \(error)")
            return nil
        }
    }
}
```

---

## 📈 Rendimiento Esperado

| Métrica | Valor |
|---------|-------|
| Accuracy Start Hour exacto | 74% |
| Accuracy Start Hour ±1h | 97% |
| Accuracy End Hour exacto | 54% |
| Accuracy End Hour ±1h | 92% |
| MAE Duración | 0.6h |

---

## 🔧 Generar Nuevo Dataset

Si necesitas regenerar los datos:

```bash
cd "CoreML Training Data"
python3 generate_dataset.py
```

Esto creará nuevos datasets con la misma distribución pero datos diferentes.

---

## 📝 Notas

- **workDuration** es muy estable: 59% de casos son exactamente 8 horas
- La **hora de entrada** varía alrededor de 9:00 am (±1-2 horas)
- **No se requiere input del usuario** para las features (todas son calculables)
- El modelo funciona mejor con **datos históricos reales** del usuario (3+ semanas)

---

## 📊 Distribución de Datos

```
Hora de entrada (startHour):
   7:00  -  4.7% (llega 2h antes)
   8:00  - 19.4% (llega 1h antes)
   9:00  - 41.2% (a la hora) ← Moda
  10:00  - 19.1% (llega 1h después)
  11:00  -  5.8% (llega 2h después)
   0:00  -  9.8% (no trabaja)

Duración (workDuration):
   7h  - 19.7%
   8h  - 59.4% ← Moda
   9h  - 20.9%
```
