#!/usr/bin/env python3
"""
GENERADOR BALANCEADO - Dataset validado para Create ML
Crea datos distribuidos uniformemente para mejor entrenamiento
"""

import pandas as pd
import numpy as np
import random

np.random.seed(42)
random.seed(42)

# Categorías balanceadas - distribución objetivo
categories = {
    0: {'name': 'Rest', 'emoji': '🌴', 'target_pct': 0.10},        # 10% descanso
    1: {'name': 'Calm', 'emoji': '🧘', 'target_pct': 0.15},        # 15% tranquilo
    2: {'name': 'Balanced', 'emoji': '⚡', 'target_pct': 0.25},     # 25% balanceado
    3: {'name': 'Busy', 'emoji': '📅', 'target_pct': 0.20},        # 20% ocupado
    4: {'name': 'Intense', 'emoji': '🔥', 'target_pct': 0.20},     # 20% intenso
    5: {'name': 'DeepFocus', 'emoji': '🎯', 'target_pct': 0.08},   # 8% foco profundo
    6: {'name': 'BurnoutRisk', 'emoji': '🚨', 'target_pct': 0.02}, # 2% burnout (alerta rara)
}

def generate_for_category(category_id, n_samples):
    """Genera muestras específicas para cada categoría"""
    
    samples = []
    
    for _ in range(n_samples):
        # Día de la semana (1-7, más probabilidad de días laborales)
        day_of_week = np.random.choice([1,2,3,4,5,6,7], p=[0.05, 0.20, 0.20, 0.20, 0.20, 0.10, 0.05])
        is_weekend = 1 if day_of_week in [1, 7] else 0
        is_holiday = 1 if random.random() < 0.03 else 0
        
        # Generar features según categoría
        if category_id == 0:  # Rest
            total_meetings = 0
            has_deadline = 0
            back_to_back = 0
            free_blocks = 9
            meeting_density = 0
            interruption = 0
            
        elif category_id == 1:  # Calm
            total_meetings = random.randint(1, 2)
            has_deadline = np.random.choice([0, 1], p=[0.8, 0.2])
            back_to_back = 0
            free_blocks = random.randint(5, 8)
            meeting_density = random.randint(10, 25)
            interruption = random.randint(10, 30)
            
        elif category_id == 2:  # Balanced
            total_meetings = random.randint(3, 4)
            has_deadline = np.random.choice([0, 1], p=[0.7, 0.3])
            back_to_back = np.random.choice([0, 1], p=[0.7, 0.3])
            free_blocks = random.randint(3, 6)
            meeting_density = random.randint(30, 50)
            interruption = random.randint(30, 50)
            
        elif category_id == 3:  # Busy
            total_meetings = random.randint(5, 6)
            has_deadline = np.random.choice([0, 1], p=[0.5, 0.5])
            back_to_back = np.random.choice([0, 1], p=[0.5, 0.5])
            free_blocks = random.randint(2, 4)
            meeting_density = random.randint(50, 70)
            interruption = random.randint(50, 75)
            
        elif category_id == 4:  # Intense
            total_meetings = random.randint(6, 8)
            has_deadline = np.random.choice([0, 1], p=[0.4, 0.6])
            back_to_back = np.random.choice([0, 1], p=[0.4, 0.6])
            free_blocks = random.randint(1, 3)
            meeting_density = random.randint(65, 85)
            interruption = random.randint(70, 90)
            
        elif category_id == 5:  # DeepFocus
            total_meetings = random.randint(2, 3)
            has_deadline = 1  # Siempre tiene deadline
            back_to_back = 0
            free_blocks = random.randint(4, 6)  # Bloques para foco
            meeting_density = random.randint(20, 40)
            interruption = random.randint(20, 40)
            
        elif category_id == 6:  # BurnoutRisk
            total_meetings = random.randint(7, 10)
            has_deadline = 1  # Deadline urgente
            back_to_back = 1  # Siempre seguidas
            free_blocks = random.randint(0, 2)  # Casi sin tiempo libre
            meeting_density = random.randint(80, 100)
            interruption = random.randint(85, 100)
        
        sample = {
            'dayOfWeek': day_of_week,
            'isWeekend': is_weekend,
            'isHoliday': is_holiday,
            'totalMeetingCount': total_meetings,
            'hasImportantDeadline': has_deadline,
            'backToBackMeetings': back_to_back,
            'freeTimeBlocks': free_blocks,
            'meetingDensityScore': meeting_density,
            'interruptionRiskScore': interruption,
            'dayCategory': category_id
        }
        
        samples.append(sample)
    
    return samples

def main():
    print("="*80)
    print("🎯 GENERADOR BALANCEADO PARA CREATE ML")
    print("="*80)
    
    n_total = 2500  # Total de muestras
    
    all_samples = []
    
    print("\nGenerando muestras por categoría:")
    for cat_id, info in categories.items():
        n_samples = int(n_total * info['target_pct'])
        samples = generate_for_category(cat_id, n_samples)
        all_samples.extend(samples)
        print(f"  {info['emoji']} {info['name']:12s}: {n_samples:4d} ({info['target_pct']:.0%})")
    
    # Crear DataFrame
    df = pd.DataFrame(all_samples)
    
    # Mezclar
    df = df.sample(frac=1, random_state=42).reset_index(drop=True)
    
    print(f"\n📊 Total: {len(df)} muestras")
    
    # Verificar distribución real
    print("\nDistribución real:")
    for cat_id, info in categories.items():
        count = (df['dayCategory'] == cat_id).sum()
        pct = count / len(df) * 100
        print(f"  {info['emoji']} {info['name']:12s}: {count:4d} ({pct:5.1f}%)")
    
    # Split
    train_size = int(0.7 * len(df))
    val_size = int(0.15 * len(df))
    
    train = df[:train_size]
    val = df[train_size:train_size + val_size]
    test = df[train_size + val_size:]
    
    # Guardar
    train.to_csv('TRAINING.csv', index=False)
    val.to_csv('VALIDATION.csv', index=False)
    test.to_csv('TESTING.csv', index=False)
    df.to_csv('COMPLETE.csv', index=False)
    
    print(f"\n💾 Datasets guardados:")
    print(f"  TRAINING.csv   : {len(train)} muestras")
    print(f"  VALIDATION.csv : {len(val)} muestras")
    print(f"  TESTING.csv    : {len(test)} muestras")
    
    # Validar que todo son enteros
    print(f"\n✅ Validación:")
    print(f"  Tipos: {df.dtypes.unique()}")
    print(f"  Valores nulos: {df.isnull().sum().sum()}")
    
    print(f"\n" + "="*80)
    print("📋 RESUMEN PARA CREATE ML")
    print("="*80)
    print(f"""
Archivo a usar: TRAINING.csv

Features (8 enteros):
  - dayOfWeek (1-7)
  - isWeekend (0/1)
  - isHoliday (0/1)
  - totalMeetingCount (0-10)
  - hasImportantDeadline (0/1)
  - backToBackMeetings (0/1)
  - freeTimeBlocks (0-9)
  - meetingDensityScore (0-100)
  - interruptionRiskScore (0-100)

Target: dayCategory (0-6)
  0=Rest, 1=Calm, 2=Balanced, 3=Busy, 4=Intense, 5=DeepFocus, 6=BurnoutRisk

Configuración Create ML:
  - Tipo: Tabular Classification
  - Algoritmo: Boosted Trees
  - Target type: Integer (Categorical)
""")

if __name__ == "__main__":
    main()
