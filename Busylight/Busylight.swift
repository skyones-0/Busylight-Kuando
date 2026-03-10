//
//  ContentView.swift
//  Busylight
//

import SwiftUI
import SwiftData

struct Busylight: View {
    @State private var isHovered = false
    @StateObject private var busylight = BusylightManager()
    @StateObject private var locationManager = LocationManager.shared
    @EnvironmentObject var appDelegate: AppDelegate
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettings: [AppSettings]
    @State private var selectedItem: SidebarItem = .pomodoro
    @State private var isSidebarCollapsed: Bool = SidebarState.isCollapsed
    @StateObject private var audio = AudioManager.shared

    private let expandedWidth: CGFloat = 200
    private let collapsedWidth: CGFloat = 60

    private var settings: AppSettings {
        appSettings.first ?? AppSettings()
    }

    private var colorScheme: ColorScheme? {
        switch settings.appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.15),
                    Color.purple.opacity(0.12),
                    Color.orange.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            HStack(spacing: 0) {
                sidebarContent
                    .frame(width: isSidebarCollapsed ? collapsedWidth : expandedWidth)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: isSidebarCollapsed ? 0 : 20))

                Divider()
                    .opacity(0.2)

                detailContent
                    .background(Color.clear)
            }
        }
        .overlay(alignment: .topLeading) {
            HStack(spacing: 12) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .help("Mostrar/Ocultar sidebar")

                AudioMenuView()
            }
            .padding(.leading, 80)
            .padding(.top, 8)
        }
    }

    private var sidebarContent: some View {
        ZStack {
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack { }

                if !isSidebarCollapsed {
                    expandedHeader
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                if isSidebarCollapsed {
                    collapsedHeader
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                VStack(spacing: 4) {
                    ForEach(SidebarItem.allCases) { item in
                        if isSidebarCollapsed {
                            CollapsedSidebarItem(
                                item: item,
                                isSelected: selectedItem == item,
                                action: { selectItem(item) }
                            )
                        } else {
                            LiquidGlassSidebarItem(item: item, isSelected: selectedItem == item)
                                .onTapGesture { selectItem(item) }
                        }
                    }
                }
                .padding(.horizontal, isSidebarCollapsed ? 8 : 8)

                Spacer()

                if isSidebarCollapsed {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(busylight.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                    }
                    .padding(.bottom, 16)
                } else {
                    LiquidGlassStatusCard(busylight: busylight)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 16)
                }
            }
        }
    }

    private var expandedHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(.orange.gradient)
                    .frame(width: 50, height: 50)
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }

            Text("Busylight")
                .font(.system(.title3, design: .rounded).weight(.bold))

            Text("Control Center")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let countryFlag = locationManager.detectedCountryFlag,
               let countryName = locationManager.detectedCountryName {
                HStack(spacing: 4) {
                    Text(countryFlag).font(.caption)
                    Text(countryName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.blue.opacity(0.15)))
                .padding(.top, 4)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 16)
    }

    private var collapsedHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(.orange.gradient)
                    .frame(width: 40, height: 40)
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
            }
            .padding(.top, 8)

            if let countryFlag = locationManager.detectedCountryFlag {
                Text(countryFlag).font(.caption)
            }
        }
        .padding(.bottom, 16)
    }

    private var detailContent: some View {
        ScrollView {
            VStack {
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
                    DeviceView()
                        .environmentObject(busylight)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .id(selectedItem)
        .contentMargins(.all, 20, for: .scrollContent)
    }

    private func toggleSidebar() {
        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8)) {
            isSidebarCollapsed.toggle()
            SidebarState.isCollapsed = isSidebarCollapsed
        }
    }

    private func selectItem(_ item: SidebarItem) {
        selectedItem = item
        UserInteractionLogger.shared.navigation(to: item.rawValue)
    }
}

struct AudioMenuView: View {
    @StateObject private var audio = AudioManager.shared
    @State private var isExpanded = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: audio.isPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .foregroundStyle(audio.isPlaying ? .green : .secondary)
                    if audio.isPlaying, let track = audio.currentTrack {
                        Text(track)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 0.5))

            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(audio.tracks, id: \.self) { track in
                        Button {
                            audio.currentTrack == track ? audio.stop() : audio.play(track)
                            isExpanded = false
                        } label: {
                            HStack {
                                Text(track)
                                Spacer()
                                if audio.currentTrack == track {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()

                    Button("Stop") {
                        audio.stop()
                        isExpanded = false
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    HStack {
                        Image(systemName: "speaker.fill")
                        Slider(value: $audio.volume, in: 0...1)
                            .controlSize(.mini)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .frame(width: 160)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                .offset(y: 36)
                .zIndex(100)
            }
        }
        .zIndex(isExpanded ? 100 : 1)
    }
}

private struct SidebarState {
    private static let key = "sidebarCollapsed"
    static var isCollapsed: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

struct CollapsedSidebarItem: View {
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: item.icon)
                .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 10).fill(isSelected ? Color.accentColor : Color.clear))
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help(item.rawValue)
    }
}
