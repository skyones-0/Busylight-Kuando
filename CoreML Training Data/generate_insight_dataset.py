#!/usr/bin/env python3
"""
GENERADOR DE DATASET PARA INSIGHTS DASHBOARD
Crea datos realistas para predecir tipo de día y eficiencia
"""

import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

np.random.seed(42)
random.seed(42)

def generate_day_insight(day_of_week, is_weekend, is_holiday):
    """
    Genera un día de trabajo con características realistas
    Retorna dict con features y targets
    """
    
    # Base según día de la semana
    if is_weekend or is_holiday:
        # Fines de semana/feriados: usualmente descanso o trabajo ligero
        if random.random() < 0.7:  # 70% descanso total
            return create_rest_day(day_of_week, is_weekend, is_holiday)
        else:  # 30% trabajo ligero
            base_meetings = random.randint(0, 2)
            base_deep_work = random.randint(30, 90)
    else:
        # Días laborales
        if day_of_week == 2:  # Lunes
            base_meetings = random.randint(2, 6)
            base_deep_work = random.randint(60, 180)
        elif day_of_week == 6:  # Viernes
            base_meetings = random.randint(1, 4)
            base_deep_work = random.randint(90, 210)
        elif day_of_week in [3, 4, 5]:  # Martes-Jueves
            base_meetings = random.randint(3, 7)
            base_deep_work = random.randint(120, 300)
        else:  # Miércoles
            base_meetings = random.randint(2, 5)
            base_deep_work = random.randint(120, 240)
    
    # Generar distribución de reuniones
    total_meetings = base_meetings
    early_meetings = min(total_meetings, random.randint(0, max(1, total_meetings // 2)))
    late_meetings = min(total_meetings - early_meetings, random.randint(0, 2))
    
    # Bloques libres (9am - 6pm = 9 horas)
    available_hours = 9
    meeting_hours = total_meetings * 0.75  # Asumiendo 45min promedio
    free_hours = available_hours - meeting_hours
    free_blocks = max(1, int(free_hours / 1.5))  # Bloques de ~90 min
    
    # Reuniones back-to-back (agotador)
    back_to_back = 1 if total_meetings >= 4 and random.random() < 0.4 else 0
    
    # Deadlines
    has_deadline = 1 if random.random() < 0.25 else 0
    urgent_deadline = 1 if has_deadline and random.random() < 0.3 else 0
    
    # Eventos externos
    external_events = np.random.poisson(0.5) if not is_weekend else 0
    
    # Calls de video
    video_calls = min(total_meetings, np.random.poisson(total_meetings * 0.7))
    
    # Calcular métricas derivadas
    meeting_density = total_meetings / available_hours
    
    # Bloques para deep work (mínimo 60 minutos)
    deep_work_blocks = max(0, free_blocks - 1) if total_meetings > 3 else free_blocks
    
    # Score de interrupciones (0-100)
    interruption_score = min(100, (total_meetings * 10) + (video_calls * 5))
    
    # Estimación de deep work posible
    estimated_deep_work = deep_work_blocks * 90 if deep_work_blocks > 0 else 0
    
    # Determinar categoría y scores
    category, productivity_score, focus_score, stress_level, strategy = categorize_day(
        total_meetings=total_meetings,
        free_blocks=free_blocks,
        has_deadline=has_deadline,
        urgent_deadline=urgent_deadline,
        is_weekend=is_weekend,
        is_holiday=is_holiday,
        back_to_back=back_to_back,
        estimated_deep_work=estimated_deep_work,
        meeting_density=meeting_density
    )
    
    return {
        # Features
        'dayOfWeek': day_of_week,
        'isWeekend': is_weekend,
        'isHoliday': is_holiday,
        'totalMeetingCount': total_meetings,
        'earlyMeetingCount': early_meetings,
        'lateMeetingCount': late_meetings,
        'hasImportantDeadline': has_deadline,
        'hasUrgentDeadline': urgent_deadline,
        'backToBackMeetings': back_to_back,
        'externalEventCount': external_events,
        'videoCallCount': video_calls,
        'freeTimeBlocks': free_blocks,
        'potentialDeepWorkBlocks': deep_work_blocks,
        'meetingDensityScore': round(meeting_density * 100),  # 0-100
        'interruptionRiskScore': interruption_score,  # 0-100
        
        # Targets
        'dayCategory': category,
        'productivityScore': productivity_score,  # 0-100
        'focusScore': focus_score,  # 0-100
        'stressLevel': stress_level,  # 0-100
        'recommendedStrategy': strategy
    }

def create_rest_day(day_of_week, is_weekend, is_holiday):
    """Crea un día de descanso"""
    return {
        'dayOfWeek': day_of_week,
        'isWeekend': is_weekend,
        'isHoliday': is_holiday,
        'totalMeetingCount': 0,
        'earlyMeetingCount': 0,
        'lateMeetingCount': 0,
        'hasImportantDeadline': 0,
        'hasUrgentDeadline': 0,
        'backToBackMeetings': 0,
        'externalEventCount': 0,
        'videoCallCount': 0,
        'freeTimeBlocks': 9,
        'potentialDeepWorkBlocks': 0,
        'meetingDensityScore': 0,
        'interruptionRiskScore': 0,
        'dayCategory': 0,  # Descanso
        'productivityScore': 0,
        'focusScore': 0,
        'stressLevel': 0,
        'recommendedStrategy': 0  # Descanso total
    }

def categorize_day(total_meetings, free_blocks, has_deadline, urgent_deadline,
                   is_weekend, is_holiday, back_to_back, estimated_deep_work,
                   meeting_density):
    """
    Categoriza el día y genera scores
    Retorna: (category, productivity, focus, stress, strategy)
    """
    
    # Calcular scores base
    if is_weekend or is_holiday:
        if total_meetings == 0:
            return (0, 0, 0, 0, 0)  # Descanso
    
    # Score de productividad basado en capacidad de trabajo profundo
    productivity = min(100, estimated_deep_work / 3)
    productivity += (free_blocks * 5)
    productivity -= (total_meetings * 3)
    productivity = max(0, min(100, productivity))
    
    # Score de focus (capacidad de concentración)
    focus = 100 - (total_meetings * 8)
    focus += (free_blocks * 10)
    if back_to_back:
        focus -= 20
    focus = max(0, min(100, focus))
    
    # Nivel de estrés
    stress = (total_meetings * 5) + (has_deadline * 25) + (urgent_deadline * 30)
    if back_to_back:
        stress += 20
    stress = max(0, min(100, stress))
    
    # Determinar categoría - LÓGICA CORREGIDA Y BALANCEADA
    if total_meetings == 0 and (is_weekend or is_holiday):
        category = 0  # Descanso
    
    # Día de Foco Profundo: deadline importante + pocas reuniones + buenos bloques libres
    elif has_deadline and total_meetings <= 3 and free_blocks >= 3:
        category = 5  # 🎯 Foco Profundo
    
    # Burnout Risk: muchas reuniones + deadline urgente + back-to-back
    elif (total_meetings >= 6 and urgent_deadline) or (stress >= 80) or (total_meetings >= 8):
        category = 6  # 🚨 Burnout Risk
    
    # Intenso: muchas reuniones o back-to-back fuerte
    elif total_meetings >= 6 or back_to_back or (total_meetings >= 5 and free_blocks <= 1):
        category = 4  # 🔥 Intenso
    
    # Ocupado pero manejable: reuniones moderadas-altas pero con bloques libres
    elif total_meetings >= 4:
        category = 3  # 📅 Ocupado
    
    # Tranquilo: pocas reuniones, sin presión
    elif total_meetings <= 2 and not has_deadline:
        category = 1  # 🧘 Tranquilo
    
    # Balanceado: lo más común
    else:
        category = 2  # ⚡ Balanceado
    
    # Estrategia recomendada
    strategies = {
        0: 0,  # Descansa
        1: 1,  # Aprovecha para tareas creativas
        2: 2,  # Rutina normal
        3: 3,  # Prioriza reuniones importantes
        4: 4,  # Usa técnica Pomodoro
        5: 5,  # Bloques de foco profundo
        6: 6,  # Toma descansos obligatorios
    }
    
    strategy = strategies.get(category, 2)
    
    return (category, round(productivity), round(focus), round(stress), strategy)

def generate_dataset(n_samples=3000):
    """Genera dataset completo"""
    
    print("🚀 Generando dataset para Insights Dashboard...")
    print(f"   Muestras objetivo: {n_samples}")
    
    records = []
    
    # Distribución realista de días
    day_weights = {
        2: 0.22,  # Lunes
        3: 0.20,  # Martes
        4: 0.20,  # Miércoles
        5: 0.20,  # Jueves
        6: 0.15,  # Viernes
        7: 0.025, # Sábado
        1: 0.015  # Domingo
    }
    
    samples_per_day = {day: int(n_samples * w) for day, w in day_weights.items()}
    
    for day_of_week, n_day_samples in samples_per_day.items():
        for _ in range(n_day_samples):
            is_weekend = 1 if day_of_week in [1, 7] else 0
            is_holiday = 1 if random.random() < 0.05 else 0  # 5% feriados
            
            record = generate_day_insight(day_of_week, is_weekend, is_holiday)
            records.append(record)
    
    df = pd.DataFrame(records)
    
    # Mezclar
    df = df.sample(frac=1, random_state=42).reset_index(drop=True)
    
    return df

def main():
    print("="*80)
    print("🎯 INSIGHTS DASHBOARD - GENERADOR DE DATASET")
    print("="*80)
    
    # Generar datos
    df = generate_dataset(3000)
    
    print(f"\n📊 Dataset generado: {len(df)} registros")
    
    # Análisis de distribución
    print("\n📈 Distribución de Categorías:")
    categories = {
        0: '🌴 Descanso',
        1: '🧘 Tranquilo',
        2: '⚡ Balanceado',
        3: '📅 Ocupado',
        4: '🔥 Intenso',
        5: '🎯 Foco Profundo',
        6: '🚨 Burnout Risk'
    }
    
    for cat_id, cat_name in categories.items():
        count = (df['dayCategory'] == cat_id).sum()
        pct = count / len(df) * 100
        bar = "█" * int(pct / 2)
        print(f"   {cat_id} {cat_name:18s}: {count:4d} ({pct:5.1f}%) {bar}")
    
    # Estadísticas de scores
    print("\n📊 Estadísticas de Scores:")
    for col in ['productivityScore', 'focusScore', 'stressLevel']:
        print(f"   {col:20s}: μ={df[col].mean():.1f}, σ={df[col].std():.1f}, "
              f"min={df[col].min()}, max={df[col].max()}")
    
    # Split train/val/test
    train_size = int(0.7 * len(df))
    val_size = int(0.15 * len(df))
    
    train_df = df[:train_size]
    val_df = df[train_size:train_size + val_size]
    test_df = df[train_size + val_size:]
    
    print(f"\n💾 Dividiendo dataset:")
    print(f"   Train: {len(train_df)} ({len(train_df)/len(df)*100:.0f}%)")
    print(f"   Val:   {len(val_df)} ({len(val_df)/len(df)*100:.0f}%)")
    print(f"   Test:  {len(test_df)} ({len(test_df)/len(df)*100:.0f}%)")
    
    # Guardar
    train_df.to_csv('training_data.csv', index=False)
    val_df.to_csv('validation_data.csv', index=False)
    test_df.to_csv('testing_data.csv', index=False)
    df.to_csv('complete_dataset.csv', index=False)
    
    print(f"\n✅ Archivos generados:")
    print(f"   📄 training_data.csv ({len(train_df)} regs)")
    print(f"   📄 validation_data.csv ({len(val_df)} regs)")
    print(f"   📄 testing_data.csv ({len(test_df)} regs)")
    print(f"   📄 complete_dataset.csv ({len(df)} regs)")
    
    # Info para Create ML
    print("\n" + "="*80)
    print("📋 CONFIGURACIÓN PARA CREATE ML:")
    print("="*80)
    print(f"""
Features ({len([c for c in df.columns if c not in ['dayCategory', 'productivityScore', 'focusScore', 'stressLevel', 'recommendedStrategy']])}):
   - dayOfWeek (1-7)
   - isWeekend (0/1)
   - isHoliday (0/1)
   - totalMeetingCount (0-10)
   - earlyMeetingCount (0-5)
   - lateMeetingCount (0-3)
   - hasImportantDeadline (0/1)
   - hasUrgentDeadline (0/1)
   - backToBackMeetings (0/1)
   - externalEventCount (0-3)
   - videoCallCount (0-10)
   - freeTimeBlocks (0-9)
   - potentialDeepWorkBlocks (0-6)
   - meetingDensityScore (0-100)
   - interruptionRiskScore (0-100)

Targets para entrenar modelos separados:
   1. dayCategory (0-6) - Clasificación
   2. productivityScore (0-100) - Regresión
   3. focusScore (0-100) - Regresión
   4. stressLevel (0-100) - Regresión
   5. recommendedStrategy (0-6) - Clasificación
""")

if __name__ == "__main__":
    main()
