//
//  BusylightIOSApp.swift
//  BusylightIOS
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct BusylightIOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
            IOSContentView()
                .modelContainer(container)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Notifications: \(granted)")
        }
        return true
    }
}
