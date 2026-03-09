# Guía Create ML - Dataset con Enteros

Dataset listo para usar en Create ML con categorías numéricas (más eficiente).

## 📁 Archivo a usar

**`CREATE_ML_READY.csv`** (2,121 registros, 8 features + target)

## 📊 Estructura

### Features (8 columnas de entrada):
| Columna | Tipo | Rango | Descripción |
|---------|------|-------|-------------|
| dayOfWeek | Int | 1-7 | Día de la semana (1=Domingo) |
| isWeekend | Int | 0-1 | 1 si es fin de semana |
| totalMeetingCount | Int | 0-10 | Total de reuniones |
| hasImportantDeadline | Int | 0-1 | 1 si tiene deadline |
| backToBackMeetings | Int | 0-1 | 1 si tiene reuniones seguidas |
| freeTimeBlocks | Int | 0-9 | Bloques libres de 60+ min |
| meetingDensityScore | Int | 0-100 | Densidad de reuniones |
| interruptionRiskScore | Int | 0-100 | Riesgo de interrupciones |

### Target (1 columna de salida):
| Columna | Tipo | Rango | Descripción |
|---------|------|-------|-------------|
| dayCategory | Int | 0-6 | Categoría del día |

**Mapeo de categorías:**
```
0 = Rest (🌴)
1 = Calm (🧘)
2 = Balanced (⚡)
3 = Busy (📅)
4 = Intense (🔥)
5 = DeepFocus (🎯)
6 = BurnoutRisk (🚨)
```

## 🚀 Instrucciones Paso a Paso

### Paso 1: Crear Proyecto
1. Abre **Create ML** (Xcode → Open Developer Tool → Create ML)
2. Click **"New Project"**
3. Selecciona **"Tabular Classification"** ⚠️ IMPORTANTE
4. Nombre: `DayCategoryClassifier`
5. Click **"Next"**

### Paso 2: Configurar Datos
1. En **"Training Data"**, click **"Select"**
2. Selecciona el archivo **`CREATE_ML_READY.csv`**
3. Create ML detectará automáticamente las columnas

### Paso 3: Configurar Target (IMPORTANTE)
1. En la sección **"Target"**, selecciona: `dayCategory`
2. **Verifica el tipo**: Debe decir **"Categorical"** o "Category"
   - Si dice "Continuous" o "Numerical", haz clic en el dropdown y cambia a "Categorical"
3. En **"Features"**, selecciona las 8 features (o deja que seleccione todas menos el target)

### Paso 4: Configurar Algoritmo
1. En **"Algorithm"**, selecciona: **"Boosted Trees"** (recomendado) o "Random Forest"
2. Deja los parámetros por defecto (son buenos)

### Paso 5: Entrenar
1. Click en **"Train"** (arriba a la derecha)
2. Espera a que termine (unos segundos)

### Paso 6: Verificar Resultados
Debes ver métricas como:
```
Accuracy: 70-80%
Precision: 0.70-0.80
Recall: 0.70-0.80
```

**Si ves "RMSE" o "Maximum Error":** Estás en modo Regresión, no Clasificación. Vuelve al Paso 3 y asegúrate de que el target sea "Categorical".

### Paso 7: Exportar
1. Click en **"Get"** o **"Export"**
2. Guarda como: `DayCategoryClassifier.mlmodel`
3. Arrastra el archivo a tu proyecto Xcode

## 🔍 Cómo Verificar que Está Correcto

### ✅ BUENO (Clasificación correcta):
- En la pestaña "Evaluation" ves: **Accuracy**, **Precision**, **Recall**
- Hay una matriz de confusión (confusion matrix)
- Hay un "Classification Report" con F1-Score

### ❌ MALO (Regresión incorrecta):
- Ves: **RMSE**, **Maximum Error**
- No hay matriz de confusión
- Los valores predichos son decimales (ej: 3.45)

## 💻 Código Swift de Ejemplo

```swift
import CoreML

// El modelo generado automáticamente por Xcode
class DayCategoryClassifier {
    func predict(
        dayOfWeek: Int,
        isWeekend: Int,
        totalMeetingCount: Int,
        hasImportantDeadline: Int,
        backToBackMeetings: Int,
        freeTimeBlocks: Int,
        meetingDensityScore: Int,
        interruptionRiskScore: Int
    ) -> Int {
        // Retorna 0-6
    }
}

// Uso
let model = DayCategoryClassifier()

let category = model.predict(
    dayOfWeek: 2,              // Lunes
    isWeekend: 0,
    totalMeetingCount: 5,
    hasImportantDeadline: 1,
    backToBackMeetings: 1,
    freeTimeBlocks: 2,
    meetingDensityScore: 50,
    interruptionRiskScore: 40
)

// Mapear a nombre
let names = ["🌴 Rest", "🧘 Calm", "⚡ Balanced", "📅 Busy", 
             "🔥 Intense", "🎯 DeepFocus", "🚨 BurnoutRisk"]

print("Hoy es un día: \(names[category])")
// Output: Hoy es un día: 🔥 Intense
```

## 🎯 Entrenar Otros Modelos (Opcional)

Para entrenar los otros targets, repite el proceso con el dataset completo:

### Productivity Score (Regresión)
1. Usa `training_data.csv` completo
2. Target: `productivityScore` (0-100)
3. Tipo: **"Regressor"** (NO Classification)
4. Algoritmo: Random Forest

### Focus Score (Regresión)
1. Target: `focusScore`
2. Tipo: Regressor

### Stress Level (Regresión)
1. Target: `stressLevel`
2. Tipo: Regressor

## ⚠️ Troubleshooting

### Problema: "Data must be int or double"
**Solución**: Asegúrate de usar `CREATE_ML_READY.csv` donde todas las columnas son enteros.

### Problema: Target aparece como "Continuous"
**Solución**: 
1. Haz clic en la columna `dayCategory`
2. En el panel derecho, cambia "Type" de "Continuous" a "Categorical"
3. O selecciona "Use for Classification"

### Problema: Accuracy muy baja (<50%)
**Solución**: 
- Verifica que el target esté correctamente configurado
- Asegúrate de usar Classification, no Regression
- Revisa que las features incluyan las 8 columnas

### Problema: No puedo seleccionar "Tabular Classification"
**Solución**: 
- Create ML debe ser versión 3.0 o superior
- Actualiza Xcode si es necesario

## 📊 Resultados Esperados

Con `CREATE_ML_READY.csv`:

| Métrica | Valor Esperado |
|---------|---------------|
| Accuracy | 70-80% |
| Precision (weighted) | 0.70-0.80 |
| Recall (weighted) | 0.70-0.80 |
| F1-Score | 0.70-0.80 |

Las clases con más ejemplos (Intense=4, Busy=3) tendrán mejor accuracy.
Las clases con pocos ejemplos (BurnoutRisk=6, Rest=0) serán más difíciles.

## ✅ Checklist Final

Antes de exportar el modelo, verifica:
- [ ] Proyecto es "Tabular Classification"
- [ ] Target es `dayCategory` tipo "Categorical"
- [ ] Features son las 8 columnas (todas Int)
- [ ] Algoritmo es "Boosted Trees" o "Random Forest"
- [ ] Accuracy está entre 65-85%
- [ ] No hay métricas de RMSE (solo clasificación)
- [ ] Matriz de confusión se ve razonable
