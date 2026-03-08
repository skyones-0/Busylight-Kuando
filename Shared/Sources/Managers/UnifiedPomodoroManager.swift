//
//  UnifiedPomodoroManager.swift
//  BusylightShared
//
//  Unified Pomodoro Manager with CloudKit sync
//

import Foundation
import SwiftUI
import Combine

#if os(iOS) || os(watchOS)
import AudioToolbox
import UserNotifications
#endif

#if os(iOS)
import UIKit
#endif

#if os(watchOS)
import WatchKit
#endif

@MainActor
public final class UnifiedPomodoroManager: ObservableObject {
    public static let shared = UnifiedPomodoroManager()
    
    @Published public var isRunning = false
    @Published public var isPaused = false
    @Published public var currentPhase: PomodoroPhase = .work
    @Published public var remainingSeconds: Int = 25 * 60
    @Published public var currentSet: Int = 1
    @Published public var totalSets: Int = 4
    @Published public var progress: Double = 0.0
    
    @AppStorage("pomodoroWorkTime") public var workTimeMinutes: Int = 25
    @AppStorage("pomodoroShortBreak") public var shortBreakMinutes: Int = 5
    @AppStorage("pomodoroLongBreak") public var longBreakMinutes: Int = 15
    @AppStorage("pomodoroSets") public var configuredSets: Int = 4
    @AppStorage("timerSound") public var timerSound: TimerSound = .ding
    @AppStorage("soundEnabled") public var soundEnabled: Bool = true
    @AppStorage("hapticsEnabled") public var hapticsEnabled: Bool = true
    
    public var timeString: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let cloudKit = CloudKitSyncManager.shared
    
    private init() {
        updateConfiguration()
    }
    
    public func start() {
        guard !isRunning else { return }
        
        isRunning = true
        isPaused = false
        
        if remainingSeconds == 0 || progress == 0 {
            remainingSeconds = workTimeMinutes * 60
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        
        updateProgress()
        syncToCloud()
        playStartSound()
        performHaptic(.start)
        
        #if os(iOS)
        startLiveActivity()
        #endif
    }
    
    public func pause() {
        guard isRunning else { return }
        
        isRunning = false
        isPaused = true
        timer?.invalidate()
        timer = nil
        
        syncToCloud()
        performHaptic(.pause)
        
        #if os(iOS)
        updateLiveActivity()
        #endif
    }
    
    public func stop() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        
        currentPhase = .work
        currentSet = 1
        remainingSeconds = workTimeMinutes * 60
        progress = 0
        
        syncToCloud()
        performHaptic(.stop)
        
        #if os(iOS)
        endLiveActivity()
        #endif
    }
    
