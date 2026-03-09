# Insights Dashboard ML

Sistema de Machine Learning para predecir el tipo de día laboral y eficiencia.

## 🚀 Inicio Rápido

Para entrenar el modelo en **Create ML**:

1. Lee la guía: **`CREATE_ML_GUIDE.md`**
2. Usa el dataset: **`CREATE_ML_READY.csv`**
3. Sigue los pasos para entrenar y exportar

## 🎯 Qué Predice

El modelo clasifica el día en **7 categorías**:

| Código | Categoría | Emoji | % Dataset |
|--------|-----------|-------|-----------|
| 0 | Rest | 🌴 | 7.6% |
| 1 | Calm | 🧘 | 10.4% |
| 2 | Balanced | ⚡ | 13.6% |
| 3 | Busy | 📅 | 19.7% |
| 4 | Intense | 🔥 | 36.2% |
| 5 | DeepFocus | 🎯 | 8.0% |
| 6 | BurnoutRisk | 🚨 | 4.6% |

## 📁 Archivos Principales

### Para Create ML
- **`CREATE_ML_READY.csv`** - Dataset optimizado (8 features, enteros)
- **`CREATE_ML_WITH_NAMES.csv`** - Versión con nombres para referencia
- **`CREATE_ML_GUIDE.md`** - Guía paso a paso

### Datasets Completos
- `training_data.csv` - Datos de entrenamiento (2,121 registros)
- `validation_data.csv` - Datos de validación (454 registros)
- `testing_data.csv` - Datos de prueba (455 registros)
- `complete_dataset.csv` - Dataset completo (3,030 registros)

### Scripts
- `generate_insight_dataset.py` - Genera datos sintéticos
- `train_simple.py` - Entrena modelo con Python
- `train_and_export_coreml.py` - Intenta exportar a CoreML

### Modelos Entrenados
- `InsightsClassifier.pkl` - Modelo Python entrenado
- `model_config.json` - Configuración del modelo

## 📊 Features (8 inputs)

Todas son **enteros** y se conocen al inicio del día:

```
dayOfWeek              1-7 (1=Domingo, 2=Lunes...)
isWeekend              0/1
totalMeetingCount      0-10
hasImportantDeadline   0/1
backToBackMeetings     0/1
freeTimeBlocks         0-9
meetingDensityScore    0-100
interruptionRiskScore  0-100
```

## 🎯 Target (1 output)

```
dayCategory            0-6 (categoría del día)
```

## 📖 Documentación

- **`CREATE_ML_GUIDE.md`** - Guía completa para Create ML
- Incluye: paso a paso, troubleshooting, código Swift

## 💻 Uso en Swift (después de exportar)

```swift
let model = DayCategoryClassifier()

let result = model.predict(
    dayOfWeek: 2,              // Lunes
    isWeekend: 0,
    totalMeetingCount: 5,
    hasImportantDeadline: 1,
    backToBackMeetings: 1,
    freeTimeBlocks: 2,
    meetingDensityScore: 50,
    interruptionRiskScore: 40
)

// result = 4 (Intense)
let names = ["🌴", "🧘", "⚡", "📅", "🔥", "🎯", "🚨"]
print("Hoy: \(names[result])")
```

## ⚠️ Importante

Si Create ML no funciona, el modelo entrenado en Python (`InsightsClassifier.pkl`) está listo para usar con:
- Backend Python (Flask/FastAPI)
- Predicciones offline
- Otras herramientas ML

## 📊 Performance Esperada

| Métrica | Valor |
|---------|-------|
| Training Accuracy | 100% (datos sintéticos) |
| Validation Accuracy | 100% (datos sintéticos) |
| Real-world Expected | 65-75% |

## 🔄 Regenerar Datos

```bash
cd "CoreML Training Data"
python3 generate_insight_dataset.py
```

## 📞 Soporte

Si tienes problemas con Create ML:
1. Revisa `CREATE_ML_GUIDE.md` sección "Troubleshooting"
2. Asegúrate de seleccionar **"Tabular Classification"** (no Regressor)
3. Verifica que el target sea tipo **"Categorical"**
