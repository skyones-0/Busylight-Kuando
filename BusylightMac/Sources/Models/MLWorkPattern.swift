//
//  MLWorkPattern.swift
//  Busylight
//
//  ML Training Data Model for Work Schedule Prediction
//

import Foundation
import SwiftData

/// Modelo para almacenar patrones de trabajo del usuario
/// Usado para entrenar el modelo de ML
@Model
class MLWorkPattern {
    var id: UUID
    var date: Date
    var dayOfWeek: Int // 1=Domingo, 2=Lunes, ..., 7=Sábado
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var durationMinutes: Int
    var isHoliday: Bool
    var isWeekend: Bool
    var sessionCount: Int // Número de sesiones de pomodoro
    var deepWorkMinutes: Int
    var calendarEventCount: Int
    var createdAt: Date
    
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
    }
    
    /// Convierte a formato para entrenamiento ML
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

/// Modelo para almacenar calendarios de festivos
@Model
class HolidayCalendar: Identifiable {
    var id: UUID
    var name: String
    var countryCode: String // "US", "MX", "ES", etc.
    var customDates: [Date]
    var isEnabled: Bool
    var createdAt: Date
    
    init(name: String, countryCode: String, customDates: [Date] = []) {
        self.id = UUID()
        self.name = name
        self.countryCode = countryCode
        self.customDates = customDates
        self.isEnabled = true
        self.createdAt = Date()
    }
    
    /// Verifica si una fecha es festivo
    func isHoliday(_ date: Date) -> Bool {
        guard isEnabled else { return false }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: date)
        
        // Verificar fechas personalizadas
        for holidayDate in customDates {
            let holidayComponents = calendar.dateComponents([.month, .day], from: holidayDate)
            if components.month == holidayComponents.month && components.day == holidayComponents.day {
                return true
            }
        }
        
        // Aquí se podrían agregar festivos por país
        // Por ahora solo usamos fechas personalizadas
        return false
    }
}

/// Configuración de ML para el usuario
@Model
class MLConfiguration {
    var id: UUID
    var isMLEnabled: Bool
    var minTrainingDays: Int // Mínimo de días para entrenar (default: 14)
    var lastTrainingDate: Date?
    var modelAccuracy: Double // Precisión del modelo (0-1)
    var selectedHolidayCalendarId: UUID?
    var autoAdjustSchedule: Bool // Ajustar automáticamente work hours
    var confidenceThreshold: Double // Umbral de confianza para aplicar predicciones
    var autoTrainingEnabled: Bool // Entrenar modelo automáticamente cuando hay suficientes datos
    var lastAutoTrainingCheck: Date? // Última vez que se verificó auto-training
    var notificationOnAutoTrain: Bool // Notificar cuando se entrena automáticamente
    
    init() {
        self.id = UUID()
        self.isMLEnabled = false
        self.minTrainingDays = 14
        self.modelAccuracy = 0.0
        self.autoAdjustSchedule = true // Por defecto activado
        self.confidenceThreshold = 0.75
        self.autoTrainingEnabled = true // Por defecto activado
        self.notificationOnAutoTrain = true
    }
}
