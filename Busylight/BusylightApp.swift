import SwiftUI

@main
struct BusylightApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    @AppStorage("appearanceMode") private var appearanceMode = 0
    
    init() {
        BusylightLogger.shared.info("=== Busylight App Iniciada ===")
        
        // Escuchar notificación para traer ventana al frente
        NotificationCenter.default.addObserver(
            forName: .openMainWindow,
            object: nil,
            queue: .main
        ) { _ in
            bringWindowToFront()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate)
                .preferredColorScheme(colorScheme) // ← Aplicar tema aquí
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 700, height: 500)
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                appDelegate.busylight.off()
                BusylightLogger.shared.debug("App en background - luz apagada")
            }
        }
    }
    
    // Computed property para convertir Int a ColorScheme
    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil // System
        }
    }
}

// Función global
private func bringWindowToFront() {
    NSApp.activate(ignoringOtherApps: true)
    NSApp.unhide(nil)
    
    for window in NSApp.windows {
        if window.isVisible {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            BusylightLogger.shared.debug("Ventana traída al frente")
            return
        }
    }
}

extension Notification.Name {
    static let openMainWindow = Notification.Name("OpenMainWindow")
}
