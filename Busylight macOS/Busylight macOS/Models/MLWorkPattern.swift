//
//  MLWorkPattern.swift
//  Busylight
//

import Foundation
import SwiftData

@Model
class MLWorkPattern {
    @Attribute(.unique) var id: UUID
    var date: Date
    var dayOfWeek: Int
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var durationMinutes: Int
    var isHoliday: Bool
    var isWeekend: Bool
    var sessionCount: Int
    var deepWorkMinutes: Int
    var calendarEventCount: Int
    var createdAt: Date
    
    // CloudKit sync
    var isSynced: Bool
    var deviceID: String?
    
    init(
        date: Date,
        dayOfWeek: Int,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        isHoliday: Bool = false,
        sessionCount: Int = 0,
        deepWorkMinutes: Int = 0,
        calendarEventCount: Int = 0
    ) {
        self.id = UUID()
        self.date = date
        self.dayOfWeek = dayOfWeek
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.durationMinutes = (endHour * 60 + endMinute) - (startHour * 60 + startMinute)
        self.isHoliday = isHoliday
        self.isWeekend = dayOfWeek == 1 || dayOfWeek == 7
        self.sessionCount = sessionCount
        self.deepWorkMinutes = deepWorkMinutes
        self.calendarEventCount = calendarEventCount
        self.createdAt = Date()
        self.isSynced = false
    }
    
    var mlFeatures: [String: Double] {
        [
            "dayOfWeek": Double(dayOfWeek),
            "isWeekend": isWeekend ? 1.0 : 0.0,
            "isHoliday": isHoliday ? 1.0 : 0.0,
            "sessionCount": Double(sessionCount),
            "deepWorkMinutes": Double(deepWorkMinutes),
            "calendarEventCount": Double(calendarEventCount)
        ]
    }
    
    var startTimeValue: Double {
        Double(startHour) + Double(startMinute) / 60.0
    }
    
    var endTimeValue: Double {
        Double(endHour) + Double(endMinute) / 60.0
    }
}

@Model
class HolidayCalendar: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var countryCode: String
    var customDates: [Date]
    var isEnabled: Bool
    var createdAt: Date
    var isSystemCalendar: Bool
    
    // CloudKit sync
    var modifiedAt: Date
    var isSynced: Bool
    
    init(
        name: String,
        countryCode: String,
        customDates: [Date] = [],
        isSystemCalendar: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.countryCode = countryCode
        self.customDates = customDates
        self.isEnabled = true
        self.createdAt = Date()
        self.isSystemCalendar = isSystemCalendar
        self.modifiedAt = Date()
        self.isSynced = false
    }
    
    func isHoliday(_ date: Date) -> Bool {
        guard isEnabled else { return false }
        
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let components = calendar.dateComponents([.month, .day], from: date)
        
        // Check custom dates
        for holidayDate in customDates {
            let holidayComponents = calendar.dateComponents([.month, .day], from: holidayDate)
            if components.month == holidayComponents.month && components.day == holidayComponents.day {
                return true
            }
        }
        
        // Check predefined holidays
        if !isSystemCalendar || countryCode == "CUSTOM" {
            return false
        }
        
        let holidays = HolidayData.holidays(for: countryCode, year: year)
        for holiday in holidays {
            let holidayComponents = calendar.dateComponents([.month, .day], from: holiday)
            if components.month == holidayComponents.month && components.day == holidayComponents.day {
                return true
            }
        }
        
        return false
    }
    
    static let availableCountries: [(code: String, name: String, flag: String)] = [
        ("US", "United States", "🇺🇸"),
        ("MX", "Mexico", "🇲🇽"),
        ("ES", "Spain", "🇪🇸"),
        ("UK", "United Kingdom", "🇬🇧"),
        ("CA", "Canada", "🇨🇦")
    ]
    
    static func getHolidays(for countryCode: String, year: Int) -> [Date] {
        HolidayData.holidays(for: countryCode, year: year)
    }
}

@Model
class MLConfiguration {
    @Attribute(.unique) var id: UUID
    var isMLEnabled: Bool
    var minTrainingDays: Int
    var lastTrainingDate: Date?
    var modelAccuracy: Double
    var selectedHolidayCalendarId: UUID?
    var autoAdjustSchedule: Bool
    var confidenceThreshold: Double
    var autoTrainingEnabled: Bool?
    var lastAutoTrainingCheck: Date?
    var notificationOnAutoTrain: Bool?
    
    // CloudKit sync
    var modifiedAt: Date
    var isSynced: Bool
    
    init() {
        self.id = UUID()
        self.isMLEnabled = false
        self.minTrainingDays = 14
        self.modelAccuracy = 0.0
        self.autoAdjustSchedule = true
        self.confidenceThreshold = 0.75
        self.autoTrainingEnabled = true
        self.notificationOnAutoTrain = true
        self.modifiedAt = Date()
        self.isSynced = false
    }
    
    var isAutoTrainingEnabled: Bool {
        autoTrainingEnabled ?? true
    }
    
    var shouldNotifyOnAutoTrain: Bool {
        notificationOnAutoTrain ?? true
    }
}

// MARK: - Supporting Types

struct SchedulePrediction {
    let date: Date
    let predictedStartHour: Int
    let predictedEndHour: Int
    let confidence: Double
    
    var formattedStartTime: String {
        String(format: "%02d:00", predictedStartHour)
    }
    
    var formattedEndTime: String {
        String(format: "%02d:00", predictedEndHour)
    }
}

enum MLError: Error, LocalizedError {
    case insufficientData
    case trainingFailed
    case modelNotFound
    
    var errorDescription: String? {
        switch self {
        case .insufficientData:
            return "At least 3 days of work data needed to train the model"
        case .trainingFailed:
            return "Model training failed"
        case .modelNotFound:
            return "No trained model found"
        }
    }
}
