#!/usr/bin/env python3
"""
Entrenador de modelos CoreML para Busylight
Entrena Random Forest para predecir startHour y endHour
Exporta modelos en formato .mlpackage para Xcode
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.metrics import classification_report, accuracy_score, mean_absolute_error
from sklearn.model_selection import cross_val_score
import coremltools as ct
import warnings
warnings.filterwarnings('ignore')

def load_data():
    """Carga los datasets"""
    train_df = pd.read_csv('work_schedule_training_data.csv')
    val_df = pd.read_csv('work_schedule_validation.csv')
    test_df = pd.read_csv('testing_data.csv')
    
    print(f"📊 Datasets cargados:")
    print(f"   Training: {len(train_df)} registros")
    print(f"   Validation: {len(val_df)} registros")
    print(f"   Testing: {len(test_df)} registros")
    print()
    
    return train_df, val_df, test_df

def train_start_hour_model(train_df, val_df, test_df):
    """Entrena modelo para predecir startHour"""
    print("=" * 60)
    print("🎯 ENTRENANDO MODELO: StartHour")
    print("=" * 60)
    
    # Features
    feature_cols = ['dayOfWeek', 'isWeekend', 'isHoliday', 'sessionCount', 
                    'deepWorkMinutes', 'calendarEventCount']
    
    X_train = train_df[feature_cols]
    y_train = train_df['startHour']
    X_val = val_df[feature_cols]
    y_val = val_df['startHour']
    X_test = test_df[feature_cols]
    y_test = test_df['startHour']
    
    # Entrenar Random Forest Classifier (startHour es categórico 0-20)
    print("🌲 Entrenando Random Forest Classifier...")
    model = RandomForestClassifier(
        n_estimators=200,      # Más árboles para mejor precisión
        max_depth=12,          # Profundidad controlada
        min_samples_split=10,  # Evitar overfitting
        min_samples_leaf=5,
        max_features='sqrt',
        class_weight='balanced', # Balancear clases
        random_state=42
    )
    
    model.fit(X_train, y_train)
    
    # Evaluar
    train_pred = model.predict(X_train)
    val_pred = model.predict(X_val)
    test_pred = model.predict(X_test)
    
    train_acc = accuracy_score(y_train, train_pred)
    val_acc = accuracy_score(y_val, val_pred)
    test_acc = accuracy_score(y_test, test_pred)
    
    train_mae = mean_absolute_error(y_train, train_pred)
    val_mae = mean_absolute_error(y_val, val_pred)
    test_mae = mean_absolute_error(y_test, test_pred)
    
    print(f"\n📈 RESULTADOS StartHour:")
    print(f"   Training Accuracy:   {train_acc:.1%}")
    print(f"   Validation Accuracy: {val_acc:.1%}")
    print(f"   Testing Accuracy:    {test_acc:.1%}")
    print(f"   Training MAE:        {train_mae:.2f} horas")
    print(f"   Validation MAE:      {val_mae:.2f} horas")
    print(f"   Testing MAE:         {test_mae:.2f} horas")
    
    # Feature importance
    print(f"\n🔍 Feature Importance:")
    for feat, imp in sorted(zip(feature_cols, model.feature_importances_), 
                            key=lambda x: x[1], reverse=True):
        print(f"   {feat:20s}: {imp:.3f}")
    
    # Exportar a CoreML
    print(f"\n💾 Exportando a CoreML...")
    coreml_model = ct.converters.sklearn.convert(
        model,
        input_features=feature_cols,
        output_feature_names='startHour'
    )
    
    # Metadata
    coreml_model.author = 'Busylight ML'
    coreml_model.license = 'Proprietary'
    coreml_model.short_description = 'Predicts optimal start hour based on work patterns'
    coreml_model.version = '1.0'
    
    # Guardar
    coreml_model.save('StartHours.mlmodel')
    print(f"   ✅ Guardado: StartHours.mlmodel")
    
    return model, test_acc

def train_end_hour_model(train_df, val_df, test_df):
    """Entrena modelo para predecir endHour"""
    print("\n" + "=" * 60)
    print("🎯 ENTRENANDO MODELO: EndHour")
    print("=" * 60)
    
    # Features + startHour (para que el modelo sepa cuándo empezó)
    feature_cols = ['dayOfWeek', 'isWeekend', 'isHoliday', 'sessionCount', 
                    'deepWorkMinutes', 'calendarEventCount', 'startHour']
    
    X_train = train_df[feature_cols]
    y_train = train_df['endHour']
    X_val = val_df[feature_cols]
    y_val = val_df['endHour']
    X_test = test_df[feature_cols]
    y_test = test_df['endHour']
    
    print("🌲 Entrenando Random Forest Regressor...")
    model = RandomForestRegressor(
        n_estimators=200,
        max_depth=12,
        min_samples_split=10,
        min_samples_leaf=5,
        random_state=42
    )
    
    model.fit(X_train, y_train)
    
    # Evaluar
    train_pred = np.round(model.predict(X_train)).astype(int)
    val_pred = np.round(model.predict(X_val)).astype(int)
    test_pred = np.round(model.predict(X_test)).astype(int)
    
    # Clampear a 0-23
    train_pred = np.clip(train_pred, 0, 23)
    val_pred = np.clip(val_pred, 0, 23)
    test_pred = np.clip(test_pred, 0, 23)
    
    train_mae = mean_absolute_error(y_train, train_pred)
    val_mae = mean_absolute_error(y_val, val_pred)
    test_mae = mean_absolute_error(y_test, test_pred)
    
    train_acc = accuracy_score(y_train, train_pred)
    val_acc = accuracy_score(y_val, val_pred)
    test_acc = accuracy_score(y_test, test_pred)
    
    print(f"\n📈 RESULTADOS EndHour:")
    print(f"   Training Accuracy:   {train_acc:.1%}")
    print(f"   Validation Accuracy: {val_acc:.1%}")
    print(f"   Testing Accuracy:    {test_acc:.1%}")
    print(f"   Training MAE:        {train_mae:.2f} horas")
    print(f"   Validation MAE:      {val_mae:.2f} horas")
    print(f"   Testing MAE:         {test_mae:.2f} horas")
    
    # Feature importance
    print(f"\n🔍 Feature Importance:")
    for feat, imp in sorted(zip(feature_cols, model.feature_importances_), 
                            key=lambda x: x[1], reverse=True):
        print(f"   {feat:20s}: {imp:.3f}")
    
    # Exportar a CoreML
    print(f"\n💾 Exportando a CoreML...")
    coreml_model = ct.converters.sklearn.convert(
        model,
        input_features=feature_cols,
        output_feature_names='endHour'
    )
    
    coreml_model.author = 'Busylight ML'
    coreml_model.license = 'Proprietary'
    coreml_model.short_description = 'Predicts optimal end hour based on work patterns'
    coreml_model.version = '1.0'
    
    coreml_model.save('EndHours.mlmodel')
    print(f"   ✅ Guardado: EndHours.mlmodel")
    
    return model, test_acc

def test_predictions(train_df):
    """Prueba algunas predicciones de ejemplo"""
    print("\n" + "=" * 60)
    print("🧪 PRUEBAS DE PREDICCIÓN")
    print("=" * 60)
    
    from sklearn.ensemble import RandomForestClassifier
    
    feature_cols = ['dayOfWeek', 'isWeekend', 'isHoliday', 'sessionCount', 
                    'deepWorkMinutes', 'calendarEventCount']
    
    X = train_df[feature_cols]
    y = train_df['startHour']
    model = RandomForestClassifier(n_estimators=200, max_depth=12, random_state=42)
    model.fit(X, y)
    
    # Casos de prueba
    test_cases = [
        # (descripción, día, finde, festivo, sesiones, deepWork, eventos)
        ("Lunes productivo", 2, 0, 0, 8, 240, 3),
        ("Viernes ligero", 6, 0, 0, 2, 30, 1),
        ("Domingo descanso", 1, 1, 0, 0, 0, 0),
        ("Miércoles festivo", 4, 0, 1, 0, 0, 0),
        ("Jornada intensa", 3, 0, 0, 10, 400, 5),
    ]
    
    for desc, *features in test_cases:
        pred = model.predict([features])[0]
        print(f"   {desc:20s}: {pred:2d}:00 (input: {features})")

def main():
    print("🚀 BUSYLIGHT ML TRAINER")
    print("Training CoreML models with scikit-learn")
    print()
    
    # Cargar datos
    train_df, val_df, test_df = load_data()
    
    # Entrenar modelos
    start_model, start_acc = train_start_hour_model(train_df, val_df, test_df)
    end_model, end_acc = train_end_hour_model(train_df, val_df, test_df)
    
    # Pruebas
    test_predictions(train_df)
    
    # Resumen final
    print("\n" + "=" * 60)
    print("📊 RESUMEN FINAL")
    print("=" * 60)
    print(f"   StartHour Model: {start_acc:.1%} accuracy")
    print(f"   EndHour Model:   {end_acc:.1%} accuracy")
    print(f"\n   Archivos generados:")
    print(f"   📄 StartHours.mlmodel")
    print(f"   📄 EndHours.mlmodel")
    print()
    print("💡 Para usar en Xcode:")
    print("   1. Arrastra los archivos .mlmodel a tu proyecto")
    print("   2. Selecciona 'Copy items if needed'")
    print("   3. El modelo se compilará automáticamente al build")

if __name__ == "__main__":
    main()
