import Foundation
import SwiftData

/// Configuración global del usuario - sincronizada entre dispositivos
@Model
public class UserSettings {
    @Attribute(.unique) public var id: UUID
    
    // Pomodoro Settings
    public var focusDuration: TimeInterval
    public var shortBreakDuration: TimeInterval
    public var longBreakDuration: TimeInterval
    public var sessionsBeforeLongBreak: Int
    public var autoStartBreaks: Bool
    public var autoStartPomodoros: Bool
    
    // Work Hours
    public var workStartHour: Int
    public var workStartMinute: Int
    public var workEndHour: Int
    public var workEndMinute: Int
    public var workDays: [Int] // 1 = Sunday, 7 = Saturday
    
    // Deep Work
    public var deepWorkDuration: TimeInterval
    public var deepWorkNotificationsEnabled: Bool
    
    // Sync
    public var modifiedAt: Date
    public var isSynced: Bool
    public var lastSyncDate: Date?
    
    public init() {
        self.id = UUID()
        
        // Default Pomodoro
        self.focusDuration = 25 * 60
        self.shortBreakDuration = 5 * 60
        self.longBreakDuration = 15 * 60
        self.sessionsBeforeLongBreak = 4
        self.autoStartBreaks = false
        self.autoStartPomodoros = false
        
        // Default Work Hours (9-5)
        self.workStartHour = 9
        self.workStartMinute = 0
        self.workEndHour = 17
        self.workEndMinute = 0
        self.workDays = [2, 3, 4, 5, 6] // Mon-Fri
        
        // Default Deep Work
        self.deepWorkDuration = 120 * 60 // 2 hours
        self.deepWorkNotificationsEnabled = true
        
        self.modifiedAt = Date()
        self.isSynced = false
    }
    
    public var workStartTime: Date {
        Calendar.current.date(from: DateComponents(hour: workStartHour, minute: workStartMinute)) ?? Date()
    }
    
    public var workEndTime: Date {
        Calendar.current.date(from: DateComponents(hour: workEndHour, minute: workEndMinute)) ?? Date()
    }
}

/// Perfil de trabajo
@Model
public class WorkProfile {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var color: String // hex color
    public var icon: String // SF Symbol name
    public var isDefault: Bool
    
    // Settings override
    public var focusDuration: TimeInterval?
    public var workStartHour: Int?
    public var workEndHour: Int?
    
    // Sync
    public var createdAt: Date
    public var modifiedAt: Date
    public var isSynced: Bool
    
    public init(
        name: String,
        color: String = "#007AFF",
        icon: String = "briefcase.fill",
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.icon = icon
        self.isDefault = isDefault
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.isSynced = false
    }
}
