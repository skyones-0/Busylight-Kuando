#!/usr/bin/env python3
"""
Script V9 - Dataset REALISTA con granularidad fina

Características:
1. Usuario configura hora base (ej: 9:00 am)
2. Variación realista: ±1h en 80% de casos, ±2h en 20%
3. Campos adicionales: refrigerio, reuniones, deadlines, etc.
4. WorkDuration calculado automáticamente
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

np.random.seed(42)
random.seed(42)

# ============================================================================
# CONFIGURACIÓN DEL USUARIO TIPO
# ============================================================================

USER_CONFIG = {
    'baseStartHour': 9,        # Hora base de entrada: 9:00 am
    'baseEndHour': 18,         # Hora base de salida: 6:00 pm (9h trabajo)
    'typicalWorkDuration': 8,  # Horas efectivas de trabajo
    'lunchDuration': 1,        # Duración refrigerio
    'varianceProbability': {   # Probabilidad de variación
        -2: 0.05,  # 5% llega 2h antes
        -1: 0.20,  # 20% llega 1h antes
         0: 0.50,  # 50% llega a hora
        +1: 0.20,  # 20% llega 1h después
        +2: 0.05   # 5% llega 2h después
    }
}

# ============================================================================
# GENERADOR DE DATOS REALISTAS
# ============================================================================

def generate_realistic_schedule(day_of_week, is_weekend, is_holiday, user_config):
    """
    Genera un horario realista basado en configuración del usuario
    """
    base = user_config['baseStartHour']
    
    # Si es fin de semana o feriado: probable no trabajo
    if is_weekend or is_holiday:
        if random.random() < 0.7:  # 70% no trabaja
            return {
                'startHour': 0,
                'endHour': 0,
                'workDuration': 0,
                'lunchStart': 0,
                'lunchEnd': 0,
                'offsetFromBase': None,
                'hasLunch': False
            }
    
    # Determinar offset basado en probabilidades
    offsets = list(user_config['varianceProbability'].keys())
    probabilities = list(user_config['varianceProbability'].values())
    
    # Ajustar probabilidades según día de la semana
    if day_of_week == 2:  # Lunes: más probabilidad de llegar tarde
        probabilities = [0.03, 0.15, 0.40, 0.30, 0.12]
    elif day_of_week == 6:  # Viernes: más probabilidad de salir temprano
        probabilities = [0.10, 0.30, 0.35, 0.20, 0.05]
    elif is_weekend:  # Fin de semana: horario irregular
        probabilities = [0.15, 0.25, 0.30, 0.20, 0.10]
    
    offset = np.random.choice(offsets, p=probabilities)
    
    # Calcular hora de inicio
    start_hour = base + offset
    start_hour = max(6, min(20, start_hour))  # Entre 6am y 8pm
    
    # Calcular duración (con pequeña variación)
    duration_variation = np.random.choice([-1, 0, 0, 0, 1])  # Mayoría sin cambio
    work_duration = user_config['typicalWorkDuration'] + duration_variation
    work_duration = max(4, min(10, work_duration))
    
    # Calcular hora de fin
    end_hour = start_hour + work_duration + user_config['lunchDuration']
    end_hour = min(23, end_hour)
    
    # Refrigerio: típicamente 1-2pm o 2-3pm según hora de entrada
    if start_hour <= 11:
        lunch_start = 13  # 1pm
    elif start_hour <= 13:
        lunch_start = 14  # 2pm
    else:
        lunch_start = 15  # 3pm
    
    lunch_end = lunch_start + user_config['lunchDuration']
    
    return {
        'startHour': start_hour,
        'endHour': end_hour,
        'workDuration': work_duration,
        'lunchStart': lunch_start,
        'lunchEnd': lunch_end,
        'offsetFromBase': offset,
        'hasLunch': True
    }

def generate_calendar_features(day_of_week, is_weekend, is_holiday, schedule):
    """
    Genera features de calendario contextuales
    """
    features = {}
    
    # Reuniones según día y hora de entrada
    if is_weekend or is_holiday or schedule['startHour'] == 0:
        features['earlyMeetingCount'] = 0
        features['totalMeetingCount'] = 0
        features['hasImportantDeadline'] = 0
    else:
        # Más reuniones los días con entrada temprana
        base_meetings = np.random.poisson(3)  # Promedio 3 reuniones
        if schedule['offsetFromBase'] and schedule['offsetFromBase'] < 0:
            base_meetings += np.random.poisson(2)  # Más reuniones si llega temprano
        
        features['earlyMeetingCount'] = np.random.poisson(1) if schedule['startHour'] <= 9 else 0
        features['totalMeetingCount'] = min(8, base_meetings)
        
        # Deadlines: más comunes a fin de mes (simulado)
        features['hasImportantDeadline'] = 1 if random.random() < 0.15 else 0
    
    # Eventos externos
    features['externalEventCount'] = np.random.poisson(0.5) if not is_weekend else np.random.poisson(1)
    
    # Calls de video
    features['videoCallCount'] = np.random.poisson(2) if not is_weekend else 0
    
    return features

def generate_work_features(schedule, calendar_features):
    """
    Genera features de trabajo basados en el horario
    """
    if schedule['startHour'] == 0:
        # No trabaja
        return {
            'sessionCount': 0,
            'deepWorkMinutes': 0,
            'shallowWorkMinutes': 0,
            'breakCount': 0,
            'productivityScore': 0,
            'emailCount': 0,
            'taskCompleted': 0
        }
    
    # Calcular minutos disponibles para trabajo
    available_minutes = schedule['workDuration'] * 60
    
    # Deep work: bloques de concentración (mayor si entrada temprana)
    if schedule['offsetFromBase'] and schedule['offsetFromBase'] <= -1:
        deep_work_ratio = np.random.uniform(0.4, 0.6)  # 40-60% deep work si madruga
    else:
        deep_work_ratio = np.random.uniform(0.2, 0.4)  # 20-40% normal
    
    deep_work_minutes = int(available_minutes * deep_work_ratio)
    
    # Sessions de trabajo (bloques de 45-90 min)
    avg_session = np.random.randint(45, 91)
    session_count = max(1, deep_work_minutes // avg_session)
    
    # Shallow work (emails, slack, etc.)
    shallow_work_minutes = int(available_minutes * np.random.uniform(0.2, 0.3))
    
    # Emails según tipo de día
    email_count = np.random.poisson(20) if schedule['workDuration'] > 0 else 0
    
    # Tareas completadas correlacionadas con deep work
    task_completed = int(deep_work_minutes / 45) + np.random.poisson(2)
    
    # Breaks (cada 90 min aprox)
    break_count = max(1, available_minutes // 90)
    
    # Productividad score (0-100)
    productivity = min(100, int(
        (deep_work_minutes / 240) * 50 +  # Base en deep work (4h = 50 pts)
        (task_completed * 5) +  # +5 por tarea
        np.random.randint(-10, 11)  # Ruido
    ))
    
    return {
        'sessionCount': session_count,
        'deepWorkMinutes': deep_work_minutes,
        'shallowWorkMinutes': shallow_work_minutes,
        'breakCount': break_count,
        'productivityScore': productivity,
        'emailCount': email_count,
        'taskCompleted': task_completed
    }

def generate_environmental_features(day_of_week, is_weekend, schedule):
    """
    Features ambientales/contextuales
    """
    features = {}
    
    # Dormir: si trabaja mucho un día, al día siguiente puede llegar tarde
    # (esto creará correlación temporal útil)
    features['sleepQuality'] = np.random.randint(3, 9) if not is_weekend else np.random.randint(5, 10)
    
    # Tráfico (afecta hora de llegada)
    if schedule['startHour'] > 0 and schedule['startHour'] <= 9:
        features['commuteDuration'] = np.random.randint(20, 46)  # Tráfico mañana
    else:
        features['commuteDuration'] = np.random.randint(15, 31)
    
    # Clima (afecta motivación)
    features['weatherGood'] = 1 if random.random() < 0.7 else 0
    
    # Energía personal (correlacionado con hora de entrada)
    if schedule['offsetFromBase'] and schedule['offsetFromBase'] < 0:
        features['energyLevel'] = np.random.randint(7, 10)  # Madrugar = más energía
    else:
        features['energyLevel'] = np.random.randint(4, 9)
    
    return features

# ============================================================================
# GENERAR DATASET COMPLETO
# ============================================================================

def generate_dataset(n_samples=2000, user_config=USER_CONFIG):
    """Genera dataset completo"""
    
    records = []
    
    # Distribuir muestras entre días de la semana
    days_distribution = {
        2: 0.20,  # Lunes: 20%
        3: 0.18,  # Martes: 18%
        4: 0.18,  # Miércoles: 18%
        5: 0.18,  # Jueves: 18%
        6: 0.16,  # Viernes: 16%
        7: 0.06,  # Sábado: 6%
        1: 0.04   # Domingo: 4%
    }
    
    samples_per_day = {day: int(n_samples * pct) for day, pct in days_distribution.items()}
    
    for day_of_week, n_day_samples in samples_per_day.items():
        for _ in range(n_day_samples):
            # Determinar si es fin de semana o feriado
            is_weekend = 1 if day_of_week in [1, 7] else 0
            is_holiday = 1 if random.random() < 0.05 else 0  # 5% feriados
            
            # Generar horario
            schedule = generate_realistic_schedule(day_of_week, is_weekend, is_holiday, user_config)
            
            # Generar features
            calendar = generate_calendar_features(day_of_week, is_weekend, is_holiday, schedule)
            work = generate_work_features(schedule, calendar)
            environmental = generate_environmental_features(day_of_week, is_weekend, schedule)
            
            # Combinar todo
            record = {
                # Identificación
                'dayOfWeek': day_of_week,
                'isWeekend': is_weekend,
                'isHoliday': is_holiday,
                
                # Horario principal (TARGETS)
                'startHour': schedule['startHour'],
                'endHour': schedule['endHour'],
                'workDuration': schedule['workDuration'],
                'offsetFromBase': schedule['offsetFromBase'] if schedule['offsetFromBase'] is not None else 0,
                
                # Refrigerio
                'lunchStart': schedule['lunchStart'],
                'lunchEnd': schedule['lunchEnd'],
                'hasLunch': 1 if schedule['hasLunch'] else 0,
                
                # Calendario
                'earlyMeetingCount': calendar['earlyMeetingCount'],
                'totalMeetingCount': calendar['totalMeetingCount'],
                'hasImportantDeadline': calendar['hasImportantDeadline'],
                'externalEventCount': calendar['externalEventCount'],
                'videoCallCount': calendar['videoCallCount'],
                
                # Trabajo
                'sessionCount': work['sessionCount'],
                'deepWorkMinutes': work['deepWorkMinutes'],
                'shallowWorkMinutes': work['shallowWorkMinutes'],
                'breakCount': work['breakCount'],
                'productivityScore': work['productivityScore'],
                'emailCount': work['emailCount'],
                'taskCompleted': work['taskCompleted'],
                
                # Ambientales
                'sleepQuality': environmental['sleepQuality'],
                'commuteDuration': environmental['commuteDuration'],
                'weatherGood': environmental['weatherGood'],
                'energyLevel': environmental['energyLevel'],
                
                # Configuración base (para referencia)
                'userBaseHour': user_config['baseStartHour'],
            }
            
            records.append(record)
    
    return pd.DataFrame(records)

def main():
    print("="*80)
    print("🚀 GENERADOR V9 - DATASET REALISTA CON GRANULARIDAD FINA")
    print("="*80)
    
    print(f"\n⚙️  Configuración del usuario:")
    print(f"   Hora base: {USER_CONFIG['baseStartHour']}:00")
    print(f"   Duración típica: {USER_CONFIG['typicalWorkDuration']}h")
    print(f"   Refrigerio: {USER_CONFIG['lunchDuration']}h")
    print(f"   Variación: ±1h (80% de casos), ±2h (20%)")
    
    # Generar datasets
    print("\n📊 Generando datasets...")
    
    full_df = generate_dataset(2000, USER_CONFIG)
    
    # Dividir en train/val/test
    train_df = full_df.sample(n=1400, random_state=42)
    remaining = full_df.drop(train_df.index)
    val_df = remaining.sample(n=300, random_state=42)
    test_df = remaining.drop(val_df.index).sample(n=300, random_state=42)
    
    print(f"   Total: {len(full_df)} registros")
    print(f"   Train: {len(train_df)}, Val: {len(val_df)}, Test: {len(test_df)}")
    
    # Análisis de distribución de startHour
    print(f"\n📈 Distribución de horas de inicio:")
    start_dist = full_df[full_df['startHour'] > 0]['startHour'].value_counts().sort_index()
    for hour, count in start_dist.items():
        bar = "█" * (count // 5)
        print(f"   {hour:2d}:00 - {count:3d} ({count/len(full_df)*100:4.1f}%) {bar}")
    
    # Análisis de offset
    print(f"\n📈 Distribución de OFFSET desde hora base ({USER_CONFIG['baseStartHour']}:00):")
    offset_dist = full_df[full_df['offsetFromBase'] != 0]['offsetFromBase'].value_counts().sort_index()
    for offset, count in offset_dist.items():
        sign = "+" if offset > 0 else ""
        print(f"   {sign}{offset:2d}h: {count:4d} registros ({count/len(full_df)*100:5.1f}%)")
    
    # Guardar datasets
    print(f"\n💾 Guardando datasets...")
    
    train_df.to_csv('work_schedule_v9_training.csv', index=False)
    val_df.to_csv('work_schedule_v9_validation.csv', index=False)
    test_df.to_csv('work_schedule_v9_testing.csv', index=False)
    full_df.to_csv('work_schedule_v9_full.csv', index=False)
    
    print(f"   ✅ work_schedule_v9_training.csv ({len(train_df)} registros)")
    print(f"   ✅ work_schedule_v9_validation.csv ({len(val_df)} registros)")
    print(f"   ✅ work_schedule_v9_testing.csv ({len(test_df)} registros)")
    print(f"   ✅ work_schedule_v9_full.csv ({len(full_df)} registros)")
    
    # Estadísticas de features
    print(f"\n📊 Estadísticas de features clave:")
    print(f"   Variables totales: {len(full_df.columns)}")
    print(f"   Features: {len(full_df.columns) - 5} (excluyendo targets)")
    print(f"   Deep Work promedio: {full_df['deepWorkMinutes'].mean():.0f} min")
    print(f"   Session Count promedio: {full_df['sessionCount'].mean():.1f}")
    print(f"   Reuniones promedio: {full_df['totalMeetingCount'].mean():.1f}")
    print(f"   Días sin trabajo: {(full_df['startHour'] == 0).sum()} ({(full_df['startHour'] == 0).mean()*100:.1f}%)")
    
    print("\n" + "="*80)
    print("✅ DATASET V9 GENERADO EXITOSAMENTE")
    print("="*80)
    print("""
Características:
   ✅ Horario basado en hora base del usuario (9:00 am)
   ✅ Variación realista: ±1h en 80% de casos
   ✅ Campos de refrigerio (lunchStart, lunchEnd)
   ✅ Features de calendario (reuniones, deadlines)
   ✅ Features de trabajo (sessions, deep work, tareas)
   ✅ Features ambientales (sueño, tráfico, clima, energía)
   
Targets para ML:
   - startHour: 0 (no work), 7-11 (variación alrededor de 9)
   - offsetFromBase: -2, -1, 0, +1, +2 (5 clases principales)
   - endHour: calculado automáticamente
    """)

if __name__ == "__main__":
    main()