    public func skip() {
        timer?.invalidate()
        timer = nil
        advanceToNextPhase()
        
        if isRunning {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.tick()
                }
            }
        }
        
        syncToCloud()
        
        #if os(iOS)
        updateLiveActivity()
        #endif
    }
    
    private func tick() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
            updateProgress()
            
            if remainingSeconds % 5 == 0 {
                syncToCloud()
                #if os(iOS)
                updateLiveActivity()
                #endif
            }
        } else {
            phaseComplete()
        }
    }
    
    private func phaseComplete() {
        playCompletionSound()
        performHaptic(.completion)
        sendNotification()
        advanceToNextPhase()
        syncToCloud()
        
        #if os(iOS)
        updateLiveActivity()
        #endif
    }
    
    private func advanceToNextPhase() {
        switch currentPhase {
        case .work:
            if currentSet >= totalSets {
                completeSession()
                return
            } else if currentSet % 4 == 0 {
                currentPhase = .longBreak
                remainingSeconds = longBreakMinutes * 60
            } else {
                currentPhase = .shortBreak
                remainingSeconds = shortBreakMinutes * 60
            }
            
        case .shortBreak, .longBreak:
            currentSet += 1
            if currentSet > totalSets {
                completeSession()
                return
            }
            currentPhase = .work
            remainingSeconds = workTimeMinutes * 60
        }
        
        updateProgress()
    }
    
    private func completeSession() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        
        playSessionCompleteSound()
        performHaptic(.completion)
        
        currentPhase = .work
        currentSet = 1
        remainingSeconds = workTimeMinutes * 60
        progress = 0
        
        syncToCloud()
        
        #if os(iOS)
        endLiveActivity()
        #endif
    }
    
    private func updateProgress() {
        let total = currentPhaseDuration
        guard total > 0 else { progress = 0; return }
        progress = Double(total - remainingSeconds) / Double(total)
    }
    
    private var currentPhaseDuration: Int {
        switch currentPhase {
        case .work: return workTimeMinutes * 60
        case .shortBreak: return shortBreakMinutes * 60
        case .longBreak: return longBreakMinutes * 60
        }
    }
    
    public func updateConfiguration() {
        totalSets = configuredSets
        if !isRunning && !isPaused {
            remainingSeconds = workTimeMinutes * 60
            progress = 0
        }
    }
    
    public func applyProfile(_ profile: WorkProfile) {
        let settings = profile.settings
        workTimeMinutes = settings.work
        shortBreakMinutes = settings.shortBreak
        longBreakMinutes = settings.longBreak
        configuredSets = settings.sets
        updateConfiguration()
        syncToCloud()
    }
    
    private func syncToCloud() {
        let state = PomodoroSyncState(
            isRunning: isRunning,
            isPaused: isPaused,
            currentPhase: currentPhase,
            remainingSeconds: remainingSeconds,
            currentSet: currentSet,
            totalSets: totalSets,
            workTimeMinutes: workTimeMinutes,
            shortBreakMinutes: shortBreakMinutes,
            longBreakMinutes: longBreakMinutes,
            lastUpdated: Date(),
            sourceDevice: cloudKit.currentDeviceID
        )
        
        Task {
            try? await cloudKit.savePomodoroState(state)
        }
    }
    
    private func playStartSound() {
        guard soundEnabled else { return }
        #if os(iOS) || os(watchOS)
        AudioServicesPlaySystemSound(timerSound.systemSoundID)
        #endif
    }
    
    private func playCompletionSound() {
        guard soundEnabled else { return }
        #if os(iOS) || os(watchOS)
        AudioServicesPlaySystemSound(1008)
        #endif
    }
    
    private func playSessionCompleteSound() {
        guard soundEnabled else { return }
        #if os(iOS) || os(watchOS)
        AudioServicesPlaySystemSound(1013)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            AudioServicesPlaySystemSound(1008)
        }
        #endif
    }
    
    private func performHaptic(_ type: HapticType) {
        guard hapticsEnabled else { return }
        Haptics.shared.perform(type)
    }
    
    private func sendNotification() {
        #if os(iOS) || os(watchOS)
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro Complete!"
        content.body = "\(currentPhase.displayName) finished. Time for \(currentPhase == .work ? "a break" : "work")!"
        content.sound = soundEnabled ? .default : nil
        content.interruptionLevel = .timeSensitive
        
        let request = UNNotificationRequest(
            identifier: "pomodoro_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
        #endif
    }
    
    #if os(iOS)
    private func startLiveActivity() {
        // Implemented in LiveActivityManager
    }
    
    private func updateLiveActivity() {
        // Implemented in LiveActivityManager
    }
    
    private func endLiveActivity() {
        // Implemented in LiveActivityManager
    }
    #endif
}

enum HapticType {
    case start, pause, stop, completion, button
}

#if os(iOS)
class Haptics {
    static let shared = Haptics()
    private let notification = UINotificationFeedbackGenerator()
    private let impact = UIImpactFeedbackGenerator(style: .medium)
    
    func perform(_ type: HapticType) {
        switch type {
        case .start, .completion:
            notification.notificationOccurred(.success)
        case .pause, .stop:
            notification.notificationOccurred(.warning)
        case .button:
            impact.impactOccurred()
        }
    }
}
#elseif os(watchOS)
class Haptics {
    static let shared = Haptics()
    func perform(_ type: HapticType) {
        let device = WKInterfaceDevice.current()
        switch type {
        case .start, .completion:
            device.play(.success)
        case .pause:
            device.play(.click)
        case .stop:
            device.play(.stop)
        case .button:
            device.play(.click)
        }
    }
}
#else
class Haptics {
    static let shared = Haptics()
    func perform(_ type: HapticType) {}
}
#endif
