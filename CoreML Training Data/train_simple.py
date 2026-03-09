#!/usr/bin/env python3
"""
Script simple para entrenar y guardar el modelo
El usuario puede usar el modelo directamente con Python
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
import json

print("="*70)
print("🚀 ENTRENANDO MODELO - INSIGHTS DASHBOARD")
print("="*70)

# Cargar datos
train = pd.read_csv('training_data.csv')
val = pd.read_csv('validation_data.csv')

# Features (solo las del calendario, conocidas al inicio del día)
features = [
    'dayOfWeek',
    'isWeekend', 
    'isHoliday',
    'totalMeetingCount',
    'earlyMeetingCount',
    'lateMeetingCount',
    'hasImportantDeadline',
    'hasUrgentDeadline',
    'backToBackMeetings',
    'externalEventCount',
    'videoCallCount',
    'freeTimeBlocks',
    'potentialDeepWorkBlocks',
    'meetingDensityScore',
    'interruptionRiskScore'
]

X_train = train[features]
y_train = train['dayCategory'].astype(int)
X_val = val[features]
y_val = val['dayCategory'].astype(int)

print(f"\n📊 Datos:")
print(f"   Features: {len(features)}")
print(f"   Entrenamiento: {len(X_train)} muestras")
print(f"   Validación: {len(X_val)} muestras")

# Entrenar modelo
print(f"\n🎯 Entrenando modelo...")
model = RandomForestClassifier(
    n_estimators=100,
    max_depth=12,
    min_samples_leaf=2,
    random_state=42
)
model.fit(X_train, y_train)

# Evaluar
train_acc = accuracy_score(y_train, model.predict(X_train))
val_acc = accuracy_score(y_val, model.predict(X_val))

print(f"\n✅ RESULTADOS:")
print(f"   Training Accuracy:   {train_acc:.1%}")
print(f"   Validation Accuracy: {val_acc:.1%}")

# Guardar modelo
import pickle
with open('InsightsClassifier.pkl', 'wb') as f:
    pickle.dump({
        'model': model,
        'features': features,
        'accuracy': val_acc
    }, f)

print(f"\n💾 Modelo guardado: InsightsClassifier.pkl")

# Crear mapeo para usar en app
mapping = {
    'features': features,
    'categories': {
        0: {'name': 'Rest', 'emoji': '🌴', 'color': 'gray'},
        1: {'name': 'Calm', 'emoji': '🧘', 'color': 'green'},
        2: {'name': 'Balanced', 'emoji': '⚡', 'color': 'blue'},
        3: {'name': 'Busy', 'emoji': '📅', 'color': 'orange'},
        4: {'name': 'Intense', 'emoji': '🔥', 'color': 'red'},
        5: {'name': 'DeepFocus', 'emoji': '🎯', 'color': 'purple'},
        6: {'name': 'BurnoutRisk', 'emoji': '🚨', 'color': 'pink'}
    },
    'accuracy': val_acc
}

with open('model_config.json', 'w') as f:
    json.dump(mapping, f, indent=2)

print(f"📋 Configuración guardada: model_config.json")

# Exportar árbol de decisión simple para visualización
print(f"\n📊 Árbol de decisión simplificado:")
print(f"   Importancia de features:")
for feat, imp in sorted(zip(features, model.feature_importances_), key=lambda x: x[1], reverse=True)[:5]:
    print(f"   - {feat}: {imp:.1%}")

print(f"\n" + "="*70)
print("✅ MODELO LISTO PARA USAR")
print("="*70)
print(f"""
Para usar el modelo en Python:

import pickle
import numpy as np

# Cargar
with open('InsightsClassifier.pkl', 'rb') as f:
    data = pickle.load(f)
model = data['model']
features = data['features']

# Predecir
def predict_day_type(day_info):
    '''
    day_info = [dayOfWeek, isWeekend, isHoliday, totalMeetingCount, ...]
    '''
    prediction = model.predict([day_info])[0]
    categories = ['🌴 Rest', '🧘 Calm', '⚡ Balanced', '📅 Busy', 
                  '🔥 Intense', '🎯 DeepFocus', '🚨 BurnoutRisk']
    return categories[prediction]

# Ejemplo
result = predict_day_type([2, 0, 0, 5, 1, 0, 0, 0, 0, 0, 3, 2, 1, 50, 30])
print(f"Hoy es un día: {{result}}")
""")
