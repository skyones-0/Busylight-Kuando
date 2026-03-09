4#!/usr/bin/env python3
"""
Entrenador V3: Agrupa horas en categorías para mejor accuracy
Early(6-8), Morning(9-10), Midday(11-12), Afternoon(13-16), Evening(17-20), None(0)
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report
import warnings
warnings.filterwarnings('ignore')

def hour_to_category(hour):
    """Convierte hora a categoría"""
    if hour == 0:
        return 0  # None
    elif hour <= 8:
        return 1  # Early (6-8)
    elif hour <= 10:
        return 2  # Morning (9-10)
    elif hour <= 12:
        return 3  # Midday (11-12)
    elif hour <= 16:
        return 4  # Afternoon (13-16)
    else:
        return 5  # Evening (17-20)

def category_to_hour_range(cat):
    """Convierte categoría a rango de horas"""
    ranges = {
        0: (0, 0),
        1: (6, 8),
        2: (9, 10),
        3: (11, 12),
        4: (13, 16),
        5: (17, 20)
    }
    return ranges.get(cat, (0, 0))

def train_categorical_model(train_df, val_df, test_df):
    """Entrena modelo con categorías de hora"""
    print("=" * 70)
    print("🎯 MODELO CON CATEGORÍAS DE HORA (6 clases)")
    print("=" * 70)
    
    # Convertir a categorías
    for df in [train_df, val_df, test_df]:
        df['startHour_cat'] = df['startHour'].apply(hour_to_category)
    
    feature_cols = ['dayOfWeek', 'isWeekend', 'isHoliday', 'sessionCount', 
                    'deepWorkMinutes', 'calendarEventCount']
    
    X_train = train_df[feature_cols]
    y_train = train_df['startHour_cat']
    X_val = val_df[feature_cols]
    y_val = val_df['startHour_cat']
    X_test = test_df[feature_cols]
    y_test = test_df['startHour_cat']
    
    print("\n📊 Distribución de categorías en training:")
    cat_counts = y_train.value_counts().sort_index()
    cat_names = {0: 'None', 1: 'Early(6-8)', 2: 'Morning(9-10)', 
                 3: 'Midday(11-12)', 4: 'Afternoon(13-16)', 5: 'Evening(17-20)'}
    for cat, count in cat_counts.items():
        print(f"   {cat} ({cat_names[cat]:15s}): {count} ejemplos")
    
    # Entrenar modelo
    print("\n🌲 Entrenando Random Forest...")
    model = RandomForestClassifier(
        n_estimators=500,
        max_depth=15,
        min_samples_leaf=8,
        class_weight='balanced',
        random_state=42
    )
    
    model.fit(X_train, y_train)
    
    # Evaluar
    train_acc = accuracy_score(y_train, model.predict(X_train))
    val_acc = accuracy_score(y_val, model.predict(X_val))
    test_acc = accuracy_score(y_test, model.predict(X_test))
    
    print(f"\n📈 RESULTADOS:")
    print(f"   Training:   {train_acc:.1%}")
    print(f"   Validation: {val_acc:.1%}")
    print(f"   Testing:    {test_acc:.1%}")
    
    # Reporte por clase
    print(f"\n📋 Reporte por categoría (Test):")
    y_pred = model.predict(X_test)
    print(classification_report(y_test, y_pred, target_names=[
        'None', 'Early', 'Morning', 'Midday', 'Afternoon', 'Evening'
    ]))
    
    return model, test_acc

def test_predictions_v3(model):
    """Prueba predicciones"""
    print("\n" + "=" * 70)
    print("🧪 PRUEBAS DE PREDICCIÓN")
    print("=" * 70)
    
    cat_names = {0: 'None', 1: 'Early(6-8)', 2: 'Morning(9-10)', 
                 3: 'Midday(11-12)', 4: 'Afternoon(13-16)', 5: 'Evening(17-20)'}
    
    test_cases = [
        ("Lunes productivo", 2, 0, 0, 8, 240, 3),
        ("Lunes normal", 2, 0, 0, 5, 120, 3),
        ("Viernes ligero", 6, 0, 0, 2, 30, 1),
        ("Viernes normal", 6, 0, 0, 5, 150, 2),
        ("Sábado descanso", 7, 1, 0, 0, 0, 0),
        ("Sábado trabajo", 7, 1, 0, 3, 90, 0),
        ("Festivo", 2, 0, 1, 0, 0, 0),
        ("Jornada intensa", 3, 0, 0, 11, 400, 6),
        ("Medio día", 4, 0, 0, 3, 60, 2),
    ]
    
    feature_cols = ['dayOfWeek', 'isWeekend', 'isHoliday', 'sessionCount', 
                    'deepWorkMinutes', 'calendarEventCount']
    
    for desc, *features in test_cases:
        pred_cat = model.predict([features])[0]
        pred_range = category_to_hour_range(pred_cat)
        print(f"   {desc:20s} → {cat_names[pred_cat]:15s} ({pred_range[0]}-{pred_range[1]}h)")

def export_to_csv_for_createml(train_df, val_df, test_df):
    """Exporta dataset con categorías para Create ML"""
    print("\n💾 Exportando datasets con categorías...")
    
    for df in [train_df, val_df, test_df]:
        df['startHour_cat'] = df['startHour'].apply(hour_to_category)
        df['startHour_cat_name'] = df['startHour_cat'].map({
            0: 'None', 1: 'Early', 2: 'Morning', 3: 'Midday', 4: 'Afternoon', 5: 'Evening'
        })
    
    # Guardar CSVs con categoría
    train_df.to_csv('work_schedule_training_categorical.csv', index=False)
    val_df.to_csv('work_schedule_validation_categorical.csv', index=False)
    test_df.to_csv('work_schedule_testing_categorical.csv', index=False)
    
    print("   ✅ work_schedule_training_categorical.csv")
    print("   ✅ work_schedule_validation_categorical.csv")
    print("   ✅ work_schedule_testing_categorical.csv")

def main():
    print("🚀 BUSYLIGHT ML TRAINER V3")
    print("Clasificación por categorías de hora")
    print()
    
    # Cargar datos
    train_df = pd.read_csv('work_schedule_training_data.csv')
    val_df = pd.read_csv('work_schedule_validation.csv')
    test_df = pd.read_csv('testing_data.csv')
    
    print(f"📊 Datasets: {len(train_df)} train, {len(val_df)} val, {len(test_df)} test")
    
    # Entrenar modelo categórico
    model, acc = train_categorical_model(train_df, val_df, test_df)
    
    # Pruebas
    test_predictions_v3(model)
    
    # Exportar datasets para Create ML
    export_to_csv_for_createml(train_df, val_df, test_df)
    
    print("\n" + "=" * 70)
    print("✅ ANÁLISIS COMPLETO")
    print("=" * 70)
    print(f"\nConclusión:")
    print(f"   - Con 21 clases (horas individuales): ~20% accuracy")
    print(f"   - Con 6 categorías: ~{acc:.0%} accuracy")
    print(f"\nRecomendación:")
    print(f"   Usa las categorías en Create ML para mejor resultado")
    print(f"   O acepta MAE de ~2 horas con regresión")

if __name__ == "__main__":
    main()
