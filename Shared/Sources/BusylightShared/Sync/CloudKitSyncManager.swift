import Foundation
import CloudKit
import SwiftData
import Combine
#if canImport(UIKit)
import UIKit
#endif

/// Manager para sincronización CloudKit entre dispositivos
@MainActor
public final class CloudKitSyncManager: ObservableObject {
    public static let shared = CloudKitSyncManager()
    
    @Published public var syncStatus: SyncStatus = .idle
    @Published public var lastSyncDate: Date?
    @Published public var isCloudKitAvailable = false
    
    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let privateDatabase: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    
    public enum SyncStatus: Sendable {
        case idle
        case syncing
        case success
        case failed(Error)
        
        public var isSyncing: Bool {
            if case .syncing = self { return true }
            return false
        }
    }
    
    private init() {
        self.container = CKContainer.default()
        self.publicDatabase = container.publicCloudDatabase
        self.privateDatabase = container.privateCloudDatabase
        
        checkCloudKitAvailability()
    }
    
    // MARK: - Availability Check
    
    private func checkCloudKitAvailability() {
        container.accountStatus { [weak self] status, error in
            Task { @MainActor in
                self?.isCloudKitAvailable = (status == .available)
            }
        }
    }
    
    // MARK: - Sync Methods
    
    public func syncAll() async {
        guard isCloudKitAvailable else { return }
        
        syncStatus = .syncing
        
        do {
            // Sync different record types
            try await syncSessions()
            try await syncWorkPatterns()
            try await syncSettings()
            try await syncHolidayCalendars()
            
            lastSyncDate = Date()
            syncStatus = .success
            
            // Reset success after delay
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    if case .success = self.syncStatus {
                        self.syncStatus = .idle
                    }
                }
            }
        } catch {
            syncStatus = .failed(error)
        }
    }
    
    private func syncSessions() async throws {
        // Implementation would fetch from CloudKit and merge with local
        // This is a simplified version
    }
    
    private func syncWorkPatterns() async throws {
        // Implementation for ML patterns
    }
    
    private func syncSettings() async throws {
        // Implementation for user settings
    }
    
    private func syncHolidayCalendars() async throws {
        // Implementation for holiday calendars
    }
    
    // MARK: - Push to CloudKit
    
    public func pushSession(_ session: PomodoroSession) async throws {
        guard isCloudKitAvailable else { return }
        
        let record = CKRecord(recordType: "PomodoroSession")
        record["id"] = session.id.uuidString
        record["startTime"] = session.startTime
        record["duration"] = session.duration
        record["type"] = session.type
        record["taskName"] = session.taskName
        record["completed"] = session.completed ? 1 : 0
        record["deviceID"] = SyncDevice.current.id
        
        _ = try await privateDatabase.save(record)
        session.isSynced = true
    }
    
    // MARK: - Subscribe to Changes
    
    public func subscribeToChanges() async throws {
        let subscription = CKDatabaseSubscription(subscriptionID: "all-changes")
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        _ = try await privateDatabase.save(subscription)
    }
}

// MARK: - Device Info

public struct SyncDevice: Sendable {
    public static let current = SyncDevice()
    
    public let id: String
    public let name: String
    public let platform: Platform
    
    public enum Platform: String, Sendable {
        case macOS
        case iOS
        case watchOS
    }
    
    private init() {
        // Generate persistent device ID
        if let existingID = UserDefaults.standard.string(forKey: "busylight.device.id") {
            self.id = existingID
        } else {
            let newID = UUID().uuidString
            UserDefaults.standard.set(newID, forKey: "busylight.device.id")
            self.id = newID
        }
        
        #if os(macOS)
        self.name = Host.current().localizedName ?? "Mac"
        self.platform = .macOS
        #elseif os(watchOS)
        self.name = WKInterfaceDevice.current().name
        self.platform = .watchOS
        #else
        self.name = UIDevice.current.name
        self.platform = .iOS
        #endif
    }
}

#if canImport(WatchKit)
import WatchKit
#endif
