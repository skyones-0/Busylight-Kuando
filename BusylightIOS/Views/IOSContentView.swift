//
//  IOSContentView.swift
//  Main iOS Content View with Glassmorphism UI
//

import SwiftUI
import SwiftData

struct IOSContentView: View {
    @StateObject private var manager = UnifiedPomodoroManager.shared
    @State private var selectedTab = 0
    @State private var showProfileSheet = false
    
    var body: some View {
        ZStack {
            // Animated background
            MeshGradientBackground()
            
            TabView(selection: $selectedTab) {
                // Timer Tab
                TimerTabView()
                    .tabItem {
                        Image(systemName: "timer")
                        Text("Timer")
                    }
                    .tag(0)
                
                // Stats Tab
                StatsTabView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Stats")
                    }
                    .tag(1)
                
                // Settings Tab
                SettingsTabView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(2)
            }
            .tint(manager.currentPhase.color)
        }
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Timer Tab
struct TimerTabView: View {
    @StateObject private var manager = UnifiedPomodoroManager.shared
    @State private var showProfileSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradientBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with connection status
                        HeaderView()
                        
                        // Main Timer Card
                        TimerCard()
                        
                        // Quick Controls
                        QuickControlsView()
                        
                        // Configuration
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
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Material.thinMaterial)
                            )
                    }
                }
            }
            .sheet(isPresented: $showProfileSheet) {
                ProfileSheet()
            }
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    @StateObject private var syncManager = SyncManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Busylight")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(syncManager.hasHardwareControl ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(syncManager.hasHardwareControl ? "Device Connected" : "Remote Control")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Sync status indicator
            Image(systemName: "icloud.fill")
                .font(.title3)
                .foregroundStyle(.blue.opacity(0.8))
                .symbolEffect(.pulse, options: .repeating)
        }
    }
}

// MARK: - Timer Card
struct TimerCard: View {
    @StateObject private var manager = UnifiedPomodoroManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Phase badge
            PhaseBadge(
                phase: manager.currentPhase,
                isActive: manager.isRunning
            )
            
            // Timer display
            TimerDisplay(
                timeString: manager.timeString,
                phase: manager.currentPhase,
                isRunning: manager.isRunning,
                size: .large
            )
            
            // Progress bar
            GlassProgressBar(
                progress: manager.progress,
                color: manager.currentPhase.color,
                height: 8
            )
            .padding(.horizontal, 20)
            
            // Set counter
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

// MARK: - Quick Controls
struct QuickControlsView: View {
    @StateObject private var manager = UnifiedPomodoroManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Start/Resume Button
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
            
            // Pause Button
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
            
            // Stop Button
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

// MARK: - Configuration Card
struct ConfigurationCard: View {
    @StateObject private var manager = UnifiedPomodoroManager.shared
    @State private var isExpanded = false
    
    var body: some View {
        GlassCard(title: "Configuration", icon: "slider.horizontal.3") {
            VStack(spacing: 12) {
                GlassStepper(
                    icon: "briefcase.fill",
                    title: "Work",
                    value: $manager.workTimeMinutes,
                    range: 1...60
                )
                .disabled(manager.isRunning)
                .onChange(of: manager.workTimeMinutes) { manager.updateConfiguration() }
                
                GlassStepper(
                    icon: "cup.and.saucer.fill",
                    title: "Short Break",
                    value: $manager.shortBreakMinutes,
                    range: 1...30
                )
                .disabled(manager.isRunning)
                .onChange(of: manager.shortBreakMinutes) { manager.updateConfiguration() }
                
                GlassStepper(
                    icon: "sun.max.fill",
                    title: "Long Break",
                    value: $manager.longBreakMinutes,
                    range: 1...60
                )
                .disabled(manager.isRunning)
                .onChange(of: manager.longBreakMinutes) { manager.updateConfiguration() }
                
                GlassStepper(
                    icon: "number",
                    title: "Sets",
                    value: $manager.configuredSets,
                    range: 1...10
                )
                .disabled(manager.isRunning)
                .onChange(of: manager.configuredSets) { manager.updateConfiguration() }
            }
        }
        .opacity(manager.isRunning ? 0.6 : 1)
        .animation(.easeInOut, value: manager.isRunning)
    }
}

// MARK: - Profile Sheet
struct ProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = UnifiedPomodoroManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradientBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Choose a Work Profile")
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
                    Button("Done") {
                        dismiss()
                    }
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
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
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

// MARK: - Stats Tab
struct StatsTabView: View {
    @Query(sort: \PomodoroSession.startTime, order: .reverse) private var sessions: [PomodoroSession]
    
    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradientBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Stats summary
                        StatsSummaryCard(sessions: sessions)
                        
