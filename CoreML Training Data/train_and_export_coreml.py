#!/usr/bin/env python3
"""
Entrena modelo y exporta a CoreML directamente
No necesitas Create ML, solo ejecuta este script
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import warnings
warnings.filterwarnings('ignore')

print("="*70)
print("🚀 ENTRENANDO MODELO PARA COREML")
print("="*70)

# 1. Cargar datos
print("\n📊 Cargando datos...")
train_df = pd.read_csv('training_data.csv')
val_df = pd.read_csv('validation_data.csv')

train_df['dayCategory'] = train_df['dayCategory'].astype(int)
val_df['dayCategory'] = val_df['dayCategory'].astype(int)

# 2. Features
feature_cols = [c for c in train_df.columns if c != 'dayCategory' and 
                c not in ['productivityScore', 'focusScore', 'stressLevel', 'recommendedStrategy']]

X_train = train_df[feature_cols]
y_train = train_df['dayCategory']
X_val = val_df[feature_cols]
y_val = val_df['dayCategory']

print(f"   Features: {len(feature_cols)}")
print(f"   Clases: {sorted(y_train.unique())}")
print(f"   Train: {len(X_train)}, Val: {len(X_val)}")

# 3. Entrenar
print("\n🎯 Entrenando Random Forest...")
model = RandomForestClassifier(
    n_estimators=100,
    max_depth=12,
    min_samples_leaf=2,
    random_state=42
)
model.fit(X_train, y_train)

# 4. Evaluar
val_pred = model.predict(X_val)
val_acc = accuracy_score(y_val, val_pred)

print(f"   ✅ Validation Accuracy: {val_acc:.1%}")
print(f"\n   Reporte por clase:")
cat_names = ['Rest', 'Calm', 'Balanced', 'Busy', 'Intense', 'DeepFocus', 'BurnoutRisk']
print(classification_report(y_val, val_pred, target_names=cat_names, zero_division=0))

# 5. Exportar a CoreML usando coremltools
print("\n📦 Exportando a CoreML...")

try:
    import coremltools as ct
    from coremltools.models import datatypes
    
    print(f"   coremltools versión: {ct.__version__}")
    
    # Convertir sklearn a CoreML
    coreml_model = ct.converters.sklearn.convert(
        model,
        feature_cols,
        "dayCategory"
    )
    
    # Metadata
    coreml_model.author = "Busylight Insights"
    coreml_model.license = "MIT"
    coreml_model.short_description = f"Clasifica el tipo de día laboral. Accuracy: {val_acc:.1%}"
    
    # Configurar output para que sea categórico
    spec = coreml_model.get_spec()
    
    # Guardar
    output_path = "DayCategoryClassifier.mlmodel"
    coreml_model.save(output_path)
    
    # Verificar tamaño
    import os
    size_kb = os.path.getsize(output_path) / 1024
    
    print(f"   ✅ Modelo guardado: {output_path}")
    print(f"   📏 Tamaño: {size_kb:.1f} KB")
    print(f"   📊 Input features: {len(feature_cols)}")
    print(f"   🎯 Output: dayCategory (0-6)")
    
except ImportError:
    print("   ❌ coremltools no instalado")
    print("   Instalando...")
    import subprocess
    subprocess.run(["pip3", "install", "-q", "coremltools"])
    print("   Por favor vuelve a ejecutar el script")
    
except Exception as e:
    print(f"   ❌ Error: {e}")
    print("   Guardando modelo en formato alternativo...")
    
    # Guardar como pickle
    import pickle
    with open('DayCategoryClassifier.pkl', 'wb') as f:
        pickle.dump({'model': model, 'features': feature_cols}, f)
    print("   💾 Modelo pickle guardado: DayCategoryClassifier.pkl")
    
    # Crear archivo de especificaciones
    with open('model_features.txt', 'w') as f:
        f.write("Features de entrada (en orden):\n")
        for i, feat in enumerate(feature_cols, 1):
            f.write(f"{i}. {feat}\n")
        f.write(f"\nTarget: dayCategory (0-6)\n")
        f.write(f"0=Rest, 1=Calm, 2=Balanced, 3=Busy, 4=Intense, 5=DeepFocus, 6=BurnoutRisk\n")
    print("   📋 Especificaciones guardadas: model_features.txt")

# 6. Ejemplo de uso
print("\n" + "="*70)
print("🧪 EJEMPLO DE USO")
print("="*70)

test_cases = [
    ("Lunes tranquilo", [2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 4, 2, 20, 10]),
    ("Lunes intenso", [2, 0, 0, 6, 2, 1, 1, 0, 1, 0, 4, 1, 0, 60, 50]),
    ("Viernes light", [6, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 5, 3, 10, 5]),
]

cat_names = ['🌴 Rest', '🧘 Calm', '⚡ Balanced', '📅 Busy', '🔥 Intense', '🎯 DeepFocus', '🚨 BurnoutRisk']

for name, features in test_cases:
    pred = model.predict([features])[0]
    print(f"   {name:20s} → {cat_names[pred]}")

print("\n" + "="*70)
print("✅ COMPLETADO")
print("="*70)
