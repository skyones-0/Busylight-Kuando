//
//  ContentView.swift
//  Busylight
//
//  Main content view with sidebar navigation
//  Refactored: Split into feature modules with glassmorphism design
//

import SwiftUI
import SwiftData
import EventKit

// MARK: - User Interaction Tracking Extension
extension View {
    func logTap(_ action: String, file: String = #file, function: String = #function) -> some View {
        UserInteractionLogger.shared.navigation(to: action)
        return self
    }
}

struct ContentView: View {
    @StateObject private var busylight = BusylightManager()
    @EnvironmentObject var appDelegate: AppDelegate
    @State private var selectedItem: SidebarItem = .pomodoro
    
    var body: some View {
        NavigationSplitView {
            // Sidebar con glassmorphism
            ZStack {
                // Background
                MeshGradientBackground()
                
                // Sidebar content
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange.opacity(0.8), .red.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .shadow(color: .orange.opacity(0.4), radius: 10, x: 0, y: 4)
                            
                            Image(systemName: "lightbulb.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                        
                        Text("Busylight")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                        
                        Text("Control Center")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Navigation items
                    VStack(spacing: 4) {
                        ForEach(SidebarItem.allCases) { item in
                            GlassSidebarItem(item: item, isSelected: selectedItem == item)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedItem = item
                                        UserInteractionLogger.shared.navigation(to: item.rawValue)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    Spacer()
                    
                    // Connection status en sidebar
                    GlassStatusCard(busylight: busylight)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 16)
                }
            }
            .frame(minWidth: 180, idealWidth: 200, maxWidth: 220)
        } detail: {
            // Detail view con glassmorphism background
            ZStack {
                Color(NSColor.windowBackgroundColor)
                
                ScrollView {
                    switch selectedItem {
                    case .pomodoro:
                        PomodoroView()
                            .environmentObject(busylight)
                    case .deepWork:
                        DeepWorkView()
                    case .workProfiles:
                        WorkProfilesView()
                    case .teams:
                        TeamsView()
                    case .dashboard:
                        DashboardView()
                    case .configuration:
                        SettingsView()
                    case .device:
                        DeviceView(busylight: busylight)
                    }
                }
            }
        }
        .frame(minWidth: 750, idealWidth: 850, maxWidth: 1000,
               minHeight: 550, idealHeight: 650, maxHeight: 800)
        .onReceive(NotificationCenter.default.publisher(for: .openMainWindow)) { _ in
            BusylightLogger.shared.debug("Recibida notificación openMainWindow")
            bringWindowToFront()
        }
    }
    
    private func bringWindowToFront() {
        BusylightLogger.shared.debug("Ejecutando bringWindowToFront")
        UserInteractionLogger.shared.windowBroughtToFront()
        NSApp.activate(ignoringOtherApps: true)
        NSApp.unhide(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for window in NSApp.windows {
                if window.isVisible || !window.isMiniaturized {
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                    BusylightLogger.shared.info("Ventana traída al frente exitosamente")
                    return
                }
            }
            BusylightLogger.shared.warning("No se encontró ventana para traer al frente")
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppDelegate())
    }
}
