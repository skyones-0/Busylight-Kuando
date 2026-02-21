//import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    var busylight = BusylightManager() 
    
    @Published var showInDock = true {
        didSet { updateDockVisibility() }
    }
    @Published var showInMenuBar = true {
        didSet { updateMenuBarVisibility() }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        updateDockVisibility()
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "lightbulb.fill", accessibilityDescription: "Busylight")
        }
        
        let menuView = MenuBarView()
            .environmentObject(self)
        
        popover.contentSize = NSSize(width: 300, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: menuView)
        
        statusItem?.button?.action = #selector(togglePopover)
        statusItem?.button?.target = self
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    func updateDockVisibility() {
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
    }
    
    func updateMenuBarVisibility() {
        statusItem?.isVisible = showInMenuBar
    }
}
