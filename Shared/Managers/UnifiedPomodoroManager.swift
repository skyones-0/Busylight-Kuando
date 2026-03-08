//
//  UnifiedPomodoroManager.swift
//  Unified Pomodoro timer with CloudKit sync
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

// MARK: - Timer Sound Types
enum TimerSound: String, CaseIterable {
    case ding = "ding"
    case bell = "bell"
    case digital = "digital"
    case gentle = "gentle"
    case arcade = "arcade"
    
    var systemSoundID: SystemSoundID {
        switch self {
        case .ding: return 1005
        case .bell: return 1009
        case .digital: return 1013
        case .gentle: return 1020
        case .arcade: return 1027
        }
    }
    
    var displayName: String {
        switch self {
        case .ding: return "Ding"
        case .bell: return "Bell"
        case .digital: return "Digital"
        case .gentle: return "Gentle"
        case .arcade: return "Arcade"
        }
    }
}

// MARK: - Unified Pomodoro Manager
@MainActor
class UnifiedPomodoroManager: ObservableObject {
    static let shared = UnifiedPomodoroManager()
    
    // MARK: - Published Properties
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentPhase: PomodoroPhase = .work
    @Published var remainingSeconds: Int = 25 * 60
    @Published var currentSet: Int = 1
    @Published var totalSets: Int = 3
    @Published var progress: Double = 0.0
    
