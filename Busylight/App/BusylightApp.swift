import SwiftUI
import AppKit
import SwiftData

@main
struct BusylightApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    @AppStorage("appearanceMode") private var appearanceMode = 0
    
    // SwiftData container with CloudKit
    let container: ModelContainer
    
    init() {
        BusylightLogger.shared.info("=== Busylight App Iniciada ===")
        
        // Initialize SwiftData container
        let schema = Schema([
            PomodoroSession.self,
            MLWorkPattern.self,
            MLConfiguration.self,
            HolidayCalendar.self,
            CalendarConfiguration.self,
            CalendarEvent.self,
            CalendarTask.self,
            AppSettings.self,
            DayCategoryFeedback.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
            BusylightLogger.shared.info("SwiftData container initialized")
            
            // Initialize ML Manager with shared container
            MLScheduleManager.resetShared(container: container)
            
        } catch {
            fatalError("Failed to initialize SwiftData: \(error)")
        }
        
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
        WindowGroup("Busylight") {
            ContentView()
                .environmentObject(appDelegate)
                .environmentObject(LocationManager.shared)
                .preferredColorScheme(colorScheme)
                .modelContainer(container)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 800, height: 600)
        .windowResizability(.contentSize)
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                appDelegate.busylight.off()
                BusylightLogger.shared.debug("App en background - luz apagada")
            }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Busylight") {
                    NotificationCenter.default.post(name: .openMainWindow, object: nil)
                }
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

// Función global mejorada para traer ventana al frente
func bringWindowToFront() {
    BusylightLogger.shared.debug("Ejecutando bringWindowToFront")
    
    NSApp.activate(ignoringOtherApps: true)
    NSApp.unhide(nil)
    
    // Pequeña demora para asegurar que la ventana existe
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        var foundWindow = false
        
        // Primero buscar entre todas las ventanas de la aplicación
        for window in NSApp.windows {
            BusylightLogger.shared.debug("Revisando ventana: level=\(window.level.rawValue), isVisible=\(window.isVisible), isMiniaturized=\(window.isMiniaturized), title=\(window.title)")
            
            // Ignorar ventanas de tipo popover, menú, etc.
            guard window.level == .normal || window.level == .floating || window.level == .modalPanel else {
                continue
            }
            
            // Ignorar ventanas muy pequeñas (como el popover del menu bar)
            guard window.frame.width > 200 && window.frame.height > 200 else {
                continue
            }
            
            foundWindow = true
            
            // Si la ventana está miniaturizada, la desminiaturizamos
            if window.isMiniaturized {
                window.deminiaturize(nil)
                window.makeKeyAndOrderFront(nil)
                BusylightLogger.shared.info("Ventana desminiaturizada y traída al frente")
                return
            }
            
            // Si la ventana existe, asegurar que esté visible y al frente
            window.alphaValue = 1.0
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            
            // Si estaba oculta, mostrarla
            if !window.isVisible {
                BusylightLogger.shared.info("Ventana estaba oculta, mostrándola")
            } else {
                BusylightLogger.shared.info("Ventana traída al frente exitosamente")
            }
            return
        }
        
        // Si no encontramos ventana, intentar crear una nueva
        if !foundWindow {
            BusylightLogger.shared.info("No se encontró ventana válida, intentando crear nueva...")
            createNewWindow()
        }
    }
}

// Función para crear una nueva ventana si no existe ninguna
private func createNewWindow() {
    // Método 1: Intentar usar el menú File > New Window
    if tryMenuNewWindow() {
        return
    }
    
    // Método 2: Crear ventana manualmente
    BusylightLogger.shared.info("Creando ventana manualmente...")
    
    guard let appDelegate = NSApp.delegate as? AppDelegate else {
        BusylightLogger.shared.info("No se pudo obtener AppDelegate")
        return
    }
    
    let contentView = ContentView()
        .environmentObject(appDelegate)
    
    let hostingController = NSHostingController(rootView: contentView)
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
        styleMask: [.titled, .closable, .miniaturizable, .resizable],
        backing: .buffered,
        defer: false
    )
    
    window.contentViewController = hostingController
    window.title = "Busylight"
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.isMovableByWindowBackground = true
    window.center()
    window.makeKeyAndOrderFront(nil)
    
    BusylightLogger.shared.info("Nueva ventana creada y mostrada")
}

// Intenta usar el menú File > New Window
private func tryMenuNewWindow() -> Bool {
    guard let menu = NSApp.mainMenu else { return false }
    
    // Buscar menú File (en inglés o español)
    let fileMenuTitles = ["File", "Archivo"]
    guard let fileMenuItem = menu.items.first(where: { fileMenuTitles.contains($0.title) }) else {
        return false
    }
    
    guard let submenu = fileMenuItem.submenu else { return false }
    
    // Buscar item New Window
    let newWindowTitles = ["New", "Nuevo", "New Window", "Nueva Ventana"]
    guard let newWindowItem = submenu.items.first(where: { item in
        newWindowTitles.contains(where: { item.title.contains($0) })
    }) else {
        return false
    }
    
    guard let action = newWindowItem.action else { return false }
    
    BusylightLogger.shared.info("Ejecutando comando New Window desde menú")
    NSApp.sendAction(action, to: newWindowItem.target, from: nil)
    return true
}

extension Notification.Name {
    static let openMainWindow = Notification.Name("OpenMainWindow")
}

// MARK: - Default Settings

private func initializeDefaultSettings() {
    // This runs after container is created
    // Settings will be created on-demand when accessed
    BusylightLogger.shared.info("Default settings initialization ready")
}
