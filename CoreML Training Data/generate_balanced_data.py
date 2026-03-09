#!/usr/bin/env python3
"""
Generador de datos BALANCEADOS para Busylight ML
Cada clase (hora 0-20) tendrá aproximadamente el mismo número de ejemplos
"""

import csv
import random

def generate_for_hour(target_hour, is_end_hour=False):
    """
    Genera features realistas que resulten en la hora objetivo
    """
    records = []
    
    # Si es hora 0 (no trabaja)
    if target_hour == 0:
        for _ in range(100):
            day_of_week = random.randint(1, 7)
            is_weekend = 1 if day_of_week in [1, 7] else 0
            is_holiday = random.choice([0, 1]) if random.random() < 0.3 else 0
            
            # Sin trabajo
            session_count = 0
            deep_work_minutes = 0
            calendar_events = random.randint(0, 1) if is_holiday else 0
            
            records.append({
                'dayOfWeek': day_of_week,
                'isWeekend': is_weekend,
                'isHoliday': is_holiday,
                'sessionCount': session_count,
                'deepWorkMinutes': deep_work_minutes,
                'calendarEventCount': calendar_events,
                'startHour': 0,
                'endHour': 0
            })
        return records
    
    # Para horas de trabajo (1-20)
    for _ in range(100):  # 100 ejemplos por hora
        day_of_week = random.randint(2, 6)  # Lunes a viernes principalmente
        is_weekend = 0
        
        # Festivo ocasional
        is_holiday = 1 if random.random() < 0.05 else 0
        
        # Determinar intensidad según la hora
        if target_hour <= 7:  # Muy temprano (6-7am)
            # Alta productividad
            session_count = random.randint(7, 12)
            deep_work_minutes = random.randint(240, 480)
            calendar_events = random.randint(3, 8)
        elif target_hour <= 9:  # Temprano (8-9am)
            # Productividad normal-alta
            session_count = random.randint(5, 9)
            deep_work_minutes = random.randint(180, 360)
            calendar_events = random.randint(2, 6)
        elif target_hour <= 11:  # Normal (10-11am)
            # Productividad normal
            session_count = random.randint(4, 7)
            deep_work_minutes = random.randint(120, 300)
            calendar_events = random.randint(2, 5)
        elif target_hour <= 14:  # Medio día (12-2pm)
            # Variable (puede ser tarde o medio día)
            session_count = random.randint(3, 6)
            deep_work_minutes = random.randint(60, 240)
            calendar_events = random.randint(1, 4)
        else:  # Tarde (15-20)
            # Trabajo tardío o parcial
            session_count = random.randint(2, 5)
            deep_work_minutes = random.randint(30, 180)
            calendar_events = random.randint(0, 3)
        
        # Para endHour, asegurar que sea >= startHour
        if is_end_hour:
            start_hour = random.randint(1, target_hour)
            end_hour = target_hour
        else:
            start_hour = target_hour
            # Duración del trabajo (4-10 horas típicas)
            duration = random.randint(4, 10)
            end_hour = min(start_hour + duration, 23)
        
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

def generate_balanced_dataset():
    """Genera dataset con distribución balanceada por hora"""
    
    all_records = []
    
    # Generar para cada hora de inicio (0-20)
    print("🔄 Generando datos balanceados para StartHour...")
    for hour in range(0, 21):  # 0-20
        records = generate_for_hour(hour, is_end_hour=False)
        all_records.extend(records)
        print(f"   Hour {hour}: {len(records)} records")
    
    # Mezclar aleatoriamente
    random.shuffle(all_records)
    
    return all_records

def split_dataset(records, train_ratio=0.7, val_ratio=0.15):
    """Divide en train/val/test manteniendo balance"""
    
    # Agrupar por startHour
    by_hour = {h: [] for h in range(0, 21)}
    for r in records:
        by_hour[r['startHour']].append(r)
    
    train_records = []
    val_records = []
    test_records = []
    
    for hour, hour_records in by_hour.items():
        random.shuffle(hour_records)
        
        n = len(hour_records)
        n_train = int(n * train_ratio)
        n_val = int(n * val_ratio)
        
        train_records.extend(hour_records[:n_train])
        val_records.extend(hour_records[n_train:n_train + n_val])
        test_records.extend(hour_records[n_train + n_val:])
    
    # Mezclar
    random.shuffle(train_records)
    random.shuffle(val_records)
    random.shuffle(test_records)
    
    return train_records, val_records, test_records

def save_to_csv(records, filename):
    """Guarda en CSV"""
    fieldnames = ['dayOfWeek', 'isWeekend', 'isHoliday', 'sessionCount', 
                  'deepWorkMinutes', 'calendarEventCount', 'startHour', 'endHour']
    
    with open(filename, 'w', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(records)
    
    print(f"✅ Saved {len(records)} records → {filename}")

def print_distribution(records, name):
    """Muestra distribución por clase"""
    counts = {}
    for r in records:
        h = r['startHour']
        counts[h] = counts.get(h, 0) + 1
    
    print(f"\n📊 Distribution for {name}:")
    for h in sorted(counts.keys()):
        print(f"   Hour {h:2d}: {counts[h]:3d} examples")

if __name__ == "__main__":
    print("🚀 Generating BALANCED Dataset for Busylight ML")
    print("=" * 60)
    
    # Generar dataset balanceado
    all_data = generate_balanced_dataset()
    print(f"\n📦 Total records: {len(all_data)}")
    
    # Mostrar distribución
    print_distribution(all_data, "All Data")
    
    # Split estratificado
    print("\n✂️ Splitting into Train/Val/Test...")
    train_data, val_data, test_data = split_dataset(all_data)
    
    # Guardar
    save_to_csv(train_data, 'work_schedule_training_data.csv')
    save_to_csv(val_data, 'work_schedule_validation.csv')
    save_to_csv(test_data, 'testing_data.csv')
    
    # Verificar distribuciones
    print_distribution(train_data, "Training")
    print_distribution(val_data, "Validation")
    print_distribution(test_data, "Testing")
    
    print("\n" + "=" * 60)
    print("✨ BALANCED datasets generated!")
    print(f"   Training:   {len(train_data)} records (70%)")
    print(f"   Validation: {len(val_data)} records (15%)")
    print(f"   Testing:    {len(test_data)} records (15%)")
    print(f"   Total:      {len(all_data)} records")
    print("\n💡 Each hour (0-20) has ~70 train / ~15 val / ~15 test examples")
