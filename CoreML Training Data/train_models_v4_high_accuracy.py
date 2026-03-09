#!/usr/bin/env python3
"""
Entrenador V4: Objetivo 90% accuracy
Estrategias:
1. Feature engineering avanzado
2. Probar diferentes agrupaciones de categorías
3. Probar Gradient Boosting y otros algoritmos
4. Identificar cuál es el límite máximo posible
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier, ExtraTreesClassifier
from sklearn.preprocessing import StandardScaler, PolynomialFeatures
from sklearn.metrics import accuracy_score, classification_report
import warnings
warnings.filterwarnings('ignore')

def advanced_feature_engineering(df):
    """Feature engineering agresivo para maximizar accuracy"""
    df = df.copy()
    
    # Features básicas
    df['workload_score'] = df['sessionCount'] * 30 + df['deepWorkMinutes'] / 10
    df['is_high_intensity'] = (df['deepWorkMinutes'] > 180).astype(int)
    df['is_very_productive'] = ((df['sessionCount'] >= 7) & (df['deepWorkMinutes'] >= 240)).astype(int)
    
    # Categorías de día más detalladas
    df['day_category'] = df.apply(lambda row: 
        2 if row['isHoliday'] == 1 else
        (1 if row['isWeekend'] == 1 else 0), axis=1)
    
    # Features de tiempo
    df['estimated_duration'] = df['sessionCount'] * 45 + df['deepWorkMinutes'] / 60 * 30
    df['estimated_duration'] = df['estimated_duration'].clip(0, 12)
    
    # Interacciones
    df['sessions_x_deepwork'] = df['sessionCount'] * df['deepWorkMinutes'] / 100
    df['events_x_sessions'] = df['calendarEventCount'] * df['sessionCount']
    df['deepwork_per_session'] = df['deepWorkMinutes'] / (df['sessionCount'] + 1)
    
    # Features polinómicas (cuadráticas)
    df['sessionCount_sq'] = df['sessionCount'] ** 2
    df['deepWork_sq'] = (df['deepWorkMinutes'] / 60) ** 2
    
    # Features logarítmicas
    df['sessionCount_log'] = np.log1p(df['sessionCount'])
    df['deepWork_log'] = np.log1p(df['deepWorkMinutes'])
    
    # Features de ratios
    df['deepwork_ratio'] = df['deepWorkMinutes'] / 480  # Ratio vs 8 horas
    df['session_density'] = df['sessionCount'] / 12  # Ratio vs max 12 sesiones
    
    # Features específicas por día
    df['is_monday'] = (df['dayOfWeek'] == 2).astype(int)
    df['is_friday'] = (df['dayOfWeek'] == 6).astype(int)
    df['is_wednesday'] = (df['dayOfWeek'] == 4).astype(int)
    
    return df

def try_different_groupings(df):
    """Prueba diferentes agrupaciones de categorías para maximizar accuracy"""
    
    # Agrupación 1: Original (6 categorías)
    df['cat_6'] = df['startHour'].apply(lambda h: 
        0 if h == 0 else
        1 if h <= 8 else
        2 if h <= 10 else
        3 if h <= 12 else
        4 if h <= 16 else
        5)
    
    # Agrupación 2: 4 categorías (más anchas)
    df['cat_4'] = df['startHour'].apply(lambda h:
        0 if h == 0 else      # None
        1 if h <= 10 else     # Early-Morning (1-10)
        2 if h <= 16 else     # Midday-Afternoon (11-16)
        3)                     # Evening (17-20)
    
    # Agrupación 3: 5 categorías
    df['cat_5'] = df['startHour'].apply(lambda h:
        0 if h == 0 else      # None
        1 if h <= 8 else      # Early (1-8)
        2 if h <= 12 else     # Morning-Midday (9-12)
        3 if h <= 16 else     # Afternoon (13-16)
        4)                     # Evening (17-20)
    
    # Agrupación 4: Solo trabaja/no trabaja + early/late
    df['cat_binary'] = df['startHour'].apply(lambda h:
        0 if h == 0 else      # No trabaja
        1 if h <= 12 else     # Antes medio día
        2)                     # Después medio día
    
    # Agrupación 5: 3 categorías amplias
    df['cat_3'] = df['startHour'].apply(lambda h:
        0 if h == 0 else      # None
        1 if h <= 14 else     # Early-Midday (1-14)
        2)                     # Afternoon-Evening (15-20)
    
    return df

def train_with_config(train_df, val_df, test_df, target_col, config_name):
    """Entrena modelo con una configuración específica"""
    
    feature_cols = [c for c in train_df.columns if c not in [
        'startHour', 'endHour', 'cat_6', 'cat_4', 'cat_5', 'cat_binary', 'cat_3']]
    
    X_train = train_df[feature_cols]
    y_train = train_df[target_col]
    X_val = val_df[feature_cols]
    y_val = val_df[target_col]
    X_test = test_df[feature_cols]
    y_test = test_df[target_col]
    
    models = [
        ("Random Forest", RandomForestClassifier(n_estimators=300, max_depth=15, min_samples_leaf=3, random_state=42)),
        ("Extra Trees", ExtraTreesClassifier(n_estimators=300, max_depth=15, min_samples_leaf=3, random_state=42)),
        ("Gradient Boosting", GradientBoostingClassifier(n_estimators=200, max_depth=5, random_state=42)),
    ]
    
    best_result = None
    best_acc = 0
    
    print(f"\n{'='*70}")
    print(f"📊 CONFIGURACIÓN: {config_name}")
    print(f"   Clases: {len(y_train.unique())}")
    print(f"   Target: {target_col}")
    
    for model_name, model in models:
        model.fit(X_train, y_train)
        
        train_acc = accuracy_score(y_train, model.predict(X_train))
        val_acc = accuracy_score(y_val, model.predict(X_val))
        test_acc = accuracy_score(y_test, model.predict(X_test))
        
        print(f"\n   {model_name}:")
        print(f"      Train: {train_acc:.1%} | Val: {val_acc:.1%} | Test: {test_acc:.1%}")
        
        if val_acc > best_acc:
            best_acc = val_acc
            best_result = {
                'config': config_name,
                'model': model_name,
                'val_acc': val_acc,
                'test_acc': test_acc,
                'train_acc': train_acc
            }
    
    return best_result

def main():
    print("🚀 BUSYLIGHT ML TRAINER V4")
    print("Objetivo: 90% accuracy")
    print("="*70)
    
    # Cargar datos
    train_df = pd.read_csv('work_schedule_training_data.csv')
    val_df = pd.read_csv('work_schedule_validation.csv')
    test_df = pd.read_csv('testing_data.csv')
    
    print(f"\n📊 Datasets: {len(train_df)} train, {len(val_df)} val, {len(test_df)} test")
    
    # Feature engineering avanzado
    print("\n⚙️  Feature Engineering Avanzado...")
    train_df = advanced_feature_engineering(train_df)
    val_df = advanced_feature_engineering(val_df)
    test_df = advanced_feature_engineering(test_df)
    
    # Probar diferentes agrupaciones
    train_df = try_different_groupings(train_df)
    val_df = try_different_groupings(val_df)
    test_df = try_different_groupings(test_df)
    
    print(f"   Features creadas: {len([c for c in train_df.columns if c not in ['startHour', 'endHour']])}")
    
    # Probar todas las configuraciones
    results = []
    
    configs = [
        ('cat_binary', 'Binary (3 clases: None/AM/PM)'),
        ('cat_3', '3 categorías amplias'),
        ('cat_4', '4 categorías'),
        ('cat_5', '5 categorías'),
        ('cat_6', '6 categorías (original)'),
    ]
    
    for target, name in configs:
        result = train_with_config(train_df, val_df, test_df, target, name)
        if result:
            results.append(result)
    
    # Mostrar ranking
    print("\n" + "="*70)
    print("🏆 RANKING DE CONFIGURACIONES")
    print("="*70)
    results_sorted = sorted(results, key=lambda x: x['val_acc'], reverse=True)
    
    for i, r in enumerate(results_sorted, 1):
        marker = "🥇" if i == 1 else "🥈" if i == 2 else "🥉" if i == 3 else "  "
        print(f"{marker} #{i} {r['config']}")
        print(f"       Modelo: {r['model']}")
        print(f"       Val: {r['val_acc']:.1%} | Test: {r['test_acc']:.1%} | Train: {r['train_acc']:.1%}")
        print()
    
    # Análisis
    best = results_sorted[0]
    print("="*70)
    print("📈 ANÁLISIS")
    print("="*70)
    print(f"\nMejor configuración: {best['config']}")
    print(f"Mejor accuracy: {best['val_acc']:.1%} (validation)")
    
    if best['val_acc'] >= 0.90:
        print("\n✅ OBJETIVO ALCANZADO: 90% accuracy!")
    elif best['val_acc'] >= 0.80:
        print("\n⚠️  BUENO: 80-90% accuracy (aceptable para producción)")
    elif best['val_acc'] >= 0.70:
        print("\n⚠️  REGULAR: 70-80% accuracy (mejorable)")
    else:
        print("\n❌ BAJO: <70% accuracy (necesita más trabajo)")
    
    print(f"\n💡 Para llegar al 90% necesitas:")
    print(f"   1. Más features (clima, deadlines, eventos externos)")
    print(f"   2. Datos históricos de varios meses (patrones estacionales)")
    print(f"   3. Personalización por usuario (aprendizaje individual)")
    print(f"   4. Features temporales (mes del año, fase lunar, etc.)")
    
    # Exportar mejor dataset
    best_target = 'cat_binary' if 'Binary' in best['config'] else \
                  'cat_3' if '3 categorías' in best['config'] else \
                  'cat_4' if '4 categorías' in best['config'] else \
                  'cat_5' if '5 categorías' in best['config'] else 'cat_6'
    
    # Crear CSV con la mejor agrupación
    train_df['predicted_category'] = train_df[best_target]
    val_df['predicted_category'] = val_df[best_target]
    test_df['predicted_category'] = test_df[best_target]
    
    # Mapear a nombres legibles
    cat_names = {
        'cat_binary': {0: 'No Work', 1: 'Before Noon', 2: 'After Noon'},
        'cat_3': {0: 'No Work', 1: 'Early-Midday', 2: 'Afternoon-Evening'},
        'cat_4': {0: 'No Work', 1: 'Early-Morning', 2: 'Midday-Afternoon', 3: 'Evening'},
        'cat_5': {0: 'No Work', 1: 'Early', 2: 'Morning-Midday', 3: 'Afternoon', 4: 'Evening'},
        'cat_6': {0: 'No Work', 1: 'Early', 2: 'Morning', 3: 'Midday', 4: 'Afternoon', 5: 'Evening'}
    }
    
    train_df['category_name'] = train_df[best_target].map(cat_names.get(best_target, {}))
    
    # Guardar
    train_df.to_csv('work_schedule_best_config.csv', index=False)
    print(f"\n💾 Dataset óptimo guardado: work_schedule_best_config.csv")
    print(f"   Usa este archivo en Create ML para el mejor resultado")

if __name__ == "__main__":
    main()
