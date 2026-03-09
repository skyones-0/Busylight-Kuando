#!/usr/bin/env python3
"""
Entrenador de modelos ML para Busylight - V2
Soluciona problemas de rendimiento con feature engineering
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, mean_absolute_error, classification_report
import warnings
warnings.filterwarnings('ignore')

def engineer_features(df):
    """Crea features adicionales para mejorar predicción"""
    df = df.copy()
    
    # Features de interacción
    df['workload_score'] = df['sessionCount'] * 30 + df['deepWorkMinutes'] / 10
    df['is_high_intensity'] = (df['deepWorkMinutes'] > 180).astype(int)
    df['is_very_productive'] = ((df['sessionCount'] >= 7) & (df['deepWorkMinutes'] >= 240)).astype(int)
    
    # Categorías de día
    df['day_category'] = df.apply(lambda row: 
        2 if row['isHoliday'] == 1 else
        (1 if row['isWeekend'] == 1 else 0), axis=1)
    
    # Features de tiempo estimado
    df['estimated_duration'] = df['sessionCount'] * 45 + df['deepWorkMinutes'] / 60 * 30
    df['estimated_duration'] = df['estimated_duration'].clip(0, 12)
    
    # Interacción entre features
    df['sessions_x_deepwork'] = df['sessionCount'] * df['deepWorkMinutes'] / 100
    df['events_x_sessions'] = df['calendarEventCount'] * df['sessionCount']
    
    return df

def analyze_data(df, name):
    """Analiza la distribución de datos"""
    print(f"\n📊 Análisis de {name}:")
    print(f"   Total registros: {len(df)}")
    print(f"\n   Distribución de startHour:")
    counts = df['startHour'].value_counts().sort_index()
    for hour, count in counts.items():
        print(f"      Hour {hour:2d}: {count:3d} ejemplos")
    
    print(f"\n   Estadísticas:")
    print(f"      Media startHour: {df['startHour'].mean():.1f}")
    print(f"      Media endHour: {df['endHour'].mean():.1f}")
    print(f"      Media sessionCount: {df['sessionCount'].mean():.1f}")
    print(f"      Media deepWorkMinutes: {df['deepWorkMinutes'].mean():.1f}")

def train_start_hour_model_v2(train_df, val_df, test_df):
    """Entrena modelo mejorado para startHour"""
    print("\n" + "=" * 70)
    print("🎯 ENTRENANDO MODELO STARTHOUR V2 (con feature engineering)")
    print("=" * 70)
    
    # Feature engineering
    train_df = engineer_features(train_df)
    val_df = engineer_features(val_df)
    test_df = engineer_features(test_df)
    
    # Features mejoradas
    feature_cols = ['dayOfWeek', 'isWeekend', 'isHoliday', 'sessionCount', 
                    'deepWorkMinutes', 'calendarEventCount',
                    'workload_score', 'is_high_intensity', 'is_very_productive',
                    'day_category', 'estimated_duration', 'sessions_x_deepwork']
    
    X_train = train_df[feature_cols]
    y_train = train_df['startHour']
    X_val = val_df[feature_cols]
    y_val = val_df['startHour']
    X_test = test_df[feature_cols]
    y_test = test_df['startHour']
    
    # Probar diferentes configuraciones
    configs = [
        ("Conservador", RandomForestClassifier(n_estimators=100, max_depth=6, min_samples_leaf=10, random_state=42)),
        ("Balanceado", RandomForestClassifier(n_estimators=200, max_depth=10, min_samples_leaf=5, random_state=42)),
        ("Complejo", RandomForestClassifier(n_estimators=300, max_depth=15, min_samples_leaf=2, random_state=42)),
        ("Boosting", GradientBoostingClassifier(n_estimators=100, max_depth=5, random_state=42)),
    ]
    
    best_model = None
    best_acc = 0
    best_name = ""
    
    for name, model in configs:
        model.fit(X_train, y_train)
        
        train_acc = accuracy_score(y_train, model.predict(X_train))
        val_acc = accuracy_score(y_val, model.predict(X_val))
        test_acc = accuracy_score(y_test, model.predict(X_test))
        
        train_mae = mean_absolute_error(y_train, model.predict(X_train))
        val_mae = mean_absolute_error(y_val, model.predict(X_val))
        test_mae = mean_absolute_error(y_test, model.predict(X_test))
        
        print(f"\n   {name}:")
        print(f"      Train: {train_acc:.1%} (MAE: {train_mae:.2f})")
        print(f"      Val:   {val_acc:.1%} (MAE: {val_mae:.2f})")
        print(f"      Test:  {test_acc:.1%} (MAE: {test_mae:.2f})")
        
        # Elegir mejor modelo basado en validación (no training para evitar overfitting)
        if val_acc > best_acc:
            best_acc = val_acc
            best_model = model
            best_name = name
    
    print(f"\n🏆 Mejor modelo: {best_name}")
    print(f"   Validation Accuracy: {best_acc:.1%}")
    
    # Feature importance del mejor modelo
    print(f"\n🔍 Feature Importance ({best_name}):")
    importances = sorted(zip(feature_cols, best_model.feature_importances_), 
                        key=lambda x: x[1], reverse=True)
    for feat, imp in importances[:8]:
        print(f"      {feat:25s}: {imp:.3f}")
    
    return best_model, feature_cols

def test_specific_cases(model, feature_cols):
    """Prueba casos específicos"""
    print("\n" + "=" * 70)
    print("🧪 PRUEBAS DE PREDICCIÓN")
    print("=" * 70)
    
    test_cases = [
        ("Lunes productivo", 2, 0, 0, 8, 240, 3),
        ("Lunes normal", 2, 0, 0, 5, 120, 3),
        ("Viernes ligero", 6, 0, 0, 2, 30, 1),
        ("Viernes normal", 6, 0, 0, 5, 150, 2),
        ("Sábado descanso", 7, 1, 0, 0, 0, 0),
        ("Sábado trabajo", 7, 1, 0, 3, 90, 0),
        ("Domingo", 1, 1, 0, 0, 0, 0),
        ("Festivo", 2, 0, 1, 0, 0, 0),
        ("Festivo trabajo", 2, 0, 1, 2, 60, 1),
        ("Jornada intensa", 3, 0, 0, 11, 400, 6),
        ("Medio día", 4, 0, 0, 3, 60, 2),
        ("Tarde", 5, 0, 0, 4, 120, 3),
    ]
    
    for desc, *base_features in test_cases:
        # Crear features con engineering
        dayOfWeek, isWeekend, isHoliday, sessionCount, deepWorkMinutes, calendarEventCount = base_features
        
        workload_score = sessionCount * 30 + deepWorkMinutes / 10
        is_high_intensity = 1 if deepWorkMinutes > 180 else 0
        is_very_productive = 1 if (sessionCount >= 7 and deepWorkMinutes >= 240) else 0
        day_category = 2 if isHoliday else (1 if isWeekend else 0)
        estimated_duration = min(sessionCount * 45 + deepWorkMinutes / 60 * 30, 12)
        sessions_x_deepwork = sessionCount * deepWorkMinutes / 100
        
        features = [dayOfWeek, isWeekend, isHoliday, sessionCount, deepWorkMinutes, 
                   calendarEventCount, workload_score, is_high_intensity, 
                   is_very_productive, day_category, estimated_duration, sessions_x_deepwork]
        
        pred = model.predict([features])[0]
        print(f"   {desc:20s} → {pred:2d}:00 (input: sessions={sessionCount}, deepWork={deepWorkMinutes})")

def main():
    print("🚀 BUSYLIGHT ML TRAINER V2")
    print("Mejorado con Feature Engineering")
    print()
    
    # Cargar datos
    train_df = pd.read_csv('work_schedule_training_data.csv')
    val_df = pd.read_csv('work_schedule_validation.csv')
    test_df = pd.read_csv('testing_data.csv')
    
    print(f"📊 Datasets cargados:")
    print(f"   Training: {len(train_df)} registros")
    print(f"   Validation: {len(val_df)} registros")
    print(f"   Testing: {len(test_df)} registros")
    
    # Analizar datos
    analyze_data(train_df, "Training")
    
    # Entrenar modelo
    model, feature_cols = train_start_hour_model_v2(train_df, val_df, test_df)
    
    # Pruebas
    test_specific_cases(model, feature_cols)
    
    # Guardar modelo para uso en Python (no CoreML por incompatibilidad)
    import pickle
    with open('start_hour_model.pkl', 'wb') as f:
        pickle.dump({'model': model, 'features': feature_cols}, f)
    
    print("\n💾 Modelo guardado en: start_hour_model.pkl")
    print("\n📌 Para usar en la app:")
    print("   Opción 1: Usar el modelo .pkl con un backend Python")
    print("   Opción 2: Reentrenar en Create ML con los insights de este análisis")
    print("   Opción 3: Usar el dataset mejorado con feature engineering")

if __name__ == "__main__":
    main()
