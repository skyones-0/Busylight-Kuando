#!/usr/bin/env python3
"""
Generador de datos de entrenamiento para Busylight ML
Crea datasets realistas para entrenar Random Forest
"""

import csv
import random
from datetime import datetime, timedelta

def generate_realistic_schedule(day_of_week, is_weekend, is_holiday, session_count, deep_work_minutes, calendar_events):
    """
    Genera horarios realistas basados en patrones de trabajo
    """
    # Base: Días laborables vs fines de semana/festivos
    if is_holiday == 1:
        # Festivo: Probabilidad alta de no trabajar
        if random.random() < 0.7:
            return 0, 0  # No trabaja
        else:
            # Trabajo ligero
            start_hour = random.choice([9, 10, 11])
            end_hour = start_hour + random.randint(2, 4)
            return start_hour, end_hour
    
    if is_weekend == 1:
        # Fin de semana: Variable
        if session_count == 0 and deep_work_minutes == 0:
            return 0, 0  # Descanso total
        elif session_count <= 2:
            # Trabajo ligero de fin de semana
            start_hour = random.choice([9, 10, 11, 14])
            end_hour = start_hour + random.randint(2, 5)
            return start_hour, min(end_hour, 20)
        else:
            # Fin de semana productivo
            start_hour = random.choice([8, 9, 10])
            end_hour = start_hour + random.randint(4, 8)
            return start_hour, min(end_hour, 21)
    
    # Día laborable
    if session_count == 0 and deep_work_minutes == 0:
        # Día sin trabajo (vacaciones, baja, etc.)
        if random.random() < 0.3:
            return 0, 0
    
    # Patrones según intensidad de trabajo
    if deep_work_minutes >= 240:  # 4+ horas deep work
        # Día muy productivo: Temprano y largo
        base_start = random.choice([6, 7, 8])
        work_duration = random.randint(8, 10)
    elif deep_work_minutes >= 120:  # 2-4 horas
        # Día productivo normal
        base_start = random.choice([7, 8, 9])
        work_duration = random.randint(7, 9)
    elif session_count >= 6:
        # Muchas sesiones: Día ocupado
        base_start = random.choice([7, 8, 9, 10])
        work_duration = random.randint(6, 9)
    elif session_count >= 3:
        # Día moderado
        base_start = random.choice([8, 9, 10])
        work_duration = random.randint(6, 8)
    else:
        # Día ligero
        base_start = random.choice([9, 10, 11])
        work_duration = random.randint(4, 6)
    
    # Ajuste por día de la semana
    if day_of_week == 2:  # Lunes
        base_start += random.choice([0, 1])  # Puede empezar más tarde
    elif day_of_week == 6:  # Viernes
        work_duration -= random.choice([0, 1])  # Puede terminar más temprano
    
    # Eventos de calendario afectan horario
    if calendar_events >= 5:
        work_duration += 1  # Días con muchas reuniones son más largos
    
    start_hour = max(5, min(base_start, 12))  # Entre 5am y 12pm
    end_hour = min(start_hour + work_duration, 23)  # Máximo 11pm
    
    return start_hour, end_hour

