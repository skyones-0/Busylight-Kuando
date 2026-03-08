//
//  PomodoroSession.swift
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
    var deviceID: String?
    var syncedToCloud: Bool
    
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        durationMinutes: Int = 25,
        phase: String = "work",
        completed: Bool = false,
        notes: String? = nil,
        deviceID: String? = nil,
        syncedToCloud: Bool = false
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.phase = phase
        self.completed = completed
        self.notes = notes
        self.deviceID = deviceID
        self.syncedToCloud = syncedToCloud
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
    
    var phaseEnum: PomodoroPhase {
        PomodoroPhase(rawValue: phase) ?? .work
    }
}

// MARK: - Session Statistics
struct SessionStats {
    let totalSessions: Int
    let totalMinutes: Int
    let completedSessions: Int
    let currentStreak: Int
    let bestStreak: Int
    let weeklyStats: [DayStat]
    
    struct DayStat: Identifiable {
        let id = UUID()
        let day: String
        let sessions: Int
        let minutes: Int
    }
}

// MARK: - Sample Data for Previews
extension PomodoroSession {
    static var sampleSessions: [PomodoroSession] {
        [
            PomodoroSession(
                startTime: Date().addingTimeInterval(-3600),
                endTime: Date().addingTimeInterval(-2100),
                durationMinutes: 25,
                phase: "work",
                completed: true
            ),
            PomodoroSession(
                startTime: Date().addingTimeInterval(-1800),
                endTime: Date().addingTimeInterval(-1500),
                durationMinutes: 5,
                phase: "shortBreak",
                completed: true
            ),
            PomodoroSession(
                startTime: Date().addingTimeInterval(-1400),
                durationMinutes: 25,
                phase: "work",
                completed: false
            )
        ]
    }
}
