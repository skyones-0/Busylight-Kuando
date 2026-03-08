# ML Training Data for Busylight

This folder contains synthetic training datasets for the CoreML Random Forest models used to predict work schedules.

## Datasets

### 1. work_schedule_training_data.csv (1,200 records)
Main training dataset with realistic work patterns.

**Features:**
- `dayOfWeek`: Day of week (1=Sunday, 7=Saturday)
- `isWeekend`: 0 or 1
- `isHoliday`: 0 or 1
- `sessionCount`: Number of work sessions (0-12)
- `deepWorkMinutes`: Deep work duration (0-480)
- `calendarEventCount`: Calendar events (0-10)
- `startHour`: Predicted start hour (0-23, 0=no work)
- `endHour`: Predicted end hour (0-23, 0=no work)

### 2. testing_data.csv (200 records)
Testing dataset with edge cases and random samples.

### 3. work_schedule_with_holidays.csv (300 records)
Validation dataset with 100 holiday records for testing holiday exclusion.

## Data Generation

To regenerate datasets:
```bash
python3 generate_training_data.py
```

## Patterns in Data

### Weekday Patterns (Monday-Friday)
- **Light days** (1-3 sessions): Start 9-11am, 4-6 hours
- **Normal days** (4-6 sessions): Start 8-9am, 7-8 hours
- **Productive days** (7-9 sessions): Start 7-8am, 8-10 hours
- **Intense days** (10+ sessions): Start 6-8am, 10+ hours

### Weekend Patterns
- 30% probability: No work (0,0)
- Light work: 1-2 sessions, 2-5 hours
- Weekend warrior: 3-6 sessions, 4-8 hours

### Holiday Patterns
- 70% probability: No work
- Light work: 2-4 hours if working

### Deep Work Correlation
- 4+ hours deep work → Early start (6-8am), long day
- 2-4 hours → Normal start (8-9am)
- <2 hours → Later start (9-11am) or no work

## Usage in Create ML

1. Open `predict_hours.mlproj` in Xcode
2. Import these CSV files as data sources
3. Train two models:
   - **StartHours**: Predicts `startHour` from features
   - **EndHours**: Predicts `endHour` from features
4. Algorithm: Random Forest
5. Target: Export as CoreML (.mlmodel)

## Total Records
- Training: 1,200
- Testing: 200
- Validation: 300
- **Total: 1,700 records**

## Statistics

```
Training Data Distribution:
- Weekdays: ~71%
- Weekends: ~20%
- Holidays: ~9%

Start Hour Distribution:
- 0 (no work): ~15%
- 6-8am: ~25%
- 8-10am: ~45%
- 10am-12pm: ~15%

Session Count:
- 0: ~5%
- 1-3: ~25%
- 4-6: ~40%
- 7-9: ~22%
- 10+: ~8%
```
