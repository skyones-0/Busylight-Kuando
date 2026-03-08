//
//  SharedModels.swift
//  BusylightShared
//
//  Shared models for macOS, iOS, and watchOS
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Pomodoro Phase
public enum PomodoroPhase: String, Codable, CaseIterable, Sendable {
    case work = "Work"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    public var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "sun.max.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .work: return .green
        case .shortBreak: return .blue
        case .longBreak: return .orange
        }
    }
    
    public var displayName: String {
        switch self {
        case .work: return "Work"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
}

// MARK: - Light Color
public enum LightColor: String, Codable, CaseIterable, Sendable {
    case red = "Red"
    case green = "Green"
    case blue = "Blue"
    case yellow = "Yellow"
    case cyan = "Cyan"
    case magenta = "Magenta"
    case white = "White"
    case orange = "Orange"
    case purple = "Purple"
    case pink = "Pink"
    case off = "Off"
    
    public var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .green: return .green
        case .blue: return .blue
        case .yellow: return .yellow
        case .cyan: return .cyan
        case .magenta: return .pink
        case .white: return .white
        case .orange: return .orange
        case .purple: return .purple
        case .pink: return .pink
        case .off: return .gray
        }
    }
}

// MARK: - Work Profile
public enum WorkProfile: String, Codable, CaseIterable, Identifiable, Sendable {
    case coding = "Coding"
    case meetings = "Meetings"
    case learning = "Learning"
    case deepWork = "Deep Work"
    case custom = "Custom"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .coding: return "laptopcomputer"
        case .meetings: return "person.2.fill"
        case .learning: return "book.fill"
        case .deepWork: return "flame.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
    
    public var settings: (work: Int, shortBreak: Int, longBreak: Int, sets: Int) {
        switch self {
        case .coding: return (50, 10, 30, 4)
        case .meetings: return (25, 5, 15, 8)
        case .learning: return (25, 5, 15, 6)
        case .deepWork: return (90, 15, 30, 3)
        case .custom: return (25, 5, 15, 4)
        }
    }
}

// MARK: - Pomodoro Session
@Model
public class PomodoroSession {
    public var id: UUID
    public var startTime: Date
    public var endTime: Date?
    public var durationMinutes: Int
    public var phase: String
    public var completed: Bool
    public var deviceID: String?
    public var syncedToCloud: Bool
    
    public init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        durationMinutes: Int = 25,
        phase: String = "work",
        completed: Bool = false,
        deviceID: String? = nil,
        syncedToCloud: Bool = false
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.phase = phase
        self.completed = completed
        self.deviceID = deviceID
        self.syncedToCloud = syncedToCloud
    }
    
    public var phaseEnum: PomodoroPhase {
        PomodoroPhase(rawValue: phase) ?? .work
    }
}

// MARK: - Sync State
public struct PomodoroSyncState: Codable, Equatable, Sendable {
    public let isRunning: Bool
    public let isPaused: Bool
    public let currentPhase: PomodoroPhase
    public let remainingSeconds: Int
    public let currentSet: Int
    public let totalSets: Int
    public let workTimeMinutes: Int
    public let shortBreakMinutes: Int
    public let longBreakMinutes: Int
    public let lastUpdated: Date
    public let sourceDevice: String
    
    public init(
        isRunning: Bool = false,
        isPaused: Bool = false,
        currentPhase: PomodoroPhase = .work,
        remainingSeconds: Int = 1500,
        currentSet: Int = 1,
        totalSets: Int = 4,
        workTimeMinutes: Int = 25,
        shortBreakMinutes: Int = 5,
        longBreakMinutes: Int = 15,
        lastUpdated: Date = Date(),
        sourceDevice: String = ""
    ) {
        self.isRunning = isRunning
        self.isPaused = isPaused
        self.currentPhase = currentPhase
        self.remainingSeconds = remainingSeconds
        self.currentSet = currentSet
        self.totalSets = totalSets
        self.workTimeMinutes = workTimeMinutes
        self.shortBreakMinutes = shortBreakMinutes
        self.longBreakMinutes = longBreakMinutes
        self.lastUpdated = lastUpdated
        self.sourceDevice = sourceDevice
    }
}

// MARK: - Timer Sound
public enum TimerSound: String, Codable, CaseIterable, Sendable {
    case ding = "ding"
    case bell = "bell"
    case digital = "digital"
    case gentle = "gentle"
    case arcade = "arcade"
    
    public var displayName: String {
        switch self {
        case .ding: return "Ding"
        case .bell: return "Bell"
        case .digital: return "Digital"
        case .gentle: return "Gentle"
        case .arcade: return "Arcade"
        }
    }
    
    #if os(iOS) || os(watchOS)
    public var systemSoundID: UInt32 {
        switch self {
        case .ding: return 1005
        case .bell: return 1009
        case .digital: return 1013
        case .gentle: return 1020
        case .arcade: return 1027
        }
    }
    #endif
}
