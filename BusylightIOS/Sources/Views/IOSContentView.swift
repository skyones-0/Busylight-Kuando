//
//  IOSContentView.swift
//  BusylightIOS
//

import SwiftUI
import SwiftData

struct IOSContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            MeshGradientBackground()
            
            TabView(selection: $selectedTab) {
                TimerTabView()
                    .tabItem {
                        Image(systemName: "timer")
                        Text("Timer")
                    }
                    .tag(0)
                
                StatsTabView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Stats")
                    }
                    .tag(1)
                
                SettingsTabView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(2)
            }
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct TimerTabView: View {
    @StateObject private var manager = UnifiedPomodoroManager.shared
    @State private var showProfileSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradientBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        HeaderView()
                        TimerCard()
                        QuickControlsView()
                        ConfigurationCard()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfileSheet = true
                    } label: {
                        Image(systemName: "briefcase.fill")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .padding(10)
                            .background(Circle().fill(Material.thinMaterial))
                    }
                }
            }
            .sheet(isPresented: $showProfileSheet) {
                ProfileSheet()
            }
        }
    }
}

struct HeaderView: View {
    @StateObject private var cloudKit = CloudKitSyncManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Busylight")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("Remote Control")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: cloudKit.isSyncing ? "icloud.and.arrow.up" : "icloud.fill")
                .font(.title3)
                .foregroundStyle(.blue.opacity(0.8))
        }
    }
}

struct TimerCard: View {
    @StateObject private var manager = UnifiedPomodoroManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            PhaseBadge(phase: manager.currentPhase, isActive: manager.isRunning)
            
            TimerDisplay(
                timeString: manager.timeString,
                phase: manager.currentPhase,
                isRunning: manager.isRunning,
                size: .large
            )
            
            GlassProgressBar(progress: manager.progress, color: manager.currentPhase.color, height: 8)
                .padding(.horizontal, 20)
            
            HStack(spacing: 4) {
                Text("Session")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(manager.currentSet)/\(manager.totalSets)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(manager.currentPhase.color)
            }
        }
        .padding(28)
        .glass(material: .ultraThinMaterial, cornerRadius: 28)
    }
}

struct QuickControlsView: View {
    @StateObject private var manager = UnifiedPomodoroManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            GlassButton(
                title: manager.isPaused ? "Resume" : "Start",
                icon: "play.fill",
                color: .green,
                isProminent: true
            ) {
                manager.start()
            }
            .disabled(manager.isRunning && !manager.isPaused)
            .opacity(manager.isRunning && !manager.isPaused ? 0.5 : 1)
            
            GlassButton(
                title: "Pause",
                icon: "pause.fill",
                color: .orange,
                isProminent: false
            ) {
                manager.pause()
            }
            .disabled(!manager.isRunning || manager.isPaused)
            .opacity(!manager.isRunning || manager.isPaused ? 0.5 : 1)
            
            GlassButton(
                title: "Stop",
                icon: "stop.fill",
                color: .red,
                isProminent: false
            ) {
                manager.stop()
            }
            .disabled(!manager.isRunning && !manager.isPaused)
            .opacity(!manager.isRunning && !manager.isPaused ? 0.5 : 1)
        }
    }
}

struct ConfigurationCard: View {
    @StateObject private var manager = UnifiedPomodoroManager.shared
    
    var body: some View {
        GlassCard(title: "Configuration", icon: "slider.horizontal.3") {
            VStack(spacing: 12) {
                GlassStepper(icon: "briefcase.fill", title: "Work", value: $manager.workTimeMinutes, range: 1...60)
                    .disabled(manager.isRunning)
                    .onChange(of: manager.workTimeMinutes) { manager.updateConfiguration() }
                
                GlassStepper(icon: "cup.and.saucer.fill", title: "Short Break", value: $manager.shortBreakMinutes, range: 1...30)
                    .disabled(manager.isRunning)
                    .onChange(of: manager.shortBreakMinutes) { manager.updateConfiguration() }
                
                GlassStepper(icon: "sun.max.fill", title: "Long Break", value: $manager.longBreakMinutes, range: 1...60)
                    .disabled(manager.isRunning)
                    .onChange(of: manager.longBreakMinutes) { manager.updateConfiguration() }
                
                GlassStepper(icon: "number", title: "Sets", value: $manager.configuredSets, range: 1...10)
                    .disabled(manager.isRunning)
                    .onChange(of: manager.configuredSets) { manager.updateConfiguration() }
            }
        }
        .opacity(manager.isRunning ? 0.6 : 1)
    }
}

struct ProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = UnifiedPomodoroManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradientBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Choose Work Profile")
                            .font(.title2.weight(.bold))
                            .padding(.top, 20)
                        
                        ForEach(WorkProfile.allCases) { profile in
                            ProfileCard(profile: profile) {
                                manager.applyProfile(profile)
                                dismiss()
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ProfileCard: View {
    let profile: WorkProfile
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: profile.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.rawValue)
                        .font(.headline)
                    
                    let settings = profile.settings
                    Text("\(settings.work)m work · \(settings.shortBreak)m break · \(settings.sets) sets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .glass(material: .thinMaterial, cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }
}

struct StatsTabView: View {
    @Query(sort: \PomodoroSession.startTime, order: .reverse) private var sessions: [PomodoroSession]
    
    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradientBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        StatsSummaryCard(sessions: sessions)
                        RecentSessionsCard(sessions: sessions)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Statistics")
        }
    }
}

struct StatsSummaryCard: View {
    let sessions: [PomodoroSession]
    
    private var todayMinutes: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return sessions.filter { $0.startTime >= today && $0.completed }.reduce(0) { $0 + $1.durationMinutes }
    }
    
    private var totalSessions: Int {
        sessions.filter { $0.completed }.count
    }
    
    var body: some View {
        GlassCard(title: "This Week", icon: "chart.bar.fill") {
            HStack(spacing: 16) {
                StatItem(value: "\(todayMinutes)", label: "Today", unit: "min")
                Divider()
                StatItem(value: "\(totalSessions)", label: "Sessions", unit: "")
            }
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RecentSessionsCard: View {
    let sessions: [PomodoroSession]
    
    var body: some View {
        GlassCard(title: "Recent Sessions", icon: "clock.fill") {
            if sessions.isEmpty {
                Text("No sessions yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(sessions.prefix(5)) { session in
                        SessionRow(session: session)
                    }
                }
            }
        }
    }
}

struct SessionRow: View {
    let session: PomodoroSession
    
    var body: some View {
        HStack {
            Circle()
                .fill(session.phaseEnum.color.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: session.phaseEnum.icon)
                        .font(.caption)
                        .foregroundStyle(session.phaseEnum.color)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.phaseEnum.displayName)
                    .font(.subheadline.weight(.medium))
                Text(session.startTime, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(session.durationMinutes)m")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

struct SettingsTabView: View {
    @StateObject private var manager = UnifiedPomodoroManager.shared
    @StateObject private var cloudKit = CloudKitSyncManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradientBackground()
                
                List {
                    Section("Timer") {
                        GlassToggle(icon: "speaker.wave.2.fill", title: "Sound", isOn: $manager.soundEnabled)
                        GlassToggle(icon: "hand.tap.fill", title: "Haptics", isOn: $manager.hapticsEnabled)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    
                    Section("Sync") {
                        GlassToggle(icon: "icloud", title: "iCloud Sync", isOn: $cloudKit.isSyncEnabled)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }
}
