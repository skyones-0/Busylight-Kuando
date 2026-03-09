# ML Training Data for Busylight - BALANCED

This folder contains **balanced** training datasets for CoreML Random Forest models.

## ⚠️ Problem Solved: Class Imbalance

**Before:**
- Hour 0: 43 examples
- Hour 11: 2 examples ← **Too few!**
- Hour 20: 2 examples ← **Too few!**
- Result: 40% testing accuracy

**After (Current):**
- Every hour (0-20): **70 training examples**
- Every hour (0-20): **15 validation examples**
- Every hour (0-20): **15 testing examples**
- Result: **Expect 75-85% testing accuracy**

## Datasets

### 1. work_schedule_training_data.csv (1,470 records)
**Perfectly balanced training set**
- 70 examples per hour (0-20)
- 21 hours × 70 = 1,470 records

### 2. work_schedule_validation.csv (315 records)
**Balanced validation set**
- 15 examples per hour (0-20)
- Used for tuning during training

### 3. testing_data.csv (315 records)
**Balanced testing set**
- 15 examples per hour (0-20)
- Used for final evaluation

## Balance Check

```
Hour  0: 70 train, 15 val, 15 test  ✅
Hour  1: 70 train, 15 val, 15 test  ✅
Hour  2: 70 train, 15 val, 15 test  ✅
...
Hour 11: 70 train, 15 val, 15 test  ✅ (was only 2!)
Hour 20: 70 train, 15 val, 15 test  ✅ (was only 2!)
```

## Features

| Feature | Description | Range |
|---------|-------------|-------|
| dayOfWeek | Day of week | 1-7 (1=Sunday) |
| isWeekend | Weekend flag | 0 or 1 |
| isHoliday | Holiday flag | 0 or 1 |
| sessionCount | Work sessions | 0-12 |
| deepWorkMinutes | Deep work | 0-480 |
| calendarEventCount | Meetings | 0-10 |
| **startHour** | **Target** | **0-20** |
| endHour | Calculated | 0-23 |

## Usage in Create ML

1. Open `predict_hours.mlproj` in Xcode
2. **Import work_schedule_training_data.csv** as Training
3. **Import work_schedule_validation.csv** as Validation
4. **Import testing_data.csv** as Testing
5. Configure Random Forest:
   - Max Depth: **6-8** (limit overfitting)
   - Min Samples Per Leaf: **10-15**
   - Iterations: **100-200**
6. Train model
7. Expected results:
   - Training: 85-95%
   - Validation: 75-85%
   - Testing: 75-85% ← **Balanced!**

## Regenerate

```bash
cd "Busylight macOS/ML Training Data"
python3 generate_balanced_data.py
```

## Total Records
- Training: 1,470
- Validation: 315
- Testing: 315
- **Total: 2,100 records**

## Why This Works

1. **Equal representation**: Every hour has same number of examples
2. **Stratified split**: Train/Val/Test maintain same distribution
3. **Sufficient data**: 70+ examples per class is good for Random Forest
4. **Realistic patterns**: Features correlate with target hour
