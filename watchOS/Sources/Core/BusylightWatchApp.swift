//
//  BusylightWatchApp.swift
//  BusylightWatch
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct BusylightWatchApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let container: ModelContainer
    
    init() {
        let schema = Schema([PomodoroSession.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to initialize SwiftData: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .modelContainer(container)
        }
    }
}

class AppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            print("Notifications: \(granted)")
        }
    }
}
