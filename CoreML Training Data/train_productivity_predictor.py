#!/usr/bin/env python3
"""
NUEVO ENFOQUE: Predicción de Productividad/Horas Trabajadas
Para tab de Insights - Sin horarios de entrada/salida

Predice:
- workDuration: Cuántas horas trabajarás hoy
- productivityScore: Qué tan productivo serás (0-100)
- deepWorkMinutes: Minutos de trabajo profundo
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, mean_absolute_error, r2_score
import warnings
warnings.filterwarnings('ignore')

print("="*80)
print("🚀 NUEVO MODELO: PREDICCIÓN DE PRODUCTIVIDAD DIARIA")
print("="*80)

# ============================================================================
# 1. CARGAR DATOS
# ============================================================================

print("\n📊 Cargando datos...")
df = pd.read_csv('work_schedule_FINAL_for_createml.csv')

# Filtrar solo días con trabajo (workDuration > 0)
df_work = df[df['workDuration'] > 0].copy()

print(f"   Total registros: {len(df)}")
print(f"   Días con trabajo: {len(df_work)}")

# ============================================================================
# 2. CREAR CATEGORÍAS DE PRODUCTIVIDAD
# ============================================================================

def categorize_productivity(row):
    """
    Categoriza el día según productividad:
    - SuperProductive: >8h + mucho deep work
    - Productive: 6-8h + buen deep work  
    - Normal: 6-8h + regular deep work
    - Light: <6h o poco deep work
    - BurnoutRisk: >9h + muchas reuniones (alerta)
    """
    duration = row['workDuration']
    deep_work = row['deepWorkMinutes']
    meetings = row['totalMeetingCount']
    
    if duration >= 8 and deep_work >= 180 and meetings <= 3:
        return 4  # SuperProductive
    elif duration >= 7 and deep_work >= 120:
        return 3  # Productive
    elif duration >= 6 and deep_work >= 90:
        return 2  # Normal
    elif meetings >= 6 and duration >= 8:
        return 0  # BurnoutRisk (alerta)
    else:
        return 1  # Light

def categorize_duration(duration):
    """Categorías de horas trabajadas"""
    if duration <= 5:
        return 0  # Light (≤5h)
    elif duration <= 7:
        return 1  # Normal (6-7h)
    elif duration <= 9:
        return 2  # Productive (8-9h)
    else:
        return 3  # Intense (≥10h)

df_work['productivityCategory'] = df_work.apply(categorize_productivity, axis=1)
df_work['durationCategory'] = df_work['workDuration'].apply(categorize_duration)

print("\n📊 Categorías de Productividad:")
for cat, name in [(0, 'BurnoutRisk'), (1, 'Light'), (2, 'Normal'), (3, 'Productive'), (4, 'SuperProductive')]:
    count = (df_work['productivityCategory'] == cat).sum()
    pct = count / len(df_work) * 100
    print(f"   {cat}: {name:15s} = {count:4d} ({pct:5.1f}%)")

print("\n📊 Categorías de Duración:")
for cat, name in [(0, 'Light (≤5h)'), (1, 'Normal (6-7h)'), (2, 'Productive (8-9h)'), (3, 'Intense (≥10h)')]:
    count = (df_work['durationCategory'] == cat).sum()
    pct = count / len(df_work) * 100
    print(f"   {cat}: {name:20s} = {count:4d} ({pct:5.1f}%)")

# ============================================================================
# 3. FEATURES (INPUTS)
# ============================================================================

# Features que el usuario CONOCE al inicio del día
features_input = [
    'dayOfWeek',           # Qué día es
    'isWeekend',           # Es finde?
    'isHoliday',           # Es feriado?
    'totalMeetingCount',   # Reuniones del día
    'hasImportantDeadline', # Tiene deadline?
    'earlyMeetingCount',   # Reuniones temprano
]

# Features que se calculan automáticamente
features_calculated = [
    'meetingDensity',      # Densidad de reuniones
    'earlyMeetingRatio',   # Ratio reuniones tempranas
]

all_features = features_input + features_calculated

print(f"\n📋 Features de entrada: {len(all_features)}")
print("   Inputs conocidos:", features_input)
print("   Calculados:", features_calculated)

# ============================================================================
# 4. MODELO 1: PREDICCIÓN DE CATEGORÍA DE PRODUCTIVIDAD
# ============================================================================

print("\n" + "="*80)
print("🎯 MODELO 1: Categoría de Productividad")
print("="*80)

X = df_work[all_features]
y = df_work['productivityCategory']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

model_productivity = RandomForestClassifier(
    n_estimators=200,
    max_depth=12,
    min_samples_leaf=2,
    class_weight='balanced',
    random_state=42
)

model_productivity.fit(X_train, y_train)

y_pred = model_productivity.predict(X_test)
acc = accuracy_score(y_test, y_pred)

print(f"   ✅ Accuracy: {acc:.1%}")

# Reporte por categoría
cat_names = ['BurnoutRisk', 'Light', 'Normal', 'Productive', 'SuperProductive']
print("\n   Reporte por categoría:")
from sklearn.metrics import classification_report
print(classification_report(y_test, y_pred, target_names=cat_names, zero_division=0))

# Importancia de features
print("   Features importantes:")
importances = pd.DataFrame({
    'feature': X.columns,
    'importance': model_productivity.feature_importances_
}).sort_values('importance', ascending=False)

for _, row in importances.head(8).iterrows():
    print(f"   {row['importance']:.3f} | {row['feature']}")

# ============================================================================
# 5. MODELO 2: PREDICCIÓN DE DURACIÓN (HORAS)
# ============================================================================

print("\n" + "="*80)
print("⏱️  MODELO 2: Horas de Trabajo (Duration)")
print("="*80)

y_dur = df_work['workDuration']
X_train_d, X_test_d, y_train_d, y_test_d = train_test_split(X, y_dur, test_size=0.2, random_state=42)

# Versión categórica
y_dur_cat = df_work['durationCategory']
X_train_dc, X_test_dc, y_train_dc, y_test_dc = train_test_split(X, y_dur_cat, test_size=0.2, random_state=42, stratify=y_dur_cat)

model_duration = RandomForestClassifier(
    n_estimators=200,
    max_depth=12,
    random_state=42
)

model_duration.fit(X_train_dc, y_train_dc)

y_pred_dur = model_duration.predict(X_test_dc)
acc_dur = accuracy_score(y_test_dc, y_pred_dur)

print(f"   ✅ Accuracy categoría: {acc_dur:.1%}")

# MAE en horas
cat_to_hours = {0: 4.5, 1: 6.5, 2: 8.5, 3: 10}
y_pred_hours = [cat_to_hours[c] for c in y_pred_dur]
y_test_hours = [cat_to_hours[c] for c in y_test_dc]

mae = mean_absolute_error(y_test_hours, y_pred_hours)
print(f"   📊 MAE: {mae:.1f} horas")

# ============================================================================
# 6. MODELO 3: PREDICCIÓN DE DEEP WORK MINUTES
# ============================================================================

print("\n" + "="*80)
print("🧠 MODELO 3: Deep Work Minutes")
print("="*80)

y_deep = df_work['deepWorkMinutes']
X_train_deep, X_test_deep, y_train_deep, y_test_deep = train_test_split(X, y_deep, test_size=0.2, random_state=42)

model_deep = RandomForestRegressor(
    n_estimators=200,
    max_depth=12,
    random_state=42
)

model_deep.fit(X_train_deep, y_train_deep)

y_pred_deep = model_deep.predict(X_test_deep)
mae_deep = mean_absolute_error(y_test_deep, y_pred_deep)
r2_deep = r2_score(y_test_deep, y_pred_deep)

print(f"   📊 MAE: {mae_deep:.0f} minutos")
print(f"   📊 R²: {r2_deep:.2f}")

# ============================================================================
# 7. PRUEBAS CON EJEMPLOS
# ============================================================================

print("\n" + "="*80)
print("🧪 EJEMPLOS DE PREDICCIÓN")
print("="*80)

test_cases = [
    ("Lunes tranquilo", 2, 0, 0, 2, 0, 0),
    ("Lunes pesado", 2, 0, 0, 6, 1, 2),
    ("Viernes ligero", 6, 0, 0, 1, 0, 0),
    ("Miércoles normal", 4, 0, 0, 3, 0, 0),
    ("Sábado", 7, 1, 0, 0, 0, 0),
    ("Pre-deadline", 5, 0, 0, 4, 1, 1),
]

cat_prod_names = ['🔥 Burnout', '🌱 Light', '⚡ Normal', '🚀 Productive', '⭐ Super']
cat_dur_names = ['≤5h', '6-7h', '8-9h', '≥10h']

print(f"\n{'Día':<20} {'Productividad':<15} {'Horas':<10} {'Deep Work'}")
print("-" * 70)

for name, *vals in test_cases:
    # Preparar features
    features = list(vals)
    
    # Calcular features derivadas
    total_meetings = vals[3]
    early_meetings = vals[5]
    meeting_density = total_meetings / 10
    early_ratio = early_meetings / (total_meetings + 1)
    
    features.extend([meeting_density, early_ratio])
    
    # Predecir
    prod_cat = model_productivity.predict([features])[0]
    dur_cat = model_duration.predict([features])[0]
    deep_min = model_deep.predict([features])[0]
    
    prod_str = cat_prod_names[prod_cat]
    dur_str = cat_dur_names[dur_cat]
    deep_str = f"{int(deep_min)}min"
    
    print(f"{name:<20} {prod_str:<15} {dur_str:<10} {deep_str}")

# ============================================================================
# 8. GUARDAR MODELOS Y EXPORTAR
# ============================================================================

print("\n" + "="*80)
print("💾 GUARDANDO MODELOS")
print("="*80)

import pickle

# Guardar modelos
models = {
    'productivity_classifier': model_productivity,
    'duration_classifier': model_duration,
    'deepwork_regressor': model_deep,
    'features': all_features,
    'category_names': {
        'productivity': cat_prod_names,
        'duration': cat_dur_names
    }
}

with open('ProductivityPredictor.pkl', 'wb') as f:
    pickle.dump(models, f)

print("   ✅ ProductivityPredictor.pkl")

# Exportar CSV para Create ML
df_export = df_work[all_features + ['productivityCategory', 'durationCategory', 'deepWorkMinutes']].copy()

# Convertir a enteros
df_export['meetingDensity'] = (df_export['meetingDensity'] * 100).round().astype(int)
df_export['earlyMeetingRatio'] = (df_export['earlyMeetingRatio'] * 100).round().astype(int)

df_export.to_csv('PRODUCTIVITY_ML_INPUT.csv', index=False)
print("   ✅ PRODUCTIVITY_ML_INPUT.csv")

# ============================================================================
# 9. RESUMEN
# ============================================================================

print("\n" + "="*80)
print("📊 RESUMEN DE MODELOS")
print("="*80)

print(f"""
MODELOS ENTRENADOS:

