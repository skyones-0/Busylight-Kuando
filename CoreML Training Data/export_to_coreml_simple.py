#!/usr/bin/env python3
"""
Exportación simple a CoreML usando solamente numpy y coremltools
Sin dependencia de sklearn converter
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import warnings
warnings.filterwarnings('ignore')

print("="*70)
print("🚀 ENTRENAMIENTO Y EXPORTACIÓN MANUAL A COREML")
print("="*70)

# 1. Cargar datos
print("\n📊 Cargando datos...")
df = pd.read_csv('work_schedule_FINAL_for_createml.csv')

feature_cols = [
    'dayOfWeek', 'isWeekend', 'isHoliday',
    'totalMeetingCount', 'hasImportantDeadline', 'earlyMeetingCount',
    'sessionCount', 'deepWorkMinutes', 'taskCompleted',
    'deepWorkEfficiency', 'meetingDensity', 'earlyMeetingRatio', 'intensityRatio'
]

X = df[feature_cols]
y = df['startHour']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

print(f"   Train: {len(X_train)}, Test: {len(X_test)}")
print(f"   Features: {len(feature_cols)}")

# 2. Entrenar
print("\n🎯 Entrenando Random Forest...")
model = RandomForestClassifier(
    n_estimators=100,  # Menos árboles para archivo más pequeño
    max_depth=12,
    min_samples_leaf=2,
    random_state=42
)
model.fit(X_train, y_train)

test_acc = accuracy_score(y_test, model.predict(X_test))
test_acc_pm1 = (np.abs(model.predict(X_test) - y_test) <= 1).mean()
print(f"   ✅ Test accuracy: {test_acc:.1%}")
print(f"   ✅ Test accuracy ±1h: {test_acc_pm1:.1%}")

# 3. Exportar usando coremltools de forma básica
print("\n📦 Exportando a CoreML...")

try:
    import coremltools as ct
    print(f"   coremltools versión: {ct.__version__}")
    
    # Usar el convertidor universal (si está disponible)
    try:
        # Para modelos de sklearn, intentar convert
        coreml_model = ct.converters.sklearn.convert(
            model,
            feature_cols,
            "startHour"
        )
        
        coreml_model.save("StartHourPredictor.mlmodel")
        print("   ✅ Exportado exitosamente!")
        
    except Exception as e:
        print(f"   ⚠️  Converter falló: {e}")
        print("\n   Creando archivo manualmente...")
        
        # Método alternativo: Usar spec directamente
        from coremltools.proto import Model_pb2
        from coremltools.models import datatypes
        
        # Crear spec básico
        spec = Model_pb2.Model()
        spec.specificationVersion = 4
        
        # Input features
        for col in feature_cols:
            input_feature = spec.description.input.add()
            input_feature.name = col
            input_feature.type.doubleType.MergeFromString(b"")
        
        # Output
        output = spec.description.output.add()
        output.name = "startHour"
        output.type.int64Type.MergeFromString(b"")
        
        # Metadata
        spec.description.predictedFeatureName = "startHour"
        
        # NOTA: Esto requiere llenar los árboles manualmente, es muy complejo
        print("   ❌ Requiere implementación manual compleja")
        print("\n💡 ALTERNATIVA RECOMENDADA:")
        print("   Usar Create ML en Xcode con el CSV exportado")
        
except ImportError:
    print("   ❌ coremltools no instalado")

# 4. Guardar como pickle (siempre funciona)
print("\n💾 Guardando modelo...")
import pickle
with open('StartHourPredictor.pkl', 'wb') as f:
    pickle.dump(model, f)
print("   ✅ StartHourPredictor.pkl")

# 5. Exportar predicciones para lookup table
print("\n📊 Generando lookup table...")
predictions = []
for _, row in X_test.head(100).iterrows():
    pred = model.predict([row.values])[0]
    predictions.append({
        'features': row.to_dict(),
        'prediction': int(pred)
    })

import json
with open('predictions_sample.json', 'w') as f:
    json.dump(predictions, f, indent=2)
print("   ✅ predictions_sample.json (100 ejemplos)")

# 6. Crear CSV optimizado para Create ML
print("\n📄 Creando CSV para Create ML...")
df_export = df[feature_cols + ['startHour']].copy()

# Asegurar que todo son enteros (Create ML funciona mejor así)
for col in feature_cols:
    if col in ['deepWorkEfficiency', 'meetingDensity', 'earlyMeetingRatio', 'intensityRatio']:
        df_export[col] = (df_export[col] * 100).round().astype(int)  # Convertir a enteros 0-100
    else:
        df_export[col] = df_export[col].astype(int)

df_export['startHour'] = df_export['startHour'].astype(int)
df_export.to_csv('CREATE_ML_INPUT.csv', index=False)
print("   ✅ CREATE_ML_INPUT.csv (todo en enteros)")

print("\n" + "="*70)
print("✅ PROCESO COMPLETADO")
print("="*70)
print("""
Archivos generados:
   💾 StartHourPredictor.pkl - Modelo entrenado (Python)
   📊 predictions_sample.json - Ejemplos de predicciones
   📄 CREATE_ML_INPUT.csv - Dataset listo para Create ML

PARA CREAR EL MLMODEL:
   Opción 1: Usar Create ML en Xcode
      - Abre Xcode → Open Developer Tool → Create ML
      - Crea Tabular Classification
      - Carga CREATE_ML_INPUT.csv
      - Target: startHour
      - Algoritmo: Random Forest
      - Exporta el .mlmodel

   Opción 2: Instalar sklearn 1.5.1
      pip install scikit-learn==1.5.1
      python export_to_coreml_simple.py

   Opción 3: Usar el modelo .pkl con Python
      Ver ejemplo en el código generado
""")

# 7. Código de ejemplo para usar el modelo pickle
print("="*70)
print("📝 CÓDIGO EJEMPLO PARA USAR EL MODELO .pkl")
print("="*70)
code_example = '''
import pickle
import numpy as np

# Cargar modelo
with open('StartHourPredictor.pkl', 'rb') as f:
    model = pickle.load(f)

# Predecir
def predict_start_hour(day_of_week, is_weekend, deep_work_minutes, 
                       total_meetings, task_completed):
    """
    Predice la hora de inicio del trabajo
    """
    features = [
        day_of_week,           # dayOfWeek
        is_weekend,            # isWeekend
        0,                     # isHoliday (asumir no)
        total_meetings,        # totalMeetingCount
        0,                     # hasImportantDeadline
        0,                     # earlyMeetingCount
        max(1, deep_work_minutes // 90),  # sessionCount
        deep_work_minutes,     # deepWorkMinutes
        task_completed,        # taskCompleted
        # Features calculadas:
        deep_work_minutes / (deep_work_minutes + 60),  # deepWorkEfficiency
        total_meetings / 10,   # meetingDensity
        0,                     # earlyMeetingRatio
        deep_work_minutes / (total_meetings * 60 + 1)  # intensityRatio
    ]
    
    prediction = model.predict([features])[0]
    return prediction  # 0, 7, 8, 9, 10, 11

# Ejemplo
hour = predict_start_hour(
    day_of_week=2,      # Lunes
    is_weekend=0,
    deep_work_minutes=180,
    total_meetings=3,
    task_completed=4
)
print(f"Hora predicha: {hour}:00")
'''

with open('usage_example.py', 'w') as f:
    f.write(code_example)
print("   ✅ usage_example.py generado")
print(code_example)
