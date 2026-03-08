//
//  PomodoroSession.swift
//  Busylight
//
//  SwiftData model for Pomodoro sessions
//

import Foundation
import SwiftData

@Model
class PomodoroSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var durationMinutes: Int
    var phase: String
    var completed: Bool
    var notes: String?
    
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        durationMinutes: Int = 25,
        phase: String = "work",
        completed: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.phase = phase
        self.completed = completed
        self.notes = notes
    }
    
    var actualDuration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        guard let duration = actualDuration else { return "--:--" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Query Helpers
// Note: Predicate macros require specific Swift/SwiftData versions
// Using simple fetch descriptors without complex predicates for compatibility