1️⃣  Productividad (Categoría)
    Target: productivityCategory (0-4)
    Accuracy: {acc:.1%}
    Clases: Burnout, Light, Normal, Productive, Super
    
2️⃣  Duración (Categoría)
    Target: durationCategory (0-3)
    Accuracy: {acc_dur:.1%}
    Clases: ≤5h, 6-7h, 8-9h, ≥10h
    MAE: {mae:.1f} horas
    
3️⃣  Deep Work (Regresión)
    Target: deepWorkMinutes
    MAE: {mae_deep:.0f} minutos
    R²: {r2_deep:.2f}

FEATURES DE ENTRADA (conocidas al inicio del día):
{all_features}

PARA EL TAB DE INSIGHTS:
Al inicio del día, la app predice:
   "Hoy probablemente tengas un día {productividad}"
   "Espera trabajar alrededor de {X} horas"
   "Podrías tener {Y} minutos de deep work"
""")

# Código de uso
print("="*80)
print("📝 CÓDIGO DE USO")
print("="*80)

usage_code = '''
import pickle

# Cargar modelos
with open('ProductivityPredictor.pkl', 'rb') as f:
    models = pickle.load(f)

prod_model = models['productivity_classifier']
dur_model = models['duration_classifier']
deep_model = models['deepwork_regressor']
features = models['features']

def predict_today(day_of_week, is_weekend, is_holiday, 
                  total_meetings, has_deadline, early_meetings):
    """
    Predice la productividad del día
    """
    # Calcular features
    meeting_density = total_meetings / 10
    early_ratio = early_meetings / (total_meetings + 1)
    
    input_features = [
        day_of_week, is_weekend, is_holiday,
        total_meetings, has_deadline, early_meetings,
        meeting_density, early_ratio
    ]
    
    # Predecir
    productivity = prod_model.predict([input_features])[0]
    duration = dur_model.predict([input_features])[0]
    deep_work = deep_model.predict([input_features])[0]
    
    # Mapear a nombres
    prod_names = ['Burnout Risk', 'Light Day', 'Normal Day', 'Productive Day', 'Super Productive']
    dur_names = ['≤5h', '6-7h', '8-9h', '≥10h']
    
    return {
        'productivity_category': prod_names[productivity],
        'productivity_emoji': ['🔥', '🌱', '⚡', '🚀', '⭐'][productivity],
        'duration_category': dur_names[duration],
        'predicted_hours': [4.5, 6.5, 8.5, 10][duration],
        'deep_work_minutes': int(deep_work)
    }

# Ejemplo
result = predict_today(
    day_of_week=2,      # Lunes
    is_weekend=0,
    is_holiday=0,
    total_meetings=3,
    has_deadline=0,
    early_meetings=0
)

print(f"Hoy: {result['productivity_emoji']} {result['productivity_category']}")
print(f"Horas: {result['duration_category']}")
print(f"Deep Work: {result['deep_work_minutes']} min")
'''

with open('usage_productivity.py', 'w') as f:
    f.write(usage_code)

print(usage_code)
print("\n   ✅ usage_productivity.py guardado")
