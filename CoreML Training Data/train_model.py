#!/usr/bin/env python3
"""
Script V11 - Predicción de START HOUR y WORK DURATION (o END HOUR)

El usuario tiene razón: no es solo startHour, también necesitamos
predecir cuántas horas trabajará (workDuration) para calcular endHour.

Estrategias:
1. Dos modelos separados: uno para start, otro para duration
2. Un modelo multi-output que prediga ambos
3. Predecir startHour y calcular endHour = start + duración típica del usuario
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.multioutput import MultiOutputRegressor
from sklearn.metrics import accuracy_score, mean_absolute_error
import warnings
warnings.filterwarnings('ignore')

def load_and_prepare():
    """Carga y prepara datos"""
    train_df = pd.read_csv('work_schedule_v9_training.csv')
    val_df = pd.read_csv('work_schedule_v9_validation.csv')
    test_df = pd.read_csv('work_schedule_v9_testing.csv')
    return train_df, val_df, test_df

def engineer_features(df):
    """Feature engineering"""
    df = df.copy()
    
    # Codificación cíclica
    day_adj = df['dayOfWeek'] - 1
    df['day_sin'] = np.sin(2 * np.pi * day_adj / 7)
    df['day_cos'] = np.cos(2 * np.pi * day_adj / 7)
    
    # Días especiales
    df['is_monday'] = (df['dayOfWeek'] == 2).astype(int)
    df['is_friday'] = (df['dayOfWeek'] == 6).astype(int)
    
    # Features calculables
    df['deepWorkEfficiency'] = df['deepWorkMinutes'] / (df['deepWorkMinutes'] + df['shallowWorkMinutes'] + 1)
    df['meetingDensity'] = df['totalMeetingCount'] / 10
    df['earlyMeetingRatio'] = df['earlyMeetingCount'] / (df['totalMeetingCount'] + 1)
    df['intensityRatio'] = df['deepWorkMinutes'] / (df['totalMeetingCount'] * 60 + 1)
    
    return df

def analyze_duration_distribution(df):
    """Analiza la distribución de workDuration"""
    print("\n📊 DISTRIBUCIÓN DE WORK DURATION:")
    print("-" * 50)
    
    # Solo días con trabajo
    work_days = df[df['workDuration'] > 0]['workDuration']
    
    print(f"   Media: {work_days.mean():.1f}h")
    print(f"   Mediana: {work_days.median():.1f}h")
    print(f"   Moda: {work_days.mode().iloc[0]:.0f}h")
    print(f"   Min: {work_days.min():.0f}h, Max: {work_days.max():.0f}h")
    print(f"   Std: {work_days.std():.1f}h")
    
    print(f"\n   Distribución:")
    for duration in sorted(work_days.unique()):
        count = (work_days == duration).sum()
        pct = count / len(work_days) * 100
        bar = "█" * int(pct / 2)
        print(f"   {duration:2d}h: {count:4d} ({pct:5.1f}%) {bar}")
    
    # Relación entre startHour y workDuration
    print(f"\n   Relación Start Hour vs Duration:")
    pivot = df[df['workDuration'] > 0].groupby('startHour')['workDuration'].agg(['mean', 'std', 'count'])
    for hour, row in pivot.iterrows():
        print(f"   {hour:2d}:00 → Duración: {row['mean']:.1f}h ±{row['std']:.1f}h (n={row['count']})")

def categorize_duration(duration):
    """Categoriza duración en buckets"""
    if duration == 0:
        return 0  # No work
    elif duration <= 4:
        return 1  # Short (1-4h)
    elif duration <= 6:
        return 2  # Medium (5-6h)
    elif duration <= 8:
        return 3  # Normal (7-8h)
    elif duration <= 10:
        return 4  # Long (9-10h)
    else:
        return 5  # Very Long (11h+)

def train_separate_models(X_train, y_train_start, y_train_duration, 
                          X_test, y_test_start, y_test_duration):
    """
    Estrategia 1: Dos modelos separados
    - Modelo A: Predice startHour
    - Modelo B: Predice workDuration
    - endHour = startHour + workDuration
    """
    print("\n" + "="*70)
    print("📊 ESTRATEGIA 1: Dos Modelos Separados")
    print("   Modelo A: Start Hour | Modelo B: Work Duration")
    print("="*70)
    
    # Modelo A: Start Hour (clasificación)
    model_start = RandomForestClassifier(n_estimators=200, max_depth=15, random_state=42)
    model_start.fit(X_train, y_train_start)
    
    pred_start = model_start.predict(X_test)
    acc_start = accuracy_score(y_test_start, pred_start)
    acc_start_pm1 = (np.abs(pred_start - y_test_start) <= 1).mean()
    
    print(f"   ⏰ START HOUR:")
    print(f"      Exacto: {acc_start:.1%} | ±1h: {acc_start_pm1:.1%}")
    
    # Modelo B: Work Duration (clasificación en buckets)
    y_train_dur_cat = np.array([categorize_duration(d) for d in y_train_duration])
    y_test_dur_cat = np.array([categorize_duration(d) for d in y_test_duration])
    
    model_duration = RandomForestClassifier(n_estimators=200, max_depth=15, random_state=42)
    model_duration.fit(X_train, y_train_dur_cat)
    
    pred_dur_cat = model_duration.predict(X_test)
    acc_dur = accuracy_score(y_test_dur_cat, pred_dur_cat)
    
    # Convertir categoría a horas (punto medio)
    cat_to_hours = {0: 0, 1: 3, 2: 5, 3: 7, 4: 9, 5: 11}
    pred_dur = np.array([cat_to_hours[c] for c in pred_dur_cat])
    
    print(f"   ⏱️  WORK DURATION:")
    print(f"      Categoría: {acc_dur:.1%}")
    print(f"      MAE: {mean_absolute_error(y_test_duration, pred_dur):.1f}h")
    
    # Calcular endHour
    pred_end = pred_start + pred_dur
    pred_end[pred_start == 0] = 0  # No work
    y_test_end = y_test_start + y_test_duration
    y_test_end[y_test_start == 0] = 0
    
    acc_end = accuracy_score(y_test_end, pred_end)
    acc_end_pm1 = (np.abs(pred_end - y_test_end) <= 1).mean()
    acc_both = ((pred_start == y_test_start) & (pred_end == y_test_end)).mean()
    
    print(f"   🏁 END HOUR (calculado):")
    print(f"      Exacto: {acc_end:.1%} | ±1h: {acc_end_pm1:.1%}")
    print(f"   ✅ AMBAS (start+end): {acc_both:.1%}")
    
    return model_start, model_duration, acc_both

def train_multioutput_model(X_train, y_train_start, y_train_duration, 
                            X_test, y_test_start, y_test_duration):
    """
    Estrategia 2: Un modelo multi-output
    Predice startHour y workDuration simultáneamente
    """
    print("\n" + "="*70)
    print("📊 ESTRATEGIA 2: Multi-Output (Start + Duration)")
    print("="*70)
    
    # Combinar targets
    y_train_combined = np.column_stack([y_train_start, y_train_duration])
    y_test_combined = np.column_stack([y_test_start, y_test_duration])
    
    # Modelo multi-output
    base_model = RandomForestRegressor(n_estimators=200, max_depth=15, random_state=42)
    model = MultiOutputRegressor(base_model)
    model.fit(X_train, y_train_combined)
    
    # Predecir
    pred = model.predict(X_test)
    pred_start = np.round(pred[:, 0]).astype(int)
    pred_dur = np.round(pred[:, 1]).astype(int)
    
    # Clampear
    pred_start = np.clip(pred_start, 0, 20)
    pred_dur = np.clip(pred_dur, 0, 12)
    pred_dur[pred_start == 0] = 0
    
    # Métricas
    acc_start = accuracy_score(y_test_start, pred_start)
    acc_start_pm1 = (np.abs(pred_start - y_test_start) <= 1).mean()
    
    mae_dur = mean_absolute_error(y_test_duration, pred_dur)
    
    pred_end = pred_start + pred_dur
    y_test_end = y_test_start + y_test_duration
    y_test_end[y_test_start == 0] = 0
    
    acc_end = accuracy_score(y_test_end, pred_end)
    acc_both = ((pred_start == y_test_start) & (pred_end == y_test_end)).mean()
    
    print(f"   ⏰ START HOUR:")
    print(f"      Exacto: {acc_start:.1%} | ±1h: {acc_start_pm1:.1%}")
    print(f"   ⏱️  DURATION MAE: {mae_dur:.1f}h")
    print(f"   🏁 END HOUR: {acc_end:.1%}")
    print(f"   ✅ AMBAS: {acc_both:.1%}")
    
    return model, acc_both

def train_start_only_with_typical_duration(X_train, y_train_start, y_train_duration,
                                           X_test, y_test_start, y_test_duration,
                                           typical_duration=8):
    """
    Estrategia 3: Solo predice startHour, usa duración típica del usuario
    """
    print("\n" + "="*70)
    print(f"📊 ESTRATEGIA 3: Solo Start Hour + Duración Típica ({typical_duration}h)")
    print("="*70)
    
    model = RandomForestClassifier(n_estimators=200, max_depth=15, random_state=42)
    model.fit(X_train, y_train_start)
    
    pred_start = model.predict(X_test)
    acc_start = accuracy_score(y_test_start, pred_start)
    acc_start_pm1 = (np.abs(pred_start - y_test_start) <= 1).mean()
    
    print(f"   ⏰ START HOUR:")
    print(f"      Exacto: {acc_start:.1%} | ±1h: {acc_start_pm1:.1%}")
    
    # Usar duración típica
    pred_end = pred_start + typical_duration
    pred_end[pred_start == 0] = 0
    
    y_test_end = y_test_start + y_test_duration
    y_test_end[y_test_start == 0] = 0
    
    acc_end = accuracy_score(y_test_end, pred_end)
    acc_end_pm1 = (np.abs(pred_end - y_test_end) <= 1).mean()
    acc_both = ((pred_start == y_test_start) & (pred_end == y_test_end)).mean()
    
    print(f"   🏁 END HOUR (con duración típica {typical_duration}h):")
    print(f"      Exacto: {acc_end:.1%} | ±1h: {acc_end_pm1:.1%}")
    print(f"   ✅ AMBAS: {acc_both:.1%}")
    
    # Calcular duración real promedio del usuario en test
    real_avg_duration = y_test_duration[y_test_duration > 0].mean()
    print(f"   📊 Duración real promedio en test: {real_avg_duration:.1f}h")
    
    return model, acc_both

def main():
    print("="*80)
    print("🚀 V11 - PREDICCIÓN DE START HOUR + WORK DURATION")
    print("="*80)
    
    # Cargar datos
    train_df, val_df, test_df = load_and_prepare()
    
    print(f"\n📊 Datos: {len(train_df)} train, {len(val_df)} val, {len(test_df)} test")
    
    # Analizar distribución de duración
    analyze_duration_distribution(train_df)
    
    # Feature engineering
    train_df = engineer_features(train_df)
    test_df = engineer_features(test_df)
    
    # Features
    feature_cols = [
        'day_sin', 'day_cos', 'isWeekend', 'isHoliday',
        'is_monday', 'is_friday',
        'totalMeetingCount', 'hasImportantDeadline', 'earlyMeetingCount',
        'sessionCount', 'deepWorkMinutes', 'taskCompleted',
        'deepWorkEfficiency', 'meetingDensity', 'earlyMeetingRatio', 'intensityRatio'
    ]
    
    X_train = train_df[feature_cols]
    X_test = test_df[feature_cols]
    
    y_train_start = train_df['startHour']
    y_test_start = test_df['startHour']
    y_train_duration = train_df['workDuration']
    y_test_duration = test_df['workDuration']
    
    # ============================================================================
    # ENTRENAR MODELOS
    # ============================================================================
    
    results = []
    
    # Estrategia 1: Dos modelos
    _, _, acc1 = train_separate_models(
        X_train, y_train_start, y_train_duration,
        X_test, y_test_start, y_test_duration
    )
    results.append(("Dos modelos (start + duration)", acc1))
    
    # Estrategia 2: Multi-output
    _, acc2 = train_multioutput_model(
        X_train, y_train_start, y_train_duration,
        X_test, y_test_start, y_test_duration
    )
    results.append(("Multi-output", acc2))
    
    # Estrategia 3: Start only + duración típica (8h)
    _, acc3 = train_start_only_with_typical_duration(
        X_train, y_train_start, y_train_duration,
        X_test, y_test_start, y_test_duration,
        typical_duration=8
    )
    results.append(("Solo start + 8h fijas", acc3))
    
    # Estrategia 4: Start only + duración promedio real
    real_avg = int(train_df[train_df['workDuration'] > 0]['workDuration'].mean())
    _, acc4 = train_start_only_with_typical_duration(
        X_train, y_train_start, y_train_duration,
        X_test, y_test_start, y_test_duration,
        typical_duration=real_avg
    )
    results.append((f"Solo start + {real_avg}h (promedio real)", acc4))
    
    # ============================================================================
    # RANKING
    # ============================================================================
    
    print("\n" + "="*80)
    print("🏆 COMPARACIÓN DE ESTRATEGIAS (START + END)")
    print("="*80)
    
    results_sorted = sorted(results, key=lambda x: x[1], reverse=True)
    
    for i, (name, acc) in enumerate(results_sorted, 1):
        print(f"{i}. {name}: {acc:.1%}")
    
    # ============================================================================
    # EJEMPLOS
    # ============================================================================
    
    print("\n" + "="*80)
    print("🧪 EJEMPLOS CON LA MEJOR ESTRATEGIA")
    print("="*80)
    
    # Usar estrategia 1 (dos modelos)
    model_start = RandomForestClassifier(n_estimators=200, max_depth=15, random_state=42)
    model_start.fit(X_train, y_train_start)
    
    y_train_dur_cat = np.array([categorize_duration(d) for d in y_train_duration])
    model_duration = RandomForestClassifier(n_estimators=200, max_depth=15, random_state=42)
    model_duration.fit(X_train, y_train_dur_cat)
    
    test_cases = [
        ("Lunes intenso", 2, 0, 0, 6, 1, 300, 8),
        ("Lunes normal", 2, 0, 0, 3, 0, 150, 5),
        ("Viernes ligero", 6, 0, 0, 1, 0, 60, 2),
        ("Miércoles medio", 4, 0, 0, 4, 0, 180, 6),
        ("Sábado", 7, 1, 0, 0, 0, 0, 0),
    ]
    
    print("\n   Predicciones (Start + Duration → End):")
    print("   " + "-" * 60)
    
    for name, *vals in test_cases:
        row = {}
        cols = ['dayOfWeek', 'isWeekend', 'isHoliday', 'totalMeetingCount', 
                'hasImportantDeadline', 'deepWorkMinutes', 'taskCompleted']
        for i, col in enumerate(cols):
            row[col] = vals[i]
        
        # Calcular features
        row['day_sin'] = np.sin(2 * np.pi * (row['dayOfWeek'] - 1) / 7)
        row['day_cos'] = np.cos(2 * np.pi * (row['dayOfWeek'] - 1) / 7)
        row['is_monday'] = 1 if row['dayOfWeek'] == 2 else 0
        row['is_friday'] = 1 if row['dayOfWeek'] == 6 else 0
        row['earlyMeetingCount'] = 1 if row['totalMeetingCount'] > 0 and row['dayOfWeek'] == 2 else 0
        row['sessionCount'] = max(1, row['deepWorkMinutes'] // 90)
        row['deepWorkEfficiency'] = 0.6 if row['deepWorkMinutes'] > 0 else 0
        row['meetingDensity'] = row['totalMeetingCount'] / 10
        row['earlyMeetingRatio'] = row['earlyMeetingCount'] / (row['totalMeetingCount'] + 1)
        row['intensityRatio'] = row['deepWorkMinutes'] / (row['totalMeetingCount'] * 60 + 1)
        
        features = [row[f] for f in feature_cols]
        
        # Predecir
        start = model_start.predict([features])[0]
        dur_cat = model_duration.predict([features])[0]
        cat_to_hours = {0: 0, 1: 3, 2: 5, 3: 7, 4: 9, 5: 11}
        duration = cat_to_hours[dur_cat]
        
        end = start + duration if start > 0 else 0
        
        if start == 0:
            print(f"   {name:20s} → No trabaja")
        else:
            print(f"   {name:20s} → {start:02d}:00 - {end:02d}:00 ({duration}h)")
    
    print("\n" + "="*80)
    print("✅ LISTO PARA CREATE ML")
    print("="*80)
    print(f"""
Recomendación:
   Mejor estrategia: {results_sorted[0][0]} ({results_sorted[0][1]:.1%})
   
Para Create ML, crea DOS modelos:
   1. StartHourPredictor.mlmodel - Target: 'startHour' (0, 7-11)
   2. DurationPredictor.mlmodel  - Target: 'workDuration' (0, 3, 5, 7, 9, 11)
   
   En Swift:
   let start = startModel.predict(...)
   let duration = durationModel.predict(...)
   let end = start + duration
    """)

if __name__ == "__main__":
    main()
