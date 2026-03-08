import Foundation
import SwiftData

// MARK: - ML Work Pattern

/// Patrón de trabajo diario para entrenamiento ML
@Model
public class MLWorkPattern {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var dayOfWeek: Int
    public var startHour: Int
    public var startMinute: Int
    public var endHour: Int
    public var endMinute: Int
    public var durationMinutes: Int
    public var isHoliday: Bool
    public var isWeekend: Bool
    public var sessionCount: Int
    public var deepWorkMinutes: Int
    public var calendarEventCount: Int
    public var createdAt: Date
    
    // Sync
    public var isSynced: Bool
    public var deviceID: String?
    
    public init(
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
        self.deviceID = SyncDevice.current.id
    }
}

// MARK: - ML Configuration

@Model
public class MLConfiguration {
    @Attribute(.unique) public var id: UUID
    public var isMLEnabled: Bool
    public var minTrainingDays: Int
    public var lastTrainingDate: Date?
    public var modelAccuracy: Double
    public var selectedHolidayCalendarId: UUID?
    public var autoAdjustSchedule: Bool
    public var confidenceThreshold: Double
    public var autoTrainingEnabled: Bool?
    public var lastAutoTrainingCheck: Date?
    public var notificationOnAutoTrain: Bool?
    
    // Sync
    public var modifiedAt: Date
    public var isSynced: Bool
    
    public init() {
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
    
    public var isAutoTrainingEnabled: Bool {
        autoTrainingEnabled ?? true
    }
}

// MARK: - Holiday Calendar

@Model
public class HolidayCalendar: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var countryCode: String
    public var customDates: [Date]
    public var isEnabled: Bool
    public var createdAt: Date
    public var isSystemCalendar: Bool
    
    // Sync
    public var modifiedAt: Date
    public var isSynced: Bool
    
    public init(
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
    
    /// Verifica si una fecha es festivo
    public func isHoliday(_ date: Date) -> Bool {
        guard isEnabled else { return false }
        
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let components = calendar.dateComponents([.month, .day], from: date)
        
        // Verificar fechas personalizadas
        for holidayDate in customDates {
            let holidayComponents = calendar.dateComponents([.month, .day], from: holidayDate)
            if components.month == holidayComponents.month && components.day == holidayComponents.day {
                return true
            }
        }
        
        // Verificar festivos del país para el año actual
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
    
    /// Lista de países disponibles con calendarios predefinidos
    public static let availableCountries = HolidayData.availableCountries
}
