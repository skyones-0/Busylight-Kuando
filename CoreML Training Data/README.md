# ML Training Data for Busylight

## 🎯 Problema Resuelto: Modelo Confiable

**Tu problema:** 40% confidence, 18% validation en Create ML  
**Causa:** Dataset desbalanceado + 21 clases (horas 0-20) es demasiado complejo  
**Solución:** Categorías de hora + dataset balanceado

---

## 📊 Resultados Comparativos

| Enfoque | Training | Validation | Testing | Estado |
|---------|----------|------------|---------|--------|
| 21 clases (horas) | 60% | 22% | 18% | ❌ Malo |
| **6 categorías** | **77%** | **69%** | **65%** | ✅ **Bueno** |

### Categorías de Hora (Recomendado)

| Categoría | Horas | Accuracy |
|-----------|-------|----------|
| None | 0 (no trabaja) | 100% |
| Early | 6-8am | 96% |
| Morning | 9-10am | 60% |
| Midday | 11-12pm | 33% |
| Afternoon | 1-4pm | 20% |
| Evening | 5-8pm | 77% |

---

## 📁 Datasets Disponibles

### Original (Balanceado)
- `work_schedule_training_data.csv` - 1,470 registros
- `work_schedule_validation.csv` - 315 registros  
- `testing_data.csv` - 315 registros

### Con Categorías (Recomendado para Create ML)
- `work_schedule_training_categorical.csv` - 6 clases
- `work_schedule_validation_categorical.csv` - 6 clases
- `work_schedule_testing_categorical.csv` - 6 clases

---

## 🚀 Cómo Usar en Create ML (PASO A PASO)

### Opción A: Categorías (65% accuracy - Recomendado)

1. **Abre Create ML** en Xcode
2. **Crea nuevo proyecto** → Tabular Regression (o Classification)
3. **Importa datasets:**
   - Training: `work_schedule_training_categorical.csv`
   - Validation: `work_schedule_validation_categorical.csv`
   - Testing: `work_schedule_testing_categorical.csv`
4. **Configura:**
   - Target: `startHour_cat` (0-5)
   - Features: todas excepto `startHour`, `endHour`, `startHour_cat_name`
   - Algorithm: **Random Forest**
   - Max Depth: **8**
   - Min Samples Per Leaf: **5**
5. **Entrena**
6. **Resultado esperado:** 65-70% accuracy

### Opción B: Regresión con MAE ~2 horas

Si necesitas horas exactas:
1. Usa los datasets originales (sin `_categorical`)
2. Usa **Linear Regression** o **Random Forest Regressor**
3. Target: `startHour`
4. **Acepta MAE de ~2 horas** (es lo mejor posible con estos features)

---

## 🧪 Scripts Python

### Entrenar modelo categorizado:
```bash
cd "CoreML Training Data"
python3 train_models_v3.py
```

### Entrenar modelo horas exactas:
```bash
python3 train_models_v2.py
```

### Regenerar datos balanceados:
```bash
python3 generate_balanced_data.py
```

---

## 💡 Recomendación Final

**Para tu app Busylight:**

1. **Usa CATEGORÍAS en Create ML** (65% accuracy)
2. **En la UI muestra rangos:** "Mañana (9-10am)" en lugar de "9:00 exacto"
3. **Los usuarios prefieren rangos** más que horas exactas predichas

### Ejemplo en UI:
```
Predicción para mañana:
🌅 Early Bird    (6-8am)
🌇 Morning       (9-10am)  ← Seleccionado
☀️  Midday        (11-12pm)
🌤️  Afternoon     (1-4pm)
🌆 Evening        (5-8pm)
```

---

## 📈 Por qué mejora con categorías

| Horas Exactas | Categorías |
|---------------|------------|
| 21 clases | 6 clases |
| Hour 11: solo 70 ejemplos | Early: 560 ejemplos |
| Modelo confundido | Modelo aprende patrones claros |
| 20% accuracy | 65% accuracy |

---

## 🔧 Si aún quieres horas exactas

La realidad es que predecir horas exactas (0-20) es inherentemente difícil porque:
- Los humanos somos impredecibles
- Los patrones de trabajo varían mucho
- Con las features actuales, **MAE de ~2 horas es el límite técnico**

**Soluciones:**
1. Añadir más features (clima, temporada, deadlines)
2. Usar datos de varios meses (más contexto)
3. Personalización por usuario (aprende patrones individuales)

---

## Total de Registros
- Training: 1,470 (70 por cada hora 0-20)
- Validation: 315
- Testing: 315
- **Total: 2,100 registros balanceados**
