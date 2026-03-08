//
//  BusylightIOSApp.swift
//  Busylight iOS
//

import SwiftUI
import SwiftData
import BusylightShared

@main
struct BusylightIOSApp: App {
    let container: ModelContainer
    
    init() {
        // Initialize SwiftData container with shared models
        let schema = Schema([
            PomodoroSession.self,
            MLWorkPattern.self,
            MLConfiguration.self,
            HolidayCalendar.self,
            UserSettings.self,
            WorkProfile.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            IOSContentView()
        }
        .modelContainer(container)
    }
}

// MARK: - Main Content View

struct IOSContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var syncManager = CloudKitSyncManager.shared
    
    var body: some View {
        TabView {
            PomodoroView()
                .tabItem {
                    Label("Pomodoro", systemImage: "timer")
                }
            
            SessionsView()
                .tabItem {
                    Label("History", systemImage: "chart.bar")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .task {
            await syncManager.syncAll()
        }
    }
}
