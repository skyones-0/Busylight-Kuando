//
//  PomodoroPhase.swift
//  Shared models for Pomodoro
//

import Foundation
import SwiftUI

// MARK: - Pomodoro Phase
enum PomodoroPhase: String, Codable, CaseIterable, Equatable {
    case work = "Work"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "sun.max.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .work: return .green
        case .shortBreak: return .blue
        case .longBreak: return .orange
        }
    }
    
    var displayName: String {
        switch self {
        case .work: return NSLocalizedString("Work", comment: "Work phase")
        case .shortBreak: return NSLocalizedString("Short Break", comment: "Short break phase")
        case .longBreak: return NSLocalizedString("Long Break", comment: "Long break phase")
        }
    }
    
    var emoji: String {
        switch self {
        case .work: return "💼"
        case .shortBreak: return "☕️"
        case .longBreak: return "🌴"
        }
    }
}

// MARK: - Light Color
enum LightColor: String, Codable, CaseIterable {
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
    
    var swiftUIColor: Color {
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
    
    var rgb: (red: Int, green: Int, blue: Int) {
        switch self {
        case .red: return (100, 0, 0)
        case .green: return (0, 100, 0)
        case .blue: return (0, 0, 100)
        case .yellow: return (100, 100, 0)
        case .cyan: return (0, 100, 100)
        case .magenta: return (100, 0, 100)
        case .white: return (100, 100, 100)
        case .orange: return (100, 65, 0)
        case .purple: return (75, 0, 100)
        case .pink: return (100, 75, 80)
        case .off: return (0, 0, 0)
        }
    }
}

// MARK: - Work Profile
enum WorkProfile: String, Codable, CaseIterable, Identifiable {
    case coding = "Coding"
    case meetings = "Meetings"
    case learning = "Learning"
    case deepWork = "Deep Work"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .coding: return "laptopcomputer"
        case .meetings: return "person.2.fill"
        case .learning: return "book.fill"
        case .deepWork: return "flame.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
    
    var settings: (work: Int, shortBreak: Int, longBreak: Int, sets: Int) {
        switch self {
        case .coding:
            return (50, 10, 30, 4)
        case .meetings:
            return (25, 5, 15, 8)
        case .learning:
            return (25, 5, 15, 6)
        case .deepWork:
            return (90, 15, 30, 3)
        case .custom:
            return (25, 5, 15, 4)
        }
    }
}

// MARK: - App Theme
enum AppTheme: String, Codable, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Light Effect
enum LightEffect: String, Codable {
    case solid = "Solid"
    case pulse = "Pulse"
    case blinkSlow = "Blink Slow"
    case blinkFast = "Blink Fast"
}

// MARK: - Device Status
struct DeviceStatus: Codable {
    let isConnected: Bool
    let deviceName: String
    let deviceModel: String
    let currentColor: LightColor
    let timestamp: Date
    
    init(
        isConnected: Bool = false,
        deviceName: String = "No Device",
        deviceModel: String = "",
        currentColor: LightColor = .off,
        timestamp: Date = Date()
    ) {
        self.isConnected = isConnected
        self.deviceName = deviceName
        self.deviceModel = deviceModel
        self.currentColor = currentColor
        self.timestamp = timestamp
    }
}
