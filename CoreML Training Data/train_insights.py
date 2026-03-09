#!/usr/bin/env python3
"""
PREDICCIÓN DE PRODUCTIVIDAD SIMPLIFICADA
Para tab de Insights
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, mean_absolute_error
import warnings
warnings.filterwarnings('ignore')

print("="*80)
print("🚀 PREDICCIÓN DE PRODUCTIVIDAD (V2 - Simplificado)")
print("="*80)

# 1. Cargar datos
df = pd.read_csv('work_schedule_FINAL_for_createml.csv')
df_work = df[df['workDuration'] > 0].copy()

print(f"\n📊 Datos: {len(df_work)} días con trabajo")

# 2. SIMPLIFICAR: Solo 3 categorías de productividad
def simple_productivity_category(row):
    """
    Solo 3 categorías claras:
    0 = Light (poco trabajo)
    1 = Normal (trabajo estándar)  
    2 = Heavy (mucho trabajo)
    """
    duration = row['workDuration']
    meetings = row['totalMeetingCount']
    
    if duration <= 6 or (duration <= 7 and meetings <= 2):
        return 0  # Light
    elif duration <= 8:
        return 1  # Normal
    else:
        return 2  # Heavy

df_work['productivityCategory'] = df_work.apply(simple_productivity_category, axis=1)

print("\n📊 Distribución de categorías:")
for cat, name in [(0, '🌱 Light'), (1, '⚡ Normal'), (2, '🔥 Heavy')]:
    count = (df_work['productivityCategory'] == cat).sum()
    pct = count / len(df_work) * 100
    print(f"   {name}: {count} ({pct:.1f}%)")

# 3. Features simples (solo las que el usuario conoce al inicio del día)
features = [
    'dayOfWeek',
    'isWeekend', 
    'isHoliday',
    'totalMeetingCount',
    'hasImportantDeadline',
    'earlyMeetingCount',
]

X = df_work[features]
y_cat = df_work['productivityCategory']
y_duration = df_work['workDuration']
y_deep = df_work['deepWorkMinutes']

# 4. ENTRENAR MODELOS
print("\n" + "="*80)

# Modelo 1: Categoría de productividad
print("🎯 Modelo 1: Categoría (Light/Normal/Heavy)")
X_train, X_test, y_train, y_test = train_test_split(X, y_cat, test_size=0.2, random_state=42, stratify=y_cat)

model_cat = RandomForestClassifier(n_estimators=150, max_depth=10, random_state=42)
model_cat.fit(X_train, y_train)

acc_cat = accuracy_score(y_test, model_cat.predict(X_test))
print(f"   Accuracy: {acc_cat:.1%}")

# Modelo 2: Duración exacta (regresión)
print("\n⏱️  Modelo 2: Horas exactas (regresión)")
X_train, X_test, y_train, y_test = train_test_split(X, y_duration, test_size=0.2, random_state=42)

model_dur = RandomForestRegressor(n_estimators=150, max_depth=10, random_state=42)
model_dur.fit(X_train, y_train)

pred_dur = model_dur.predict(X_test)
mae_dur = mean_absolute_error(y_test, pred_dur)
print(f"   MAE: {mae_dur:.1f} horas")

# Modelo 3: Deep work (regresión)
print("\n🧠 Modelo 3: Deep Work minutes")
X_train, X_test, y_train, y_test = train_test_split(X, y_deep, test_size=0.2, random_state=42)

model_deep = RandomForestRegressor(n_estimators=150, max_depth=10, random_state=42)
model_deep.fit(X_train, y_train)

pred_deep = model_deep.predict(X_test)
mae_deep = mean_absolute_error(y_test, pred_deep)
print(f"   MAE: {mae_deep:.0f} minutos")

# 5. EJEMPLOS
print("\n" + "="*80)
print("🧪 EJEMPLOS DE PREDICCIÓN")
print("="*80)

test_cases = [
    ("Lunes tranquilo", 2, 0, 0, 2, 0, 0),
    ("Lunes con reuniones", 2, 0, 0, 5, 1, 2),
    ("Miércoles normal", 4, 0, 0, 3, 0, 0),
    ("Viernes light", 6, 0, 0, 1, 0, 0),
    ("Pre-deadline", 5, 0, 0, 4, 1, 1),
    ("Sábado", 7, 1, 0, 0, 0, 0),
]

cat_names = ['🌱 Light', '⚡ Normal', '🔥 Heavy']

print(f"\n{'Día':<20} {'Categoría':<12} {'Horas':<8} {'Deep Work'}")
print("-" * 55)

for name, *vals in test_cases:
    # Predicciones
    cat = model_cat.predict([vals])[0]
    dur = model_dur.predict([vals])[0]
    deep = model_deep.predict([vals])[0]
    
    print(f"{name:<20} {cat_names[cat]:<12} {dur:.1f}h     {deep:.0f}min")

# 6. GUARDAR
print("\n" + "="*80)
print("💾 GUARDANDO")
print("="*80)

import pickle

models = {
    'category_model': model_cat,
    'duration_model': model_dur,
    'deepwork_model': model_deep,
    'features': features,
    'category_names': cat_names
}

with open('ProductivityInsights.pkl', 'wb') as f:
    pickle.dump(models, f)
print("   ✅ ProductivityInsights.pkl")

# CSV para Create ML
df_export = df_work[features + ['productivityCategory', 'workDuration', 'deepWorkMinutes']]
df_export.to_csv('INSIGHTS_INPUT.csv', index=False)
print("   ✅ INSIGHTS_INPUT.csv")

print("\n" + "="*80)
print("✅ COMPLETADO")
print("="*80)

print(f"""
RESUMEN:
   Categoría: {acc_cat:.1%} accuracy
   Duración: ±{mae_dur:.1f} horas de error
   Deep Work: ±{mae_deep:.0f} minutos de error

PARA EL TAB DE INSIGHTS:
   Al inicio del día se muestra:
   
   "Hoy: {cat_names[1]}"
   "Esperado: ~{df_work['workDuration'].mean():.1f} horas"
   "Deep Work: ~{df_work['deepWorkMinutes'].mean():.0f} minutos"
""")
