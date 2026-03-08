import Foundation
import SwiftData

/// Estado del temporizador Pomodoro
public enum PomodoroTimerState: String, Codable, Sendable {
    case idle
    case focusing
    case shortBreak
    case longBreak
    case paused
}

/// Sesión Pomodoro - sincronizada vía CloudKit
@Model
public class PomodoroSession {
    @Attribute(.unique) public var id: UUID
    public var startTime: Date
    public var endTime: Date?
    public var duration: TimeInterval
    public var completed: Bool
    public var type: String // "focus", "shortBreak", "longBreak"
    public var taskName: String?
    public var notes: String?
    public var createdAt: Date
    public var modifiedAt: Date
    
    // CloudKit sync
    public var recordID: String?
    public var isSynced: Bool
    public var deviceID: String?
    
    public init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        duration: TimeInterval = 25 * 60,
        type: String = "focus",
        taskName: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.duration = duration
        self.type = type
        self.taskName = taskName
        self.completed = false
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.isSynced = false
        self.deviceID = SyncDevice.current.id
    }
    
    public var isActive: Bool {
        endTime == nil
    }
    
    public var remainingTime: TimeInterval {
        guard isActive else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, duration - elapsed)
    }
}

/// Estado actual del Pomodoro (para Live Activities)
public struct PomodoroLiveState: Codable, Sendable {
    public let sessionId: UUID
    public let state: PomodoroTimerState
    public let startTime: Date
    public let endTime: Date
    public let taskName: String?
    public let currentSet: Int
    public let totalSets: Int
    
    public init(
        sessionId: UUID,
        state: PomodoroTimerState,
        startTime: Date,
        endTime: Date,
        taskName: String? = nil,
        currentSet: Int = 1,
        totalSets: Int = 4
    ) {
        self.sessionId = sessionId
        self.state = state
        self.startTime = startTime
        self.endTime = endTime
        self.taskName = taskName
        self.currentSet = currentSet
        self.totalSets = totalSets
    }
}
