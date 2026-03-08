//
//  BusylightIOSApp.swift
//  iOS App Entry Point
//

import SwiftUI
import SwiftData
import ActivityKit
import UserNotifications

@main
struct BusylightIOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // SwiftData container
    let container: ModelContainer
    
    init() {
        // Initialize SwiftData
        let schema = Schema([PomodoroSession.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
            print("✅ SwiftData container initialized")
        } catch {
            fatalError("Failed to initialize SwiftData: \(error)")
        }
        
        // Request notification permissions
        requestNotificationPermissions()
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error)")
            } else {
                print("✅ Notification permission: \(granted)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            IOSContentView()
                .modelContainer(container)
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("✅ Busylight iOS App Launched")
        return true
    }
    
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: connectingSceneSession.configuration.name,
            sessionRole: connectingSceneSession.role
        )
        return configuration
    }
}
