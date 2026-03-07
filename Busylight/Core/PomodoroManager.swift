//
//  PomodoroManager.swift
//  Busylight
//
//  Manager for Pomodoro timer functionality
//

import Foundation
import SwiftUI
import Combine

enum PomodoroPhase: String, CaseIterable {
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
}

class PomodoroManager: ObservableObject {
    // MARK: - Singleton
    static let shared = PomodoroManager()
    
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentPhase: PomodoroPhase = .work
    @Published var remainingSeconds: Int = 25 * 60
    @Published var currentSet: Int = 1
    @Published var totalSets: Int = 3
    
    // Configuration
    @AppStorage("pomodoroWorkTime") var workTimeMinutes: Int = 25
    @AppStorage("pomodoroShortBreak") var shortBreakMinutes: Int = 5
    @AppStorage("pomodoroLongBreak") var longBreakMinutes: Int = 15
    @AppStorage("pomodoroSets") var configuredSets: Int = 3
    
    private var timer: Timer?
    private weak var busylight: BusylightManager?
    
    private init() {
        self.totalSets = configuredSets
        self.remainingSeconds = workTimeMinutes * 60
    }
    
    func configure(with busylight: BusylightManager) {
        self.busylight = busylight
    }
    
    var timeString: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }
    
    var progress: Double {
        let totalSeconds = totalSecondsForPhase(currentPhase)
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }
    
    private func totalSecondsForPhase(_ phase: PomodoroPhase) -> Int {
        switch phase {
        case .work:
            return workTimeMinutes * 60
        case .shortBreak:
            return shortBreakMinutes * 60
        case .longBreak:
            return longBreakMinutes * 60
        }
    }
    
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        isPaused = false
        
        // Set initial time if starting fresh
        if remainingSeconds == 0 || (!isPaused && currentSet == 1 && currentPhase == .work) {
            remainingSeconds = workTimeMinutes * 60
            currentSet = 1
            currentPhase = .work
        }
        
        // Update Busylight color based on phase
        updateBusylightColor()
        
        BusylightLogger.shared.info("Pomodoro: Started - Phase: \(currentPhase.rawValue), Set: \(currentSet)/\(totalSets)")
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func pause() {
        guard isRunning else { return }
        
        isRunning = false
        isPaused = true
        timer?.invalidate()
        timer = nil
        
        // Dim the light or turn off
        busylight?.off()
        
        BusylightLogger.shared.info("Pomodoro: Paused")
    }
    
    func stop() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        
        currentPhase = .work
        currentSet = 1
        remainingSeconds = workTimeMinutes * 60
        
        busylight?.off()
        
        BusylightLogger.shared.info("Pomodoro: Stopped and reset")
    }
    
    func skip() {
        timer?.invalidate()
        timer = nil
        advanceToNextPhase()
        
        if isRunning {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.tick()
            }
        }
    }
    
    private func tick() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        } else {
            phaseComplete()
        }
    }
    
    private func phaseComplete() {
        BusylightLogger.shared.info("Pomodoro: Phase complete - \(currentPhase.rawValue)")
        
        // Play alert
        busylight?.alert()
        
        // Advance to next phase
        advanceToNextPhase()
    }
    
    private func advanceToNextPhase() {
        switch currentPhase {
        case .work:
            // After work, decide if short break or long break
            if currentSet >= totalSets {
                // All sets complete
                completePomodoro()
                return
            } else if currentSet % 4 == 0 {
                // Every 4th set, take long break
                currentPhase = .longBreak
                remainingSeconds = longBreakMinutes * 60
            } else {
                // Regular short break
                currentPhase = .shortBreak
                remainingSeconds = shortBreakMinutes * 60
            }
            
        case .shortBreak, .longBreak:
            // After break, back to work
            if currentPhase == .longBreak {
                currentSet += 1
            } else {
                currentSet += 1
            }
            
            if currentSet > totalSets {
                completePomodoro()
                return
            }
            
            currentPhase = .work
            remainingSeconds = workTimeMinutes * 60
        }
        
        updateBusylightColor()
        BusylightLogger.shared.info("Pomodoro: New phase - \(currentPhase.rawValue), Set: \(currentSet)/\(totalSets)")
    }
    
    private func completePomodoro() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        
        currentPhase = .work
        currentSet = 1
        remainingSeconds = workTimeMinutes * 60
        
        // Final completion alert
        busylight?.jingle(
            soundNumber: 1,
            red: 0,
            green: 100,
            blue: 0,
            andVolume: 80
        )
        
        BusylightLogger.shared.info("Pomodoro: Session complete!")
    }
    
    private func updateBusylightColor() {
        switch currentPhase {
        case .work:
            busylight?.green()
        case .shortBreak:
            busylight?.blue()
        case .longBreak:
            busylight?.orange()
        }
    }
    
    func updateConfiguration() {
        totalSets = configuredSets
        if !isRunning && !isPaused {
            remainingSeconds = workTimeMinutes * 60
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