                        // Recent sessions
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
        let todaySessions = sessions.filter { $0.startTime >= today && $0.completed }
        return todaySessions.reduce(0) { $0 + $1.durationMinutes }
    }
    
    private var totalSessions: Int {
        sessions.filter { $0.completed }.count
    }
    
    private var streakDays: Int {
        // Simplified streak calculation
        return min(sessions.filter { $0.completed }.count / 4, 30)
    }
    
    var body: some View {
        GlassCard(title: "This Week", icon: "chart.bar.fill") {
            HStack(spacing: 16) {
                StatItem(value: "\(todayMinutes)", label: "Today", unit: "min")
                Divider()
                StatItem(value: "\(totalSessions)", label: "Sessions", unit: "")
                Divider()
                StatItem(value: "\(streakDays)", label: "Streak", unit: "days")
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
            // Phase icon
            Circle()
                .fill(phaseColor.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: phaseIcon)
                        .font(.caption)
                        .foregroundStyle(phaseColor)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.phaseEnum.displayName)
                    .font(.subheadline.weight(.medium))
                
                Text(session.startTime, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Duration
            Text("\(session.durationMinutes)m")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
    
    private var phaseIcon: String {
        session.phaseEnum.icon
    }
    
    private var phaseColor: Color {
        session.phaseEnum.color
    }
}

// MARK: - Settings Tab
struct SettingsTabView: View {
    @StateObject private var manager = UnifiedPomodoroManager.shared
    @StateObject private var syncManager = SyncManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradientBackground()
                
                List {
                    Section("Timer") {
                        GlassToggle(
                            icon: "speaker.wave.2.fill",
                            title: "Sound",
                            isOn: $manager.soundEnabled
                        )
                        
                        GlassToggle(
                            icon: "hand.tap.fill",
                            title: "Haptics",
                            isOn: $manager.hapticsEnabled
                        )
                        
                        NavigationLink {
                            SoundSelectionView()
                        } label: {
                            HStack {
                                Image(systemName: "music.note")
                                    .frame(width: 28)
                                Text("Timer Sound")
                                Spacer()
                                Text(manager.timerSound.displayName)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    
                    Section("Sync") {
                        GlassToggle(
                            icon: "icloud",
                            title: "iCloud Sync",
                            isOn: $syncManager.isSyncEnabled
                        )
                        
                        HStack {
                            Image(systemName: "laptopcomputer")
                                .frame(width: 28)
                            Text("Device")
                            Spacer()
                            Text(syncManager.currentPlatform.rawValue)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    
                    Section("About") {
                        HStack {
                            Image(systemName: "info.circle")
                                .frame(width: 28)
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(.secondary)
                        }
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

// MARK: - Sound Selection View
struct SoundSelectionView: View {
    @StateObject private var manager = UnifiedPomodoroManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(TimerSound.allCases, id: \.self) { sound in
                Button {
                    manager.timerSound = sound
                    // Play preview
                    Haptics.shared.perform(.button)
                    dismiss()
                } label: {
                    HStack {
                        Text(sound.displayName)
                        
                        Spacer()
                        
                        if manager.timerSound == sound {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Timer Sound")
    }
}

// MARK: - Preview
#Preview {
    IOSContentView()
}
