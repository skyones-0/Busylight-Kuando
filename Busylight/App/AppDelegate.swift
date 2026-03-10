//
//  AppDelegate.swift
//  Busylight
//
//  Manages macOS-specific app lifecycle events, dock visibility,
//  and menu bar status item with popover/ detached window support.
//
//  Relationships:
//  - Used by: ContentView.swift (syncs settings), MenuBarView.swift (visibility toggles)
//  - Manages: BusylightManager (shared instance)
//  - See: SettingsView.swift for dock/menubar toggle UI
//

import SwiftUI
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    var busylight = BusylightManager()
    
    // Ventana alternativa para modo pantalla completa
    var detachedWindow: NSWindow?
    
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
        
        // Configure shared PomodoroManager with busylight
        PomodoroManager.shared.configure(with: busylight)
        
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
        
        // Configurar el popover
        popover.contentSize = NSSize(width: 220, height: 400)
        popover.behavior = .transient
        popover.animates = true
        
        let hostingController = NSHostingController(rootView: menuView)
        popover.contentViewController = hostingController
        
        statusItem?.button?.action = #selector(toggleMenu)
        statusItem?.button?.target = self
        
        BusylightLogger.shared.info("AppDelegate - setupMenuBar completado")
    }
    
    @objc func toggleMenu() {
        BusylightLogger.shared.debug("AppDelegate - toggleMenu")
        
        // Si ya hay una ventana flotante, cerrarla
        if let window = detachedWindow, window.isVisible {
            BusylightLogger.shared.debug("Cerrando ventana flotante")
            window.close()
            detachedWindow = nil
            return
        }
        
        // Si el popover está visible, cerrarlo
        if popover.isShown {
            BusylightLogger.shared.debug("Cerrando popover")
            popover.performClose(nil)
            return
        }
        
        // Determinar si estamos en modo pantalla completa
        if isAnyAppInFullScreen() {
            BusylightLogger.shared.debug("Detectado modo pantalla completa, usando ventana flotante")
            showDetachedWindow()
        } else {
            BusylightLogger.shared.debug("Abriendo popover normal")
            showPopover()
        }
    }
    
    private func isAnyAppInFullScreen() -> Bool {
        // Verificar si alguna ventana está en modo pantalla completa
        for window in NSApp.windows {
            if window.styleMask.contains(.fullScreen) {
                return true
            }
        }
        
        // Verificar si estamos en un espacio de pantalla completa
        // Esto es una heurística: si la ventana principal no está visible
        // y el menú está activo, probablemente estemos en pantalla completa
        if let screen = NSScreen.main {
            let menuBarHeight = NSApp.mainMenu?.menuBarHeight ?? 24
            let visibleFrame = screen.visibleFrame
            let fullFrame = screen.frame
            
            // Si el frame visible es significativamente menor que el frame completo
            // (más allá del menú), podría ser pantalla completa
            let heightDiff = fullFrame.height - visibleFrame.height
            if heightDiff > menuBarHeight + 5 {
                return true
            }
        }
        
        return false
    }
    
    private func showPopover() {
        guard let button = statusItem?.button else { return }
        
        NSApp.activate(ignoringOtherApps: true)
        
        // Configurar el popover para que aparezca en todos los espacios
        if let contentView = popover.contentViewController?.view {
            contentView.wantsLayer = true
        }
        
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
    
    private func showDetachedWindow() {
        guard let button = statusItem?.button else { return }
        
        // Obtener la posición del botón en pantalla
        let buttonRect = button.window?.convertToScreen(button.frame) ?? NSRect(x: 0, y: 0, width: 22, height: 22)
        
        let menuView = MenuBarView(busylight: busylight)
            .environmentObject(self)
        
        let hostingController = NSHostingController(rootView: menuView)
        
        // Crear ventana flotante tipo "popover"
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 400),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.contentViewController = hostingController
        window.level = .popUpMenu
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.animationBehavior = .utilityWindow
        
        // Posicionar la ventana debajo del botón
        let windowX = buttonRect.midX - 110 // Centrar horizontalmente (220/2)
        let windowY = buttonRect.minY - 405 // Debajo del botón
        window.setFrameOrigin(NSPoint(x: windowX, y: windowY))
        
        // Asegurar que esté en el espacio actual
        window.collectionBehavior = [.canJoinAllSpaces, .transient]
        
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        
        detachedWindow = window
        
        // Cerrar cuando se hace click fuera
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let window = self.detachedWindow else { return }
            let location = event.locationInWindow
            let windowFrame = window.frame
            if !windowFrame.contains(location) {
                DispatchQueue.main.async {
                    window.close()
                    self.detachedWindow = nil
                }
            }
        }
    }
    
    private func closeAllPopovers() {
        if popover.isShown {
            popover.performClose(nil)
        }
        if let window = detachedWindow, window.isVisible {
            window.close()
            detachedWindow = nil
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
