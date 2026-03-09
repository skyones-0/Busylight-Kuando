#!/usr/bin/env python3
"""
Script para entrenar modelo y exportar a CoreML (.mlmodel)
Usa scikit-learn + coremltools

Instalación requerida:
    pip install scikit-learn==1.5.1 coremltools pandas numpy
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import warnings
warnings.filterwarnings('ignore')

# ============================================================================
# 1. CARGAR Y PREPARAR DATOS
# ============================================================================

def load_data():
    """Carga el dataset"""
    print("📊 Cargando datos...")
    
    df = pd.read_csv('work_schedule_FINAL_for_createml.csv')
    
    # Features (13)
    feature_cols = [
        'dayOfWeek', 'isWeekend', 'isHoliday',
        'totalMeetingCount', 'hasImportantDeadline', 'earlyMeetingCount',
        'sessionCount', 'deepWorkMinutes', 'taskCompleted',
        'deepWorkEfficiency', 'meetingDensity', 'earlyMeetingRatio', 'intensityRatio'
    ]
    
    # Target
    target_col = 'startHour'
    
    X = df[feature_cols]
    y = df[target_col]
    
    print(f"   Features: {len(feature_cols)}")
    print(f"   Target: {target_col}")
    print(f"   Registros: {len(df)}")
    print(f"   Clases: {sorted(y.unique())}")
    
    return X, y, feature_cols

# ============================================================================
# 2. ENTRENAR MODELO
# ============================================================================

def train_model(X, y):
    """Entrena el modelo de Random Forest"""
    print("\n🎯 Entrenando modelo Random Forest...")
    
    # Dividir en train/test
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    # Modelo
    model = RandomForestClassifier(
        n_estimators=200,
        max_depth=15,
        min_samples_leaf=2,
        min_samples_split=5,
        class_weight='balanced',
        random_state=42,
        n_jobs=-1
    )
    
    # Entrenar
    model.fit(X_train, y_train)
    
    # Evaluar
    train_acc = accuracy_score(y_train, model.predict(X_train))
    test_acc = accuracy_score(y_test, model.predict(X_test))
    test_acc_pm1 = (np.abs(model.predict(X_test) - y_test) <= 1).mean()
    
    print(f"   ✅ Training accuracy: {train_acc:.1%}")
    print(f"   ✅ Test accuracy: {test_acc:.1%}")
    print(f"   ✅ Test accuracy ±1h: {test_acc_pm1:.1%}")
    
    # Reporte detallado
    print("\n📋 Reporte por clase:")
    print(classification_report(y_test, model.predict(X_test), zero_division=0))
    
    # Importancia de features
    print("\n📊 Features más importantes:")
    importances = pd.DataFrame({
        'feature': X.columns,
        'importance': model.feature_importances_
    }).sort_values('importance', ascending=False)
    
    for _, row in importances.head(10).iterrows():
        bar = "█" * int(row['importance'] * 50)
        print(f"   {row['importance']:.3f} | {row['feature']:25s} {bar}")
    
    return model, X.columns.tolist(), X_train, X_test, y_train, y_test

# ============================================================================
# 3. EXPORTAR A COREML
# ============================================================================

def export_to_coreml(model, feature_names, X_train, output_name="StartHourPredictor"):
    """Exporta el modelo a formato CoreML (.mlmodel)"""
    print(f"\n📦 Exportando a CoreML: {output_name}.mlmodel")
    
    try:
        import coremltools as ct
        print(f"   coremltools versión: {ct.__version__}")
        
        # Método 1: Usar convertidor de sklearn (puede fallar con versiones nuevas)
        try:
            coreml_model = ct.converters.sklearn.convert(
                model,
                feature_names,
                "startHour"
            )
        except Exception as e1:
            print(f"   ⚠️  sklearn converter falló: {e1}")
            print("   Intentando método alternativo...")
            
            # Método 2: Usar converters.convert con specify input
            # Convertir a spec primero
            from sklearn import __version__ as sklearn_version
            print(f"   sklearn versión: {sklearn_version}")
            
            # Para sklearn >= 1.6, necesitamos usar tree_ensemble directly
            import coremltools.models.tree_ensemble as tree_ensemble
            
            # Crear especificación manualmente
            spec = tree_ensemble.tree_ensemble_classifier(
                model,
                feature_names,
                "startHour",
                {int(c): f"hour_{c}" for c in model.classes_}
            )
            coreml_model = ct.models.MLModel(spec)
        
        # Metadata del modelo
        coreml_model.author = "Busylight App"
        coreml_model.license = "MIT"
        coreml_model.short_description = "Predice la hora de inicio de trabajo"
        
        # Guardar
        output_path = f"{output_name}.mlmodel"
        coreml_model.save(output_path)
        
        print(f"   ✅ Modelo guardado: {output_path}")
        print(f"   📏 Tamaño: {get_file_size(output_path)}")
        
        return output_path
        
    except ImportError:
        print("❌ coremltools no instalado")
        print("   Instala con: pip install coremltools")
        return None
    except Exception as e:
        print(f"❌ Error en exportación: {e}")
        return None

def get_file_size(path):
    """Obtiene tamaño de archivo en KB"""
    import os
    size_bytes = os.path.getsize(path)
    size_kb = size_bytes / 1024
    return f"{size_kb:.1f} KB"

# ============================================================================
# 4. EXPORTAR USANDO ONNX (alternativa)
# ============================================================================

def export_to_onnx(model, X_train, feature_names, output_name="StartHourPredictor"):
    """Exporta a ONNX como alternativa a CoreML"""
    print(f"\n📦 Exportando a ONNX: {output_name}.onnx")
    
    try:
        import skl2onnx
        from skl2onnx import convert_sklearn
        from skl2onnx.common.data_types import FloatTensorType
        
        # Definir tipo de input
        initial_type = [('float_input', FloatTensorType([None, len(feature_names)]))]
        
        # Convertir
        onnx_model = convert_sklearn(model, initial_types=initial_type)
        
        # Guardar
        output_path = f"{output_name}.onnx"
        with open(output_path, "wb") as f:
            f.write(onnx_model.SerializeToString())
        
        print(f"   ✅ Modelo ONNX guardado: {output_path}")
        print(f"   📏 Tamaño: {get_file_size(output_path)}")
        
        # Convertir ONNX a CoreML
        print("\n   Convirtiendo ONNX a CoreML...")
        import coremltools as ct
        
        mlmodel = ct.converters.onnx.convert(
            model=onnx_model,
            features=feature_names,
            target='startHour'
        )
        mlmodel.save(f"{output_name}_from_onnx.mlmodel")
        print(f"   ✅ CoreML desde ONNX: {output_name}_from_onnx.mlmodel")
        
        return output_path
        
    except ImportError as e:
        print(f"   ⚠️  Librería no instalada: {e}")
        return None

# ============================================================================
# 5. GUARDAR COMO PICKLE (alternativa simple)
# ============================================================================

def save_as_pickle(model, output_name="StartHourPredictor"):
    """Guarda el modelo como pickle (para usar en backend)"""
    import pickle
    import os
    
    output_path = f"{output_name}.pkl"
    with open(output_path, 'wb') as f:
        pickle.dump(model, f)
    
    print(f"\n💾 Modelo pickle guardado: {output_path}")
    print(f"   📏 Tamaño: {get_file_size(output_path)}")
    
    return output_path

# ============================================================================
# 6. PRUEBA DEL MODELO
# ============================================================================

def test_predictions(model, feature_names):
    """Prueba el modelo con ejemplos"""
    print("\n🧪 EJEMPLOS DE PREDICCIÓN:")
    print("-" * 60)
    
    test_cases = [
        ("Lunes normal", 2, 0, 0, 3, 0, 0, 3, 150, 4, 0.6, 0.3, 0.0, 0.8),
        ("Lunes intenso", 2, 0, 0, 6, 1, 1, 5, 300, 8, 0.7, 0.6, 0.17, 0.8),
        ("Viernes ligero", 6, 0, 0, 1, 0, 0, 1, 60, 2, 0.5, 0.1, 0.0, 1.0),
        ("Sábado", 7, 1, 0, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0),
        ("Miércoles medio", 4, 0, 0, 4, 0, 0, 3, 180, 5, 0.6, 0.4, 0.0, 0.7),
    ]
    
    for name, *values in test_cases:
        features = dict(zip(feature_names, values))
        features_array = np.array([values])
        prediction = model.predict(features_array)[0]
        
        if prediction == 0:
            result = "No trabaja"
        else:
            end = prediction + 8
            result = f"{prediction}:00 - {end}:00"
        
        print(f"   {name:20s} → {result}")

# ============================================================================
# 7. MAIN
# ============================================================================

def main():
    print("="*70)
    print("🚀 ENTRENAMIENTO Y EXPORTACIÓN A COREML")
    print("="*70)
    
    # Cargar datos
    X, y, feature_names = load_data()
    
    # Entrenar modelo
    model, feature_names, X_train, X_test, y_train, y_test = train_model(X, y)
    
    # Guardar como pickle (siempre funciona)
    save_as_pickle(model, "StartHourPredictor")
    
    # Intentar exportar a CoreML
    print("\n" + "="*70)
    print("📦 EXPORTACIÓN A COREML")
    print("="*70)
    
    coreml_path = export_to_coreml(model, feature_names, X_train, "StartHourPredictor")
    
    if coreml_path is None:
        print("\n⚠️  La exportación a CoreML falló.")
        print("   Razones posibles:")
        print("   1. scikit-learn versión incompatible (necesita <= 1.5.1)")
        print("   2. coremltools no instalado")
        print("\n💡 Solución: Usa el modelo .pkl con Python en tu backend")
        print("   O instala: pip install scikit-learn==1.5.1")
    
    # Probar predicciones
    test_predictions(model, feature_names)
    
    print("\n" + "="*70)
    print("✅ COMPLETADO")
    print("="*70)
    
    if coreml_path:
        print(f"""
Archivos generados:
   📦 StartHourPredictor.mlmodel - Modelo CoreML
   💾 StartHourPredictor.pkl - Modelo pickle (backup)

Para usar en Xcode:
   1. Arrastra StartHourPredictor.mlmodel a tu proyecto
   2. Xcode generará la clase StartHourPredictor automáticamente
        """)
    else:
        print(f"""
Archivos generados:
   💾 StartHourPredictor.pkl - Modelo pickle

Para usar el modelo:
   Opción 1: Usar Python en tu backend
   Opción 2: Instalar scikit-learn==1.5.1 y reexportar
   Opción 3: Crear predicciones offline y guardarlas en la app
        """)

if __name__ == "__main__":
    main()
