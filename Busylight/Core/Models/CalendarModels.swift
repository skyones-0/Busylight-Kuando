//
//  CalendarModels.swift
//  Busylight
//
//  Modelos SwiftData para calendarios, tareas y reuniones
//

import Foundation
import SwiftData
import EventKit

/// Configuración de calendarios seleccionados para ML
@Model
class CalendarConfiguration {
    @Attribute(.unique) var id: UUID
    var calendarIdentifier: String
    var calendarName: String
    var calendarType: String // "holiday", "work", "personal", "birthday"
    var isEnabled: Bool
    var colorHex: String?
    var lastSyncDate: Date?
    var createdAt: Date
    
    init(calendarIdentifier: String, calendarName: String, calendarType: String = "work", colorHex: String? = nil) {
        self.id = UUID()
        self.calendarIdentifier = calendarIdentifier
        self.calendarName = calendarName
        self.calendarType = calendarType
        self.isEnabled = true
        self.colorHex = colorHex
        self.createdAt = Date()
    }
}

/// Evento/ reunión almacenado para análisis ML
@Model
class CalendarEvent {
    @Attribute(.unique) var id: UUID
    var eventIdentifier: String
    var title: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var calendarIdentifier: String
    var calendarName: String
    var notes: String?
    var location: String?
    var isMeeting: Bool
    var attendeeCount: Int
    var wasAnalyzed: Bool
    var createdAt: Date
    
    init(eventIdentifier: String, title: String, startDate: Date, endDate: Date,
         isAllDay: Bool = false, calendarIdentifier: String, calendarName: String,
         notes: String? = nil, location: String? = nil, isMeeting: Bool = false,
         attendeeCount: Int = 0) {
        self.id = UUID()
        self.eventIdentifier = eventIdentifier
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.calendarIdentifier = calendarIdentifier
        self.calendarName = calendarName
        self.notes = notes
        self.location = location
        self.isMeeting = isMeeting
        self.attendeeCount = attendeeCount
        self.wasAnalyzed = false
        self.createdAt = Date()
    }
    
    var durationMinutes: Int {
        Int(endDate.timeIntervalSince(startDate) / 60)
    }
}

/// Tarea/recordatorio almacenado
@Model
class CalendarTask {
    @Attribute(.unique) var id: UUID
    var taskIdentifier: String
    var title: String
    var dueDate: Date?
    var isCompleted: Bool
    var priority: Int // 0=none, 1=low, 2=medium, 3=high
    var calendarIdentifier: String
    var notes: String?
    var createdAt: Date
    var completedAt: Date?
    
    init(taskIdentifier: String, title: String, dueDate: Date? = nil,
         priority: Int = 0, calendarIdentifier: String, notes: String? = nil) {
        self.id = UUID()
        self.taskIdentifier = taskIdentifier
        self.title = title
        self.dueDate = dueDate
        self.isCompleted = false
        self.priority = priority
        self.calendarIdentifier = calendarIdentifier
        self.notes = notes
        self.createdAt = Date()
    }
}

/// Configuración general de la app
@Model
class AppSettings {
    @Attribute(.unique) var id: UUID
    
    // Apariencia
    var appearanceMode: Int // 0=system, 1=light, 2=dark
    var showInDock: Bool
    var showInMenuBar: Bool
    
    // Notificaciones
    var twentyTwentyEnabled: Bool
    var deepWorkNotificationsEnabled: Bool
    var dayPredictionNotificationsEnabled: Bool
    var breakRemindersEnabled: Bool
    
    // ML
    var mlEnabled: Bool
    var autoTrainingEnabled: Bool
    var autoAdjustSchedule: Bool
    
    // Sync
    var lastCalendarSync: Date?
    var autoSyncCalendars: Bool
    
    // GPS Location
    var detectedCountryCode: String?
    var detectedCountryName: String?
    var detectedCountryFlag: String?
    var autoDetectLocation: Bool
    
    var createdAt: Date
    var updatedAt: Date
    
    init() {
        self.id = UUID()
        self.appearanceMode = 0
        self.showInDock = true
        self.showInMenuBar = true
        self.twentyTwentyEnabled = true
        self.deepWorkNotificationsEnabled = true
        self.dayPredictionNotificationsEnabled = true
        self.breakRemindersEnabled = true
        self.mlEnabled = true
        self.autoTrainingEnabled = true
        self.autoAdjustSchedule = false
        self.autoSyncCalendars = true
        self.autoDetectLocation = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Extensiones Helper

extension CalendarEvent {
    /// Determina si el evento es una reunión basado en varios factores
    func analyzeIfMeeting() {
        // Palabras clave que indican reunión
        let meetingKeywords = ["meeting", "reunión", "sync", "standup", "review", "llamada", "call", "zoom", "teams"]
        let lowerTitle = title.lowercased()
        
        let hasMeetingKeyword = meetingKeywords.contains { lowerTitle.contains($0) }
        let hasAttendees = attendeeCount > 0
        let reasonableDuration = durationMinutes >= 15 && durationMinutes <= 180 // 15 min - 3 horas
        
        isMeeting = hasMeetingKeyword || hasAttendees || (reasonableDuration && location != nil)
    }
}

extension CalendarConfiguration {
    static let supportedCountries = [
        (code: "US", name: "United States", flag: "🇺🇸"),
        (code: "MX", name: "Mexico", flag: "🇲🇽"),
        (code: "ES", name: "Spain", flag: "🇪🇸"),
        (code: "CO", name: "Colombia", flag: "🇨🇴"),
        (code: "AR", name: "Argentina", flag: "🇦🇷"),
        (code: "CL", name: "Chile", flag: "🇨🇱"),
        (code: "PE", name: "Peru", flag: "🇵🇪"),
        (code: "UK", name: "United Kingdom", flag: "🇬🇧"),
        (code: "CA", name: "Canada", flag: "🇨🇦")
    ]
}
