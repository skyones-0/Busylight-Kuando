//
//  PomodoroManager.swift
//  Busylight
//
//  Manager for Pomodoro timer functionality with work/break cycles.
//  Controls timer state, notifications, and Busylight color sync.
//
//  Relationships:
//  - Uses: BusylightManager (color sync during timer phases)
//  - Used by: PomodoroView.swift (UI), MenuBarView.swift (menubar timer display)
//  - Notifications: Posts Pomodoro phase change notifications
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

@MainActor
final class PomodoroManager: ObservableObject {
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
        guard totalSeconds > 0 else { return 0 }
        let progress = Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
        return max(0, min(1, progress))
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

        if remainingSeconds == 0 || (!isPaused && currentSet == 1 && currentPhase == .work) {
            remainingSeconds = workTimeMinutes * 60
            currentSet = 1
            currentPhase = .work
        }

        updateBusylightColor()

        BusylightLogger.shared.info("Pomodoro: Started - Phase: \(currentPhase.rawValue), Set: \(currentSet)/\(totalSets)")
        UserInteractionLogger.shared.pomodoroStarted(phase: currentPhase.rawValue, timeMinutes: remainingSeconds / 60)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    func pause() {
        guard isRunning else { return }

        isRunning = false
        isPaused = true
        timer?.invalidate()
        timer = nil

        busylight?.off()

        BusylightLogger.shared.info("Pomodoro: Paused")
        UserInteractionLogger.shared.pomodoroPaused(remainingTime: timeString)
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
        UserInteractionLogger.shared.pomodoroStopped()
    }

    func skip() {
        timer?.invalidate()
        timer = nil
        advanceToNextPhase()

        if isRunning {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.tick()
                }
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

        busylight?.alert()

        advanceToNextPhase()
    }

    private func advanceToNextPhase() {
        switch currentPhase {
        case .work:
            if currentSet >= totalSets {
                completePomodoro()
                return
            } else if currentSet % 4 == 0 {
                currentPhase = .longBreak
                remainingSeconds = longBreakMinutes * 60
            } else {
                currentPhase = .shortBreak
                remainingSeconds = shortBreakMinutes * 60
            }

        case .shortBreak, .longBreak:
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

    // MARK: - Timer State & Stats

    enum TimerState: String {
        case idle, running, paused
    }

    var timerState: TimerState {
        if isRunning { return .running }
        if isPaused { return .paused }
        return .idle
    }

    var phaseDescription: String {
        switch currentPhase {
        case .work: return "Tiempo de concentración"
        case .shortBreak: return "Descanso corto"
        case .longBreak: return "Descanso largo"
        }
    }

    var timeRemaining: Int { remainingSeconds }
    var totalTime: Int { totalSecondsForPhase(currentPhase) }

    @AppStorage("pomodoroSessionsCompleted") var sessionsCompleted: Int = 0
    @AppStorage("pomodoroTotalFocusTime") var totalFocusTime: Int = 0
    @AppStorage("pomodoroStreak") var streak: Int = 0
    @AppStorage("pomodoroMaxSets") var maxSets: Int = 4

    func reset() {
        stop()
    }

    func resume() {
        start()
    }

    func setDuration(_ minutes: Int) {
        guard !isRunning && !isPaused else { return }
        workTimeMinutes = minutes
        remainingSeconds = minutes * 60
    }

    func updateConfiguration() {
        totalSets = configuredSets
        if !isRunning && !isPaused {
            remainingSeconds = workTimeMinutes * 60
        }
        UserInteractionLogger.shared.pomodoroConfigChanged(
            workTime: workTimeMinutes,
            shortBreak: shortBreakMinutes,
            longBreak: longBreakMinutes,
            sets: configuredSets
        )
    }

    deinit {
        timer?.invalidate()
    }
}
