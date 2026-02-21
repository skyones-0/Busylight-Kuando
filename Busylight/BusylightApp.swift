import SwiftUI

@main
struct BusylightApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 700, height: 500)
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                appDelegate.busylight.off()
                
            }
        
        }
    }
    
    private func bringWindowToFront() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.unhide(nil)
        
        // Traer ventana al frente
        for window in NSApp.windows {
            if window.isVisible {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                return
            }
        }
    }
}

extension Notification.Name {
    static let openMainWindow = Notification.Name("OpenMainWindow")
}
