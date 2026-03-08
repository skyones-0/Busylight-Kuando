//
//  SettingsView.swift
//  Busylight iOS
//

import SwiftUI
import SwiftData
import BusylightShared

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @StateObject private var syncManager = CloudKitSyncManager.shared
    
    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Timer Durations") {
                    Stepper("Focus: \(Int(userSettings.focusDuration / 60)) min",
                            value: Binding(
                                get: { Int(userSettings.focusDuration / 60) },
                                set: { updateSettings { $0.focusDuration = TimeInterval($1 * 60) } }
                            ), in: 1...60)
                    
                    Stepper("Short Break: \(Int(userSettings.shortBreakDuration / 60)) min",
                            value: Binding(
                                get: { Int(userSettings.shortBreakDuration / 60) },
                                set: { updateSettings { $0.shortBreakDuration = TimeInterval($1 * 60) } }
                            ), in: 1...30)
                    
                    Stepper("Long Break: \(Int(userSettings.longBreakDuration / 60)) min",
                            value: Binding(
                                get: { Int(userSettings.longBreakDuration / 60) },
                                set: { updateSettings { $0.longBreakDuration = TimeInterval($1 * 60) } }
                            ), in: 5...60)
                }
                
                Section("Work Hours") {
                    DatePicker("Start",
                               selection: Binding(
                                get: { userSettings.workStartTime },
                                set: { newDate in
                                    let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                    updateSettings {
                                        $0.workStartHour = comps.hour ?? 9
                                        $0.workStartMinute = comps.minute ?? 0
                                    }
                                }
                               ),
                               displayedComponents: .hourAndMinute)
                    
                    DatePicker("End",
                               selection: Binding(
                                get: { userSettings.workEndTime },
                                set: { newDate in
                                    let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                    updateSettings {
                                        $0.workEndHour = comps.hour ?? 17
                                        $0.workEndMinute = comps.minute ?? 0
                                    }
                                }
                               ),
                               displayedComponents: .hourAndMinute)
                }
                
                Section("Cloud Sync") {
                    HStack {
                        Text("Status")
                        Spacer()
                        SyncStatusView(status: syncManager.syncStatus)
                    }
                    
                    if let lastSync = syncManager.lastSyncDate {
                        Text("Last sync: \(lastSync, style: .relative) ago")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button("Sync Now") {
                        Task {
                            await syncManager.syncAll()
                        }
                    }
                    .disabled(syncManager.syncStatus.isSyncing || !syncManager.isCloudKitAvailable)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func updateSettings(_ update: (UserSettings, Int) -> Void, value: Int) {
        let settings = userSettings
        update(settings, value)
        settings.modifiedAt = Date()
        settings.isSynced = false
        try? modelContext.save()
    }
    
    private func updateSettings(_ update: (UserSettings) -> Void) {
        let settings = userSettings
        update(settings)
        settings.modifiedAt = Date()
        settings.isSynced = false
        try? modelContext.save()
    }
}

struct SyncStatusView: View {
    let status: CloudKitSyncManager.SyncStatus
    
    var body: some View {
        HStack(spacing: 6) {
            switch status {
            case .idle:
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                Text("Ready")
                    .foregroundStyle(.secondary)
            case .syncing:
                ProgressView()
                    .controlSize(.small)
                Text("Syncing...")
                    .foregroundStyle(.blue)
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Synced")
                    .foregroundStyle(.green)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                Text("Failed")
                    .foregroundStyle(.red)
            }
        }
        .font(.callout)
    }
}