def generate_dataset(num_records=1200):
    """Genera dataset completo"""
    
    records = []
    
    for i in range(num_records):
        # Día de la semana (1=Lunes, 7=Domingo)
        day_of_week = random.randint(1, 7)
        
        # Es fin de semana
        is_weekend = 1 if day_of_week in [1, 7] else 0
        
        # Es festivo (aprox 15% de probabilidad)
        is_holiday = 1 if random.random() < 0.15 else 0
        
        # Número de sesiones (distribución realista)
        if is_weekend or is_holiday:
            session_count = random.choices(
                [0, 1, 2, 3, 4, 5, 6, 7, 8],
                weights=[30, 25, 20, 10, 7, 5, 2, 0.5, 0.5]
            )[0]
        else:
            session_count = random.choices(
                [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
                weights=[3, 5, 8, 10, 12, 15, 15, 12, 10, 5, 3, 1, 1]
            )[0]
        
        # Minutos de deep work (correlacionado con sesiones)
        if session_count == 0:
            deep_work_minutes = 0
        else:
            # Deep work típico: 30-480 minutos
            base_deep_work = session_count * random.randint(20, 60)
            deep_work_minutes = min(base_deep_work + random.randint(-30, 60), 480)
            deep_work_minutes = max(0, deep_work_minutes)
        
        # Eventos de calendario
        if is_holiday:
            calendar_events = random.choices([0, 1, 2], weights=[70, 25, 5])[0]
        elif is_weekend:
            calendar_events = random.choices([0, 1, 2, 3], weights=[50, 30, 15, 5])[0]
        else:
            calendar_events = random.choices(
                [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
                weights=[5, 8, 12, 15, 18, 15, 12, 8, 4, 2, 1]
            )[0]
        
        # Generar horarios realistas
        start_hour, end_hour = generate_realistic_schedule(
            day_of_week, is_weekend, is_holiday,
            session_count, deep_work_minutes, calendar_events
        )
        
        records.append({
            'dayOfWeek': day_of_week,
            'isWeekend': is_weekend,
            'isHoliday': is_holiday,
            'sessionCount': session_count,
            'deepWorkMinutes': deep_work_minutes,
            'calendarEventCount': calendar_events,
            'startHour': start_hour,
            'endHour': end_hour
        })
    
    return records

def save_to_csv(records, filename):
    """Guarda registros en CSV"""
    fieldnames = ['dayOfWeek', 'isWeekend', 'isHoliday', 'sessionCount', 
                  'deepWorkMinutes', 'calendarEventCount', 'startHour', 'endHour']
    
    with open(filename, 'w', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(records)
    
    print(f"✅ Generated {len(records)} records → {filename}")

def generate_testing_data(num_records=200):
    """Genera datos de prueba con casos edge"""
    records = []
    
    # Casos específicos para testing
    edge_cases = [
        # (dayOfWeek, isWeekend, isHoliday, sessionCount, deepWorkMinutes, calendarEventCount, startHour, endHour, description)
        (2, 0, 0, 8, 240, 5, 8, 17, "Día productivo lunes"),
        (7, 1, 0, 0, 0, 0, 0, 0, "Domingo descanso"),
        (2, 0, 1, 0, 0, 0, 0, 0, "Lunes festivo"),
        (2, 0, 0, 12, 480, 10, 6, 20, "Día muy productivo"),
        (6, 0, 0, 0, 0, 0, 0, 0, "Viernes sin trabajo"),
        (3, 0, 0, 3, 60, 2, 10, 14, "Medio día martes"),
        (1, 0, 0, 2, 30, 1, 14, 17, "Tarde de domingo"),
    ]
    
    for case in edge_cases:
        records.append({
            'dayOfWeek': case[0],
            'isWeekend': case[1],
            'isHoliday': case[2],
            'sessionCount': case[3],
            'deepWorkMinutes': case[4],
            'calendarEventCount': case[5],
            'startHour': case[6],
            'endHour': case[7]
        })
    
    # Completar con datos aleatorios
    remaining = num_records - len(records)
    random_records = generate_dataset(remaining)
    records.extend(random_records)
    
    return records

if __name__ == "__main__":
    print("🚀 Generating Busylight ML Training Datasets...")
    print()
    
    # Dataset principal: 1200 registros
    print("📊 Generating main training dataset...")
    training_data = generate_dataset(1200)
    save_to_csv(training_data, 'work_schedule_training_data.csv')
    
    # Dataset de testing: 200 registros
    print("🧪 Generating testing dataset...")
    testing_data = generate_testing_data(200)
    save_to_csv(testing_data, 'testing_data.csv')
    
    # Dataset con más festivos para validación
    print(" holiday calendar validation dataset...")
    holiday_data = generate_dataset(300)
    # Modificar para tener más variedad de festivos
    for record in holiday_data[:100]:
        record['isHoliday'] = 1
        record['sessionCount'] = random.randint(0, 3)
        record['deepWorkMinutes'] = random.randint(0, 120)
        record['calendarEventCount'] = random.randint(0, 2)
        # Recalcular horarios
        start_hour, end_hour = generate_realistic_schedule(
            record['dayOfWeek'], record['isWeekend'], 1,
            record['sessionCount'], record['deepWorkMinutes'], 
            record['calendarEventCount']
        )
        record['startHour'] = start_hour
        record['endHour'] = end_hour
    
    save_to_csv(holiday_data, 'work_schedule_with_holidays.csv')
    
    print()
    print("✨ All datasets generated successfully!")
    print(f"   - Training: {len(training_data)} records")
    print(f"   - Testing: {len(testing_data)} records")
    print(f"   - Holiday validation: {len(holiday_data)} records")
    print(f"   Total: {len(training_data) + len(testing_data) + len(holiday_data)} records")
