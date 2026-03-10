//
//  PomodoroSession.swift
//  Busylight
//

import Foundation
import SwiftData

@Model
class PomodoroSession {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var completed: Bool
    var type: String // "focus", "shortBreak", "longBreak"
    var taskName: String?
    var notes: String?
    var createdAt: Date
    
    // CloudKit sync properties
    var isSynced: Bool
    var deviceID: String?
    
    init(
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
        self.isSynced = false
        self.deviceID = nil
    }
}

// MARK: - Timer State

enum PomodoroTimerState: String, Codable {
    case idle
    case focusing
    case shortBreak
    case longBreak
    case paused
}
