//
//  CloudKitSyncManager.swift
//  BusylightShared
//
//  CloudKit synchronization for multi-platform
//

import Foundation
import CloudKit
import Combine

#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class CloudKitSyncManager: ObservableObject {
    public static let shared = CloudKitSyncManager()
    
    private let container: CKContainer
    private let database: CKDatabase
    
    @Published public var isSyncEnabled = true
    @Published public var lastSyncDate: Date?
    @Published public var isSyncing = false
    @Published public var syncError: Error?
    
    public let currentDeviceID: String
    
    private init() {
        self.container = CKContainer.default()
        self.database = container.publicCloudDatabase
        
        #if canImport(UIKit)
        self.currentDeviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #else
        self.currentDeviceID = UUID().uuidString
        #endif
    }
    
    public func savePomodoroState(_ state: PomodoroSyncState) async throws {
        guard isSyncEnabled else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let recordID = CKRecord.ID(recordName: "pomodoro_state_\(currentDeviceID)")
        let record = CKRecord(recordType: "PomodoroState", recordID: recordID)
        
        record["isRunning"] = state.isRunning
        record["isPaused"] = state.isPaused
        record["currentPhase"] = state.currentPhase.rawValue
        record["remainingSeconds"] = state.remainingSeconds
        record["currentSet"] = state.currentSet
        record["totalSets"] = state.totalSets
        record["workTimeMinutes"] = state.workTimeMinutes
        record["shortBreakMinutes"] = state.shortBreakMinutes
        record["longBreakMinutes"] = state.longBreakMinutes
        record["lastUpdated"] = Date()
        record["sourceDevice"] = currentDeviceID
        
        _ = try await database.save(record)
        lastSyncDate = Date()
    }
    
    public func fetchLatestPomodoroState() async throws -> PomodoroSyncState? {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "PomodoroState", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "lastUpdated", ascending: false)]
        
        let (matchResults, _) = try await database.records(matching: query, inZoneWith: nil, resultsLimit: 1)
        
        guard let result = matchResults.first?.1 else { return nil }
        let record = try result.get()
        
        guard let phaseString = record["currentPhase"] as? String,
              let phase = PomodoroPhase(rawValue: phaseString) else {
            return nil
        }
        
        return PomodoroSyncState(
            isRunning: record["isRunning"] as? Bool ?? false,
            isPaused: record["isPaused"] as? Bool ?? false,
            currentPhase: phase,
            remainingSeconds: record["remainingSeconds"] as? Int ?? 1500,
            currentSet: record["currentSet"] as? Int ?? 1,
            totalSets: record["totalSets"] as? Int ?? 4,
            workTimeMinutes: record["workTimeMinutes"] as? Int ?? 25,
            shortBreakMinutes: record["shortBreakMinutes"] as? Int ?? 5,
            longBreakMinutes: record["longBreakMinutes"] as? Int ?? 15,
            lastUpdated: record["lastUpdated"] as? Date ?? Date(),
            sourceDevice: record["sourceDevice"] as? String ?? ""
        )
    }
}

public extension Notification.Name {
    static let pomodoroStateDidChange = Notification.Name("PomodoroStateDidChange")
    static let cloudKitSyncCompleted = Notification.Name("CloudKitSyncCompleted")
}
