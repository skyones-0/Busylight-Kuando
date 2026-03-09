#!/usr/bin/env python3
"""
🧠 Entrenamiento DayCategoryClassifier
Script para entrenar el modelo CoreML que clasifica días laborales.

Uso:
    python train_model.py

Requisitos:
    pip install pandas numpy scikit-learn coremltools

Salida:
    - DayCategoryClassifier.pkl (modelo sklearn)
    - DayCategoryClassifier.mlmodel (modelo CoreML)
    - model_metrics.json (métricas)
"""

import pandas as pd
import numpy as np
import json
import os
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, accuracy_score, precision_recall_fscore_support
import joblib

print("=" * 60)
print("🚀 ENTRENAMIENTO DayCategoryClassifier")
print("=" * 60)

# 1. CARGAR DATOS
print("\n📊 Cargando datasets...")
train_df = pd.read_csv('TRAINING.csv')
val_df = pd.read_csv('VALIDATION.csv')
test_df = pd.read_csv('TESTING.csv')

print(f"   Training: {train_df.shape[0]} muestras")
print(f"   Validation: {val_df.shape[0]} muestras")
print(f"   Testing: {test_df.shape[0]} muestras")

# 2. PREPARAR DATOS
feature_columns = [
    'dayOfWeek',
    'isWeekend',
    'isHoliday',
    'totalMeetingCount',
    'hasImportantDeadline',
    'backToBackMeetings',
    'freeTimeBlocks',
    'meetingDensityScore',
    'interruptionRiskScore'
]

target_column = 'dayCategory'

X_train = train_df[feature_columns]
y_train = train_df[target_column]
X_val = val_df[feature_columns]
y_val = val_df[target_column]
X_test = test_df[feature_columns]
y_test = test_df[target_column]

# 3. ENTRENAR MODELO
print("\n🎯 Entrenando Random Forest...")
rf_model = RandomForestClassifier(
    n_estimators=100,
    max_depth=15,
    min_samples_split=5,
    min_samples_leaf=2,
    random_state=42,
    n_jobs=-1
)

rf_model.fit(X_train, y_train)

# 4. EVALUAR
print("\n📈 Evaluando modelo...")
y_pred = rf_model.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)

print(f"\n✅ Accuracy: {accuracy:.4f} ({accuracy*100:.2f}%)")

# Classification report
categories = ['Rest', 'Calm', 'Balanced', 'Busy', 'Intense', 'DeepFocus', 'BurnoutRisk']
print("\n📊 Classification Report:")
print(classification_report(y_test, y_pred, target_names=categories))

# 5. FEATURE IMPORTANCE
print("\n🔍 Feature Importance:")
importance = sorted(zip(feature_columns, rf_model.feature_importances_), 
                   key=lambda x: x[1], reverse=True)
for feature, imp in importance:
    print(f"   {feature}: {imp:.4f}")

# 6. GUARDAR MODELO SKLEARN
print("\n💾 Guardando modelos...")
joblib.dump(rf_model, 'DayCategoryClassifier.pkl')
print("   ✅ DayCategoryClassifier.pkl")

# 7. CONVERTIR A COREML
print("\n🍎 Convirtiendo a CoreML...")
try:
    import coremltools as ct
    
    coreml_model = ct.converters.sklearn.convert(
        rf_model,
        input_features=feature_columns,
        output_feature_names='dayCategory'
    )
    
    coreml_model.author = 'Busylight Team'
    coreml_model.license = 'MIT'
    coreml_model.short_description = 'Clasifica días laborales en 7 categorías'
    
    coreml_model.save('DayCategoryClassifier.mlmodel')
    print("   ✅ DayCategoryClassifier.mlmodel")
    print(f"   📦 Tamaño: {os.path.getsize('DayCategoryClassifier.mlmodel') / 1024:.2f} KB")
    
except ImportError:
    print("   ⚠️ coremltools no instalado. Instala con: pip install coremltools")
    print("   ⚠️ Solo se guardó el modelo .pkl")

# 8. GUARDAR MÉTRICAS
precision, recall, f1, support = precision_recall_fscore_support(y_test, y_pred, average=None)

metrics = {
    'model_name': 'DayCategoryClassifier',
    'algorithm': 'Random Forest',
    'accuracy': float(accuracy),
    'n_estimators': 100,
    'max_depth': 15,
    'training_samples': len(X_train),
    'test_samples': len(X_test),
    'features': feature_columns,
    'categories': categories,
    'metrics_by_class': {
        cat: {
            'precision': float(precision[i]),
            'recall': float(recall[i]),
            'f1': float(f1[i]),
            'support': int(support[i])
        }
        for i, cat in enumerate(categories)
    },
    'feature_importance': {f: float(i) for f, i in importance}
}

with open('model_metrics.json', 'w') as f:
    json.dump(metrics, f, indent=2)

print("   ✅ model_metrics.json")

# 9. TEST RÁPIDO
print("\n🧪 Test rápido:")
sample = {
    'dayOfWeek': 2,
    'isWeekend': 0,
    'isHoliday': 0,
    'totalMeetingCount': 5,
    'hasImportantDeadline': 1,
    'backToBackMeetings': 1,
    'freeTimeBlocks': 2,
    'meetingDensityScore': 60,
    'interruptionRiskScore': 70
}

pred = rf_model.predict([list(sample.values())])[0]
categories_map = {
    0: '🌴 Rest', 1: '🧘 Calm', 2: '⚡ Balanced', 3: '📅 Busy',
    4: '🔥 Intense', 5: '🎯 DeepFocus', 6: '🚨 BurnoutRisk'
}
print(f"   Input: 5 reuniones, 60% densidad")
print(f"   Predicción: {pred} - {categories_map[pred]}")

print("\n" + "=" * 60)
print("✅ ENTRENAMIENTO COMPLETADO")
print("=" * 60)
print("\nArchivos generados:")
print("   • DayCategoryClassifier.pkl")
print("   • DayCategoryClassifier.mlmodel  ← Arrastra a Xcode")
print("   • model_metrics.json")
print("\nPara usar en la app:")
print("   1. Copia DayCategoryClassifier.mlmodel al proyecto")
print("   2. Selecciona el archivo → Target Membership → Check tu app")
print("   3. Usa: DayCategoryClassifierWrapper.shared.predictToday(...)")
