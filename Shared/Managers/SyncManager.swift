//
//  SyncManager.swift
//  Multi-platform synchronization manager
//

import Foundation
import Combine
import SwiftUI

// MARK: - Platform Type
enum PlatformType: String, Codable {
    case macOS = "macOS"
    case iOS = "iOS"
    case watchOS = "watchOS"
}

// MARK: - Sync Commands
enum SyncCommand: String, Codable {
    case startPomodoro = "start_pomodoro"
    case pausePomodoro = "pause_pomodoro"
    case stopPomodoro = "stop_pomodoro"
    case skipPhase = "skip_phase"
    case setLightColor = "set_light_color"
    case lightOff = "light_off"
    case requestSync = "request_sync"
}

// MARK: - Sync Manager
@MainActor
class SyncManager: ObservableObject {
    static let shared = SyncManager()
    
    // MARK: - Published Properties
    @Published var currentState: PomodoroSyncState = PomodoroSyncState()
    @Published var isSyncEnabled = true
    @Published var lastSyncDate: Date?
    @Published var isSyncing = false
    @Published var connectedDevices: [String] = []
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    private let cloudKitManager = CloudKitManager.shared
    
    // Platform detection
    let currentPlatform: PlatformType = {
        #if os(macOS)
        return .macOS
        #elseif os(iOS)
        return .iOS
        #elseif os(watchOS)
        return .watchOS
        #endif
    }()
    
    // Device has hardware control (macOS only)
    var hasHardwareControl: Bool {
        currentPlatform == .macOS
    }
    
    private init() {
        setupSyncMonitoring()
    }
    
    // MARK: - Setup
    private func setupSyncMonitoring() {
        // Listen for local notifications
        NotificationCenter.default.publisher(for: .pomodoroStateDidChange)
            .sink { [weak self] _ in
                Task {
                    await self?.syncToCloud()
                }
            }
            .store(in: &cancellables)
        
        // Periodic sync every 10 seconds when running
        syncTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchFromCloud()
            }
        }
    }
    
    // MARK: - Sync Methods
    func syncToCloud() async {
        guard isSyncEnabled else { return }
        
        do {
            try await cloudKitManager.savePomodoroState(currentState)
            lastSyncDate = Date()
            NotificationCenter.default.post(name: .cloudKitSyncCompleted, object: nil)
        } catch {
            print("❌ Failed to sync to CloudKit: \(error)")
        }
    }
    
    func fetchFromCloud() async {
        guard isSyncEnabled else { return }
        
        do {
            if let state = try await cloudKitManager.fetchLatestPomodoroState() {
                // Only update if the fetched state is newer
                if state.lastUpdated > currentState.lastUpdated && state.sourceDevice != cloudKitManager.currentDeviceID {
                    await MainActor.run {
                        self.currentState = state
                        self.lastSyncDate = Date()
                    }
                    NotificationCenter.default.post(name: .cloudKitSyncCompleted, object: state)
                }
            }
        } catch {
            print("❌ Failed to fetch from CloudKit: \(error)")
        }
    }
    
    // MARK: - State Updates
    func updateState(
        isRunning: Bool? = nil,
        isPaused: Bool? = nil,
        currentPhase: PomodoroPhase? = nil,
        remainingSeconds: Int? = nil,
        currentSet: Int? = nil,
        totalSets: Int? = nil
    ) {
        currentState = PomodoroSyncState(
            isRunning: isRunning ?? currentState.isRunning,
            isPaused: isPaused ?? currentState.isPaused,
            currentPhase: currentPhase ?? currentState.currentPhase,
            remainingSeconds: remainingSeconds ?? currentState.remainingSeconds,
            currentSet: currentSet ?? currentState.currentSet,
            totalSets: totalSets ?? currentState.totalSets,
            workTimeMinutes: currentState.workTimeMinutes,
            shortBreakMinutes: currentState.shortBreakMinutes,
            longBreakMinutes: currentState.longBreakMinutes,
            lastUpdated: Date(),
            sourceDevice: cloudKitManager.currentDeviceID
        )
        
        // Sync immediately on state change
        Task {
            await syncToCloud()
        }
        
        NotificationCenter.default.post(name: .pomodoroStateDidChange, object: currentState)
    }
    
    // MARK: - Command Methods
    func sendCommand(_ command: SyncCommand, payload: [String: Any]? = nil) {
        var userInfo: [String: Any] = ["command": command.rawValue]
        if let payload = payload {
            userInfo.merge(payload) { _, new in new }
        }
        
        NotificationCenter.default.post(name: .syncCommandReceived, object: nil, userInfo: userInfo)
        
        // If this is a macOS device, handle hardware commands
        if hasHardwareControl {
            handleHardwareCommand(command, payload: payload)
        }
    }
    
    private func handleHardwareCommand(_ command: SyncCommand, payload: [String: Any]?) {
        #if os(macOS)
        // This will be implemented in the macOS-specific BusylightManager
        NotificationCenter.default.post(
            name: .hardwareCommandReceived,
            object: nil,
            userInfo: ["command": command.rawValue, "payload": payload ?? [:]]
        )
        #endif
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let syncCommandReceived = Notification.Name("SyncCommandReceived")
    static let hardwareCommandReceived = Notification.Name("HardwareCommandReceived")
    static let deviceStatusChanged = Notification.Name("DeviceStatusChanged")
}