    // Configuration
    @AppStorage("pomodoroWorkTime") var workTimeMinutes: Int = 25
    @AppStorage("pomodoroShortBreak") var shortBreakMinutes: Int = 5
    @AppStorage("pomodoroLongBreak") var longBreakMinutes: Int = 15
    @AppStorage("pomodoroSets") var configuredSets: Int = 3
    @AppStorage("timerSound") var timerSound: TimerSound = .ding
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    
    // Computed Properties
    var timeString: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }
    
    var currentPhaseDuration: Int {
        switch currentPhase {
        case .work: return workTimeMinutes * 60
        case .shortBreak: return shortBreakMinutes * 60
        case .longBreak: return longBreakMinutes * 60
        }
    }
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let syncManager = SyncManager.shared
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        setupSubscriptions()
        updateConfiguration()
    }
    
    // MARK: - Setup
    private func setupSubscriptions() {
        // Listen for remote sync state changes
        NotificationCenter.default.publisher(for: .cloudKitSyncCompleted)
            .compactMap { $0.object as? PomodoroSyncState }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleRemoteStateChange(state)
            }
            .store(in: &cancellables)
        
        // Listen for sync commands
        NotificationCenter.default.publisher(for: .syncCommandReceived)
            .sink { [weak self] notification in
                self?.handleSyncCommand(notification)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Timer Control
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        isPaused = false
        
        // Initialize time if starting fresh
        if remainingSeconds == 0 || (!isPaused && currentSet == 1 && currentPhase == .work && progress == 0) {
            remainingSeconds = workTimeMinutes * 60
            currentSet = 1
            currentPhase = .work
        }
        
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        
        // Update UI and sync
        updateProgress()
        syncState()
        playStartSound()
        performHaptic(.start)
        
        // Update Dynamic Island / Live Activity
        startLiveActivity()
    }
    
    func pause() {
        guard isRunning else { return }
        
        isRunning = false
        isPaused = true
        timer?.invalidate()
        timer = nil
        
        syncState()
        performHaptic(.pause)
        updateLiveActivity()
    }
    
    func stop() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        
        currentPhase = .work
        currentSet = 1
        remainingSeconds = workTimeMinutes * 60
        progress = 0
        
        syncState()
        performHaptic(.stop)
        endLiveActivity()
    }
    
    func skip() {
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
        
        syncState()
        updateLiveActivity()
    }
    
    private func tick() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
            updateProgress()
            
            // Sync every 5 seconds to reduce CloudKit calls
            if remainingSeconds % 5 == 0 {
                syncState()
                updateLiveActivity()
            }
        } else {
            phaseComplete()
        }
    }
    
    private func phaseComplete() {
        playCompletionSound()
        performHaptic(.completion)
        
        // Send notification
        sendPhaseCompleteNotification()
        
        // Advance to next phase
        advanceToNextPhase()
        
        // Update sync
        syncState()
        updateLiveActivity()
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
        
        // Play completion sound
        playSessionCompleteSound()
        performHaptic(.completion)
        
        // Reset
        currentPhase = .work
        currentSet = 1
        remainingSeconds = workTimeMinutes * 60
        progress = 0
        
        syncState()
        endLiveActivity()
        sendSessionCompleteNotification()
    }
    
    // MARK: - Progress & State
    private func updateProgress() {
        let total = currentPhaseDuration
        guard total > 0 else {
            progress = 0
            return
        }
        progress = Double(total - remainingSeconds) / Double(total)
    }
    
    func updateConfiguration() {
        totalSets = configuredSets
        if !isRunning && !isPaused {
            remainingSeconds = workTimeMinutes * 60
            progress = 0
        }
    }
    
    func applyProfile(_ profile: WorkProfile) {
        let settings = profile.settings
        workTimeMinutes = settings.work
        shortBreakMinutes = settings.shortBreak
        longBreakMinutes = settings.longBreak
        configuredSets = settings.sets
        updateConfiguration()
        syncState()
    }
    
    // MARK: - Sync
    private func syncState() {
        syncManager.updateState(
            isRunning: isRunning,
            isPaused: isPaused,
            currentPhase: currentPhase,
            remainingSeconds: remainingSeconds,
            currentSet: currentSet,
            totalSets: totalSets
        )
    }
    
    private func handleRemoteStateChange(_ state: PomodoroSyncState) {
        // Only update if this is from another device
        guard state.sourceDevice != CloudKitManager.shared.currentDeviceID else { return }
        
        // Check if we need to sync
        let shouldUpdate = abs(state.lastUpdated.timeIntervalSinceNow) < 30 // Within 30 seconds
        
        if shouldUpdate {
            isRunning = state.isRunning
            isPaused = state.isPaused
            currentPhase = state.currentPhase
            remainingSeconds = state.remainingSeconds
            currentSet = state.currentSet
            totalSets = state.totalSets
            workTimeMinutes = state.workTimeMinutes
            shortBreakMinutes = state.shortBreakMinutes
            longBreakMinutes = state.longBreakMinutes
            
            updateProgress()
            
            // Restart timer if running
            if isRunning && timer == nil {
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                    Task { @MainActor in
                        self?.tick()
                    }
                }
            } else if !isRunning {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    private func handleSyncCommand(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let commandString = userInfo["command"] as? String,
              let command = SyncCommand(rawValue: commandString) else { return }
        
        switch command {
        case .startPomodoro:
            if !isRunning { start() }
        case .pausePomodoro:
            if isRunning { pause() }
        case .stopPomodoro:
            stop()
        case .skipPhase:
            skip()
        default:
            break
        }
    }
    
    // MARK: - Audio
    private func playStartSound() {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(timerSound.systemSoundID)
    }
    
    private func playCompletionSound() {
        guard soundEnabled else { return }
        // Different sound for completion
        switch currentPhase {
        case .work:
            AudioServicesPlaySystemSound(1008) // Success sound
        case .shortBreak, .longBreak:
            AudioServicesPlaySystemSound(timerSound.systemSoundID)
        }
    }
    
    private func playSessionCompleteSound() {
        guard soundEnabled else { return }
        // Play a sequence of sounds
        AudioServicesPlaySystemSound(1013)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            AudioServicesPlaySystemSound(1008)
        }
    }
    
    // MARK: - Haptics
    private func performHaptic(_ type: HapticType) {
        guard hapticsEnabled else { return }
        Haptics.shared.perform(type)
    }
    
    // MARK: - Notifications
    private func sendPhaseCompleteNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro Complete!"
        content.body = "\(currentPhase.displayName) finished. Time for \(currentPhase == .work ? "a break" : "work")!"
        content.sound = soundEnabled ? .default : nil
        content.interruptionLevel = .timeSensitive
        
        let request = UNNotificationRequest(
            identifier: "phase_complete_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func sendSessionCompleteNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Session Complete!"
        content.body = "You completed \(totalSets) pomodoros. Great work!"
        content.sound = soundEnabled ? .default : nil
        content.interruptionLevel = .timeSensitive
        
        let request = UNNotificationRequest(
            identifier: "session_complete_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Live Activity
    #if os(iOS)
    private func startLiveActivity() {
        LiveActivityManager.shared.startActivity(
            phase: currentPhase,
            remainingSeconds: remainingSeconds,
            totalSets: totalSets,
            currentSet: currentSet
        )
    }
    
    private func updateLiveActivity() {
        LiveActivityManager.shared.updateActivity(
            phase: currentPhase,
            remainingSeconds: remainingSeconds,
            isRunning: isRunning,
            currentSet: currentSet,
            totalSets: totalSets
        )
    }
    
    private func endLiveActivity() {
        LiveActivityManager.shared.endActivity()
    }
    #else
    private func startLiveActivity() {}
    private func updateLiveActivity() {}
    private func endLiveActivity() {}
    #endif
}

// MARK: - Haptic Types
enum HapticType {
    case start
    case pause
    case stop
    case completion
    case tick
    case button
}

// MARK: - Haptics Helper
#if os(iOS)
import UIKit

class Haptics {
    static let shared = Haptics()
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    
    func perform(_ type: HapticType) {
        switch type {
        case .start:
            notification.notificationOccurred(.success)
        case .pause:
            impactMedium.impactOccurred()
        case .stop:
            notification.notificationOccurred(.warning)
        case .completion:
            notification.notificationOccurred(.success)
        case .tick:
            impactLight.impactOccurred(intensity: 0.3)
        case .button:
            impactLight.impactOccurred()
        }
    }
}

#elseif os(macOS)
import AppKit

class Haptics {
    static let shared = Haptics()
    
    func perform(_ type: HapticType) {
        let performer = NSHapticFeedbackManager.defaultPerformer
        
        switch type {
        case .start, .completion:
            performer.perform(.generic, performanceTime: .now)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                performer.perform(.generic, performanceTime: .now)
            }
        case .pause, .stop:
            performer.perform(.generic, performanceTime: .now)
        case .tick:
            performer.perform(.generic, performanceTime: .now)
        case .button:
            performer.perform(.generic, performanceTime: .now)
        }
    }
}

#elseif os(watchOS)
import WatchKit

class Haptics {
    static let shared = Haptics()
    
    func perform(_ type: HapticType) {
        let device = WKInterfaceDevice.current()
        
        switch type {
        case .start:
            device.play(.success)
        case .pause:
            device.play(.click)
        case .stop:
            device.play(.stop)
        case .completion:
            device.play(.success)
        case .tick:
            device.play(.click)
        case .button:
            device.play(.click)
        }
    }
}
#endif

// MARK: - AudioServices
#if os(iOS) || os(watchOS)
import AudioToolbox

func AudioServicesPlaySystemSound(_ soundID: SystemSoundID) {
    AudioToolbox.AudioServicesPlaySystemSound(soundID)
}
#endif
