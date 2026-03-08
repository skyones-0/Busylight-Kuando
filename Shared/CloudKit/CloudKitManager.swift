//
//  CloudKitManager.swift
//  Shared CloudKit synchronization for Busylight
//

import Foundation
import CloudKit
import Combine
import SwiftData

// MARK: - Sync Record Types
enum BusylightRecordType: String {
    case pomodoroState = "PomodoroState"
    case session = "PomodoroSession"
    case deviceStatus = "DeviceStatus"
    case userPreference = "UserPreference"
}

// MARK: - Sync Keys
enum SyncKeys: String {
    case isRunning = "isRunning"
    case isPaused = "isPaused"
    case currentPhase = "currentPhase"
    case remainingSeconds = "remainingSeconds"
    case currentSet = "currentSet"
    case totalSets = "totalSets"
    case workTimeMinutes = "workTimeMinutes"
    case shortBreakMinutes = "shortBreakMinutes"
    case longBreakMinutes = "longBreakMinutes"
    case lastUpdated = "lastUpdated"
    case deviceID = "deviceID"
    case sourceDevice = "sourceDevice"
    case lightColor = "lightColor"
    case lightStatus = "lightStatus"
}

// MARK: - CloudKit Manager
@MainActor
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    private let container: CKContainer
    private let database: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isSyncEnabled = true
    @Published var lastSyncDate: Date?
    @Published var isSyncing = false
    @Published var syncError: Error?
    
    // Current device identifier
    let currentDeviceID: String
    
    private init() {
        // Use shared CloudKit container
        self.container = CKContainer.default()
        self.database = container.publicCloudDatabase
        self.currentDeviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        setupSubscriptions()
    }
    
    // MARK: - Setup
    private func setupSubscriptions() {
        // Monitor iCloud account status
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = error
                    print("CloudKit account error: \(error)")
                }
                print("CloudKit account status: \(status.rawValue)")
            }
        }
    }
    
    // MARK: - Save Pomodoro State
    func savePomodoroState(_ state: PomodoroSyncState) async throws {
        guard isSyncEnabled else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let recordID = CKRecord.ID(recordName: "pomodoro_\(currentDeviceID)")
        let record = CKRecord(recordType: BusylightRecordType.pomodoroState.rawValue, recordID: recordID)
        
        // Set values
        record[SyncKeys.isRunning.rawValue] = state.isRunning
        record[SyncKeys.isPaused.rawValue] = state.isPaused
        record[SyncKeys.currentPhase.rawValue] = state.currentPhase.rawValue
        record[SyncKeys.remainingSeconds.rawValue] = state.remainingSeconds
        record[SyncKeys.currentSet.rawValue] = state.currentSet
        record[SyncKeys.totalSets.rawValue] = state.totalSets
        record[SyncKeys.workTimeMinutes.rawValue] = state.workTimeMinutes
        record[SyncKeys.shortBreakMinutes.rawValue] = state.shortBreakMinutes
        record[SyncKeys.longBreakMinutes.rawValue] = state.longBreakMinutes
        record[SyncKeys.lastUpdated.rawValue] = Date()
        record[SyncKeys.sourceDevice.rawValue] = currentDeviceID
        
        do {
            let savedRecord = try await database.save(record)
            lastSyncDate = Date()
            print("✅ Pomodoro state saved to CloudKit: \(savedRecord.recordID.recordName)")
        } catch {
            syncError = error
            throw error
        }
    }
    
    // MARK: - Fetch Pomodoro State
    func fetchPomodoroState() async throws -> PomodoroSyncState? {
        let recordID = CKRecord.ID(recordName: "pomodoro_\(currentDeviceID)")
        
        do {
            let record = try await database.record(for: recordID)
            return PomodoroSyncState(from: record)
        } catch {
            if let ckError = error as? CKError, ckError.code == .unknownItem {
                return nil // No record exists yet
            }
            throw error
        }
    }
    
    // MARK: - Fetch Latest State (from any device)
    func fetchLatestPomodoroState() async throws -> PomodoroSyncState? {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: BusylightRecordType.pomodoroState.rawValue, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: SyncKeys.lastUpdated.rawValue, ascending: false)]
        
        let (results, _) = try await database.records(matching: query, inZoneWith: nil, resultsLimit: 1)
        
        guard let record = results.first?.1 else { return nil }
        
        do {
            let stateRecord = try record.get()
            return PomodoroSyncState(from: stateRecord)
        } catch {
            throw error
        }
    }
    
    // MARK: - Delete State
    func deletePomodoroState() async throws {
        let recordID = CKRecord.ID(recordName: "pomodoro_\(currentDeviceID)")
        try await database.deleteRecord(withID: recordID)
    }
    
    // MARK: - Subscribe to Changes
    func subscribeToChanges() async throws {
        let subscription = CKQuerySubscription(
            recordType: BusylightRecordType.pomodoroState.rawValue,
            predicate: NSPredicate(value: true),
            subscriptionID: "pomodoro_changes",
            options: .firesOnRecordUpdate
        )
        
        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification
        
        do {
            _ = try await database.save(subscription)
            print("✅ Subscribed to CloudKit changes")
        } catch {
            if let ckError = error as? CKError, ckError.code == .serverRecordChanged {
                // Subscription already exists
                return
            }
            throw error
        }
    }
}

// MARK: - Pomodoro Sync State
struct PomodoroSyncState: Codable, Equatable {
    let isRunning: Bool
    let isPaused: Bool
    let currentPhase: PomodoroPhase
    let remainingSeconds: Int
    let currentSet: Int
    let totalSets: Int
    let workTimeMinutes: Int
    let shortBreakMinutes: Int
    let longBreakMinutes: Int
    let lastUpdated: Date
    let sourceDevice: String
    
    init(
        isRunning: Bool = false,
        isPaused: Bool = false,
        currentPhase: PomodoroPhase = .work,
        remainingSeconds: Int = 25 * 60,
        currentSet: Int = 1,
        totalSets: Int = 3,
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
    
    init?(from record: CKRecord) {
        guard let isRunning = record[SyncKeys.isRunning.rawValue] as? Bool,
              let currentPhaseString = record[SyncKeys.currentPhase.rawValue] as? String,
              let currentPhase = PomodoroPhase(rawValue: currentPhaseString) else {
            return nil
        }
        
        self.isRunning = isRunning
        self.isPaused = record[SyncKeys.isPaused.rawValue] as? Bool ?? false
        self.currentPhase = currentPhase
        self.remainingSeconds = record[SyncKeys.remainingSeconds.rawValue] as? Int ?? 25 * 60
        self.currentSet = record[SyncKeys.currentSet.rawValue] as? Int ?? 1
        self.totalSets = record[SyncKeys.totalSets.rawValue] as? Int ?? 3
        self.workTimeMinutes = record[SyncKeys.workTimeMinutes.rawValue] as? Int ?? 25
        self.shortBreakMinutes = record[SyncKeys.shortBreakMinutes.rawValue] as? Int ?? 5
        self.longBreakMinutes = record[SyncKeys.longBreakMinutes.rawValue] as? Int ?? 15
        self.lastUpdated = record[SyncKeys.lastUpdated.rawValue] as? Date ?? Date()
        self.sourceDevice = record[SyncKeys.sourceDevice.rawValue] as? String ?? ""
    }
}

// MARK: - Sync Events
extension Notification.Name {
    static let pomodoroStateDidChange = Notification.Name("PomodoroStateDidChange")
    static let cloudKitSyncCompleted = Notification.Name("CloudKitSyncCompleted")
}
