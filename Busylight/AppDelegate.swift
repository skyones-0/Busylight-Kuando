import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    var busylight = BusylightManager()
    
    @Published var showInDock = true {
        didSet {
            BusylightLogger.shared.info("AppDelegate: showInDock cambiado a \(showInDock)")
            updateDockVisibility()
        }
    }
    @Published var showInMenuBar = true {
        didSet {
            BusylightLogger.shared.info("AppDelegate: showInMenuBar cambiado a \(showInMenuBar)")
            updateMenuBarVisibility()
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        BusylightLogger.shared.info("AppDelegate - applicationDidFinishLaunching")
        setupMenuBar()
        updateDockVisibility()
    }
    
    func setupMenuBar() {
        BusylightLogger.shared.info("AppDelegate - setupMenuBar iniciando")
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "lightbulb.fill", accessibilityDescription: "Busylight")
        }
        
        let menuView = MenuBarView(busylight: busylight)
            .environmentObject(self)
        
        popover.contentSize = NSSize(width: 300, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: menuView)
        
        statusItem?.button?.action = #selector(togglePopover)
        statusItem?.button?.target = self
        
        BusylightLogger.shared.info("AppDelegate - setupMenuBar completado")
    }
    
    @objc func togglePopover() {
        BusylightLogger.shared.debug("AppDelegate - togglePopover")
        if let button = statusItem?.button {
            if popover.isShown {
                BusylightLogger.shared.debug("Cerrando popover")
                popover.performClose(nil)
            } else {
                BusylightLogger.shared.debug("Abriendo popover")
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    func updateDockVisibility() {
        BusylightLogger.shared.debug("AppDelegate - updateDockVisibility: \(showInDock)")
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
    }
    
    func updateMenuBarVisibility() {
        BusylightLogger.shared.debug("AppDelegate - updateMenuBarVisibility: \(showInMenuBar)")
        statusItem?.isVisible = showInMenuBar
    }
    
    @objc func showMainWindow() {
        NotificationCenter.default.post(name: .openMainWindow, object: nil)
        BusylightLogger.shared.info("Solicitada apertura de ventana desde menú bar")
    }
}
