//
//  BusylightMacApp.swift
//  macOS App Entry Point with Shared Framework
//

import SwiftUI
import SwiftData
import AppKit

@main
struct BusylightMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    
    // SwiftData container
    let container: ModelContainer
    
    init() {
        print("=== Busylight macOS App Iniciada ===")
        
        // Initialize SwiftData container
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
        
        // Listen for window focus
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
            MacContentView()
                .environmentObject(appDelegate)
                .modelContainer(container)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 650)
        .windowResizability(.contentSize)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                // Optional: turn off light when app goes to background
                // appDelegate.busylight.off()
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
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem?
    var popover = NSPopover()
    var busylight = MacBusylightManager.shared
    
    // Window for full-screen mode
    var detachedWindow: NSWindow?
    
    @AppStorage("showInDock") var showInDock = true {
        didSet {
            updateDockVisibility()
        }
    }
    
    @AppStorage("showInMenuBar") var showInMenuBar = true {
        didSet {
            updateMenuBarVisibility()
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("✅ macOS AppDelegate - applicationDidFinishLaunching")
        
        // Configure PomodoroManager with hardware
        UnifiedPomodoroManager.shared
        
        setupMenuBar()
        updateDockVisibility()
        
        // Listen for hardware commands from other devices
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHardwareCommand(_:)),
            name: .hardwareCommandReceived,
            object: nil
        )
    }
    
    // MARK: - Menu Bar
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "lightbulb.fill", accessibilityDescription: "Busylight")
        }
        
        let menuView = MacMenuBarView()
            .environmentObject(self)
        
        popover.contentSize = NSSize(width: 260, height: 450)
        popover.behavior = .transient
        popover.animates = true
        
        let hostingController = NSHostingController(rootView: menuView)
        popover.contentViewController = hostingController
        
        statusItem?.button?.action = #selector(toggleMenu)
        statusItem?.button?.target = self
    }
    
    @objc func toggleMenu() {
        // Close detached window if open
        if let window = detachedWindow, window.isVisible {
            window.close()
            detachedWindow = nil
            return
        }
        
        // Close popover if shown
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        
        // Check if in full-screen mode
        if isAnyAppInFullScreen() {
            showDetachedWindow()
        } else {
            showPopover()
        }
    }
    
    private func isAnyAppInFullScreen() -> Bool {
        for window in NSApp.windows {
            if window.styleMask.contains(.fullScreen) {
                return true
            }
        }
        return false
    }
    
    private func showPopover() {
        guard let button = statusItem?.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
    
    private func showDetachedWindow() {
        guard let button = statusItem?.button else { return }
        let buttonRect = button.window?.convertToScreen(button.frame) ?? NSRect(x: 0, y: 0, width: 22, height: 22)
        
        let menuView = MacMenuBarView()
            .environmentObject(self)
        
        let hostingController = NSHostingController(rootView: menuView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 450),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.contentViewController = hostingController
        window.level = .popUpMenu
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        
        let windowX = buttonRect.midX - 130
        let windowY = buttonRect.minY - 455
        window.setFrameOrigin(NSPoint(x: windowX, y: windowY))
        
        window.collectionBehavior = [.canJoinAllSpaces, .transient]
        window.makeKeyAndOrderFront(nil)
        
        detachedWindow = window
        
        // Close on outside click
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
    
    // MARK: - Hardware Commands
    @objc func handleHardwareCommand(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let commandString = userInfo["command"] as? String,
              let command = SyncCommand(rawValue: commandString) else { return }
        
        DispatchQueue.main.async { [weak self] in
            switch command {
            case .setLightColor:
                if let payload = userInfo["payload"] as? [String: Any],
                   let colorString = payload["color"] as? String,
                   let color = LightColor(rawValue: colorString) {
                    self?.busylight.setColor(color)
                }
            case .lightOff:
                self?.busylight.off()
            default:
                break
            }
        }
    }
    
    // MARK: - Visibility
    func updateDockVisibility() {
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
    }
    
    func updateMenuBarVisibility() {
        statusItem?.isVisible = showInMenuBar
    }
}

// MARK: - Window Helpers
func bringWindowToFront() {
    NSApp.activate(ignoringOtherApps: true)
    NSApp.unhide(nil)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        for window in NSApp.windows {
            guard window.level == .normal || window.level == .floating || window.level == .modalPanel else {
                continue
            }
            guard window.frame.width > 200 && window.frame.height > 200 else {
                continue
            }
            
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            return
        }
    }
}

extension Notification.Name {
    static let openMainWindow = Notification.Name("OpenMainWindow")
}
