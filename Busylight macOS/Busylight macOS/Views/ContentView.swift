//
//  ContentView.swift
//  Busylight
//
//  Main content view with sidebar navigation
//  Refactored: Split into feature modules
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
            // Sidebar
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.icon)
                        .font(.system(.body, design: .rounded))
                }
            }
            .navigationTitle("Busylight")
            .listStyle(.sidebar)
            
        } detail: {
            // Detail View based on selection
            switch selectedItem {
            case .pomodoro:
                PomodoroViewPlaceholder()
                    .environmentObject(busylight)
            case .deepWork:
                DeepWorkViewPlaceholder()
            case .workProfiles:
                WorkProfilesViewPlaceholder()
            case .teams:
                TeamsViewPlaceholder()
            case .dashboard:
                DashboardViewPlaceholder()
            case .configuration:
                SettingsViewPlaceholder()
            case .device:
                DeviceView(busylight: busylight)
            }
        }
    }
}

// MARK: - Placeholder Views (To be implemented)
// These should be moved to their respective files in Features/ folder

struct PomodoroViewPlaceholder: View {
    @EnvironmentObject var busylight: BusylightManager
    
    var body: some View {
        VStack {
            Text("Pomodoro Timer")
                .font(.largeTitle)
            Text("Move PomodoroView code here from old ContentView.swift")
                .foregroundStyle(.secondary)
            
            // Placeholder for actual implementation
            GlassCard(title: "Timer", icon: "timer") {
                Text("Pomodoro timer implementation goes here")
                    .padding()
            }
            .padding()
        }
    }
}

struct DeepWorkViewPlaceholder: View {
    var body: some View {
        VStack {
            Text("Deep Work Mode")
                .font(.largeTitle)
            Text("Move DeepWorkView code here from old ContentView.swift")
                .foregroundStyle(.secondary)
        }
    }
}

struct WorkProfilesViewPlaceholder: View {
    var body: some View {
        VStack {
            Text("Work Profiles")
                .font(.largeTitle)
            Text("Move WorkProfilesView code here from old ContentView.swift")
                .foregroundStyle(.secondary)
        }
    }
}

struct TeamsViewPlaceholder: View {
    var body: some View {
        VStack {
            Text("Microsoft Teams")
                .font(.largeTitle)
            Text("Move TeamsView code here from old ContentView.swift")
                .foregroundStyle(.secondary)
        }
    }
}

struct DashboardViewPlaceholder: View {
    var body: some View {
        VStack {
            Text("Dashboard")
                .font(.largeTitle)
            Text("Move DashboardView code here from old ContentView.swift")
                .foregroundStyle(.secondary)
        }
    }
}

struct SettingsViewPlaceholder: View {
    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
            Text("Move SettingsView code here from old ContentView.swift")
                .foregroundStyle(.secondary)
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
