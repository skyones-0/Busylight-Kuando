//
//  SidebarItem.swift
//  Busylight
//
//  Sidebar navigation items
//

import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case pomodoro = "Pomodoro"
    case deepWork = "Deep Work"
    case workProfiles = "Profiles"
    case teams = "Teams"
    case dashboard = "Dashboard"
    case configuration = "Settings"
    case device = "Device"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .pomodoro: return "timer"
        case .deepWork: return "flame.fill"
        case .workProfiles: return "briefcase.fill"
        case .teams: return "person.2.fill"
        case .dashboard: return "chart.bar.fill"
        case .configuration: return "gearshape.fill"
        case .device: return "lightbulb.fill"
        }
    }
}
