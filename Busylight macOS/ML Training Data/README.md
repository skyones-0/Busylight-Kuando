# Guía de Entrenamiento CoreML para Busylight

Esta carpeta contiene datos y guías para entrenar tu propio modelo de predicción de horarios usando Create ML de Xcode.

---

## 📁 Archivos Incluidos

| Archivo | Descripción |
|---------|-------------|
| `work_schedule_training_data.csv` | 30 días de datos de trabajo (sin fechas) - Ideal para entrenamiento rápido |
| `work_schedule_with_holidays.csv` | 30 días con fechas reales y festivos marcados - Más realista |

---

## 📊 Estructura de los Datos

### Columnas del CSV:

| Columna | Tipo | Descripción | Ejemplo |
|---------|------|-------------|---------|
| `dayOfWeek` | Número | Día de la semana (1=Domingo, 2=Lunes...) | 2 (Lunes) |
| `isWeekend` | Booleano | ¿Es fin de semana? (0=no, 1=sí) | 0 |
| `isHoliday` | Booleano | ¿Es festivo? (0=no, 1=sí) | 0 |
| `sessionCount` | Número | Número de sesiones Pomodoro completadas | 5 |
| `deepWorkMinutes` | Número | Minutos de trabajo profundo | 120 |
| `calendarEventCount` | Número | Eventos en calendario ese día | 3 |
| `startHour` | Número (Target) | Hora de inicio (0-23) | 8 |
| `endHour` | Número (Target) | Hora de fin (0-23) | 17 |

**Nota:** `startHour` y `endHour` son los valores que el modelo intentará predecir.

---

## 🚀 Paso a Paso: Entrenar con Create ML

### Paso 1: Abrir Create ML

1. Abre **Xcode**
2. Ve al menú: **Xcode** → **Open Developer Tool** → **Create ML**
3. Selecciona **New Document** (⌘N)

### Paso 2: Elegir el Tipo de Modelo

1. Selecciona la pestaña **Tabular** (izquierda)
2. Haz doble clic en **Tabular Regression** (Regresión Tabular)
3. Dale un nombre: `BusylightWorkSchedulePredictor`
4. Click en **Next** → Guarda el proyecto

### Paso 3: Cargar los Datos

1. En la sección **Training Data**, click en **Select...**
2. Elige el archivo `work_schedule_training_data.csv` o `work_schedule_with_holidays.csv`
3. Create ML detectará automáticamente las columnas

### Paso 4: Configurar el Target (Objetivo)

1. En **Target** (columna a predecir), selecciona primero **`startHour`**
2. Verás que las demás columnas aparecen como **Features** automáticamente
3. En **Algorithm**, selecciona **Random Forest** (mejor precisión)
4. En **Parameters**:
   - **Max iterations**: 100
   - **Max depth**: 6

### Paso 5: Entrenar el Modelo

1. Click en el botón **Train** (arriba a la derecha)
2. Espera ~10-30 segundos
3. Verás métricas como:
   - **Root Mean Squared Error (RMSE)**: Cuanto menor, mejor (ideal < 1.5)
   - **Maximum Error**: Error máximo cometido

### Paso 6: Probar el Modelo

1. Ve a la pestaña **Evaluation**
2. Ingresa valores de prueba:
   ```
   dayOfWeek: 2 (Lunes)
   isWeekend: 0
   isHoliday: 0
   sessionCount: 5
   deepWorkMinutes: 120
   calendarEventCount: 3
   ```
3. Click en **Predict**
4. Debería predecir algo cerca de `startHour: 8`

### Paso 7: Exportar el Modelo

1. Ve a la pestaña **Output** (izquierda)
2. Click en **Get** → Elige ubicación
3. Se guardará como `BusylightWorkSchedulePredictor.mlmodel`

### Paso 8: Entrenar Segundo Modelo (endHour)

Repite pasos 3-7 pero cambia:
- **Target**: `endHour` (en lugar de startHour)
- Nombre: `BusylightWorkSchedulePredictorEnd`

---

## 📱 Usar el Modelo en tu App

### Opción A: Reemplazar modelo existente

1. Arrastra los archivos `.mlmodel` generados a tu proyecto Xcode
2. Asegúrate de que estén en el target "Busylight macOS"
3. El código usará automáticamente el nuevo modelo

### Opción B: Probar predicción en código

```swift
import CoreML

// Cargar modelo
let config = MLModelConfiguration()
let model = try! BusylightWorkSchedulePredictor(configuration: config)

// Crear input
let input = BusylightWorkSchedulePredictorInput(
    dayOfWeek: 2,
    isWeekend: 0,
    isHoliday: 0,
    sessionCount: 5,
    deepWorkMinutes: 120,
    calendarEventCount: 3
)

// Predecir
let output = try! model.prediction(input: input)
print("Hora de inicio predicha: \(output.startHour)")
```

---

## 🎯 Consejos para Mejores Resultados

### 1. Más Datos = Mejor Precisión
- Mínimo: 7 días (1 semana)
- Recomendado: 30+ días
- Ideal: 3+ meses

### 2. Variedad en los Datos
Incluye días:
- Productivos (más sesiones, más deep work)
- Ligeros (pocas sesiones)
- Festivos (isHoliday=1, horas=0)
- Fines de semana (isWeekend=1)

### 3. Evitar Overfitting
- No uses datos de solo 1 semana repetidos
- Incluye variaciones reales
- Usa Random Forest en lugar de Linear Regression para datos complejos

---

## 📊 Interpretar Resultados

### Métricas de Evaluación:

| Métrica | Bueno | Regular | Malo |
|---------|-------|---------|------|
| **RMSE** | < 1.0 | 1.0 - 2.0 | > 2.0 |
| **Max Error** | < 2 | 2 - 4 | > 4 |

**RMSE** = Error promedio en horas. Si es 0.5, significa que el modelo se equivoca ±30 minutos en promedio.

---

## 🔧 Solución de Problemas

### "Training failed" o errores

1. **Verifica el CSV**:
   - No debe tener celdas vacías
   - Solo números (no texto excepto en headers)
   - Usa punto (.) para decimales, no coma (,)

2. **Suficientes datos**:
   - Mínimo 5 filas
   - Recomendado: 20+ filas

3. **Variación en target**:
   - Asegúrate de que `startHour` tenga diferentes valores (no todo 9)
   - Si todos son iguales, el modelo no puede aprender

### Predicciones constantes

Si siempre predice lo mismo (ej: siempre 9:00):
- Necesitas más variedad en tus datos de entrenamiento
- Agrega días donde empiezas a diferentes horas

---

## 🎓 Ejemplo: Crear tus Propios Datos

Copia este formato en Excel o Numbers y exporta como CSV:

```csv
dayOfWeek,isWeekend,isHoliday,sessionCount,deepWorkMinutes,calendarEventCount,startHour,endHour
2,0,0,5,120,3,8,17
3,0,0,6,150,4,8,18
...
```

**Tip**: Rastrea tus patrones reales por 2-3 semanas y luego entrena el modelo con esos datos para predicciones personalizadas.

---

## 📚 Recursos Adicionales

- [Documentación Create ML](https://developer.apple.com/documentation/createml)
- [Core ML Tools](https://coremltools.readme.io/) - Para convertir modelos de Python
- [Machine Learning de Apple](https://developer.apple.com/machine-learning/)

---

¿Problemas? Revisa los logs de la app en Console.app para ver mensajes de error detallados.
