//
//  WatchContentView.swift
//  BusylightWatch
//

import SwiftUI
import WatchKit

struct WatchContentView: View {
    @StateObject private var manager = UnifiedPomodoroManager.shared
    
    var body: some View {
        TabView {
            TimerView()
            QuickActionsView()
            StatsView()
        }
        .tabViewStyle(.verticalPage)
        .onAppear {
            WKApplication.shared().isIdleTimerDisabled = manager.isRunning
        }
        .onChange(of: manager.isRunning) { _, isRunning in
            WKApplication.shared().isIdleTimerDisabled = isRunning
        }
    }
}

struct TimerView: View {
    @StateObject private var manager = UnifiedPomodoroManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(manager.currentPhase.color.opacity(manager.isRunning ? 0.15 : 0.05))
                    .blur(radius: 40)
                    .scaleEffect(1.5)
                
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: manager.currentPhase.icon)
                            .font(.caption2)
                        Text(manager.currentPhase.displayName)
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(manager.currentPhase.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(manager.currentPhase.color.opacity(0.2)))
                    
                    Spacer()
                    
                    Text(manager.timeString)
                        .font(.system(size: 52, weight: .thin, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(manager.progress))
                            .stroke(manager.currentPhase.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.5), value: manager.progress)
                    }
                    .frame(width: 50, height: 50)
                    
                    Text("\(manager.currentSet)/\(manager.totalSets)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        WatchButton(
                            icon: manager.isRunning ? "pause.fill" : "play.fill",
                            color: manager.isRunning ? .orange : .green
                        ) {
                            if manager.isRunning {
                                manager.pause()
                            } else {
                                manager.start()
                            }
                        }
                        
                        WatchButton(
                            icon: "stop.fill",
                            color: .red
                        ) {
                            manager.stop()
                        }
                        .disabled(!manager.isRunning && !manager.isPaused)
                        .opacity(!manager.isRunning && !manager.isPaused ? 0.3 : 1)
                    }
                }
                .padding()
            }
        }
    }
}

struct WatchButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Circle()
                    .stroke(color.opacity(0.4), lineWidth: 2)
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(color)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct QuickActionsView: View {
    @StateObject private var manager = UnifiedPomodoroManager.shared
    @State private var showingSkipConfirmation = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
            
            WatchActionButton(
                icon: "forward.fill",
                title: "Skip Phase",
                color: .blue
            ) {
                showingSkipConfirmation = true
            }
            .disabled(!manager.isRunning && !manager.isPaused)
            .alert("Skip to next phase?", isPresented: $showingSkipConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Skip") { manager.skip() }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Profile")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    ProfileButton(icon: "laptopcomputer", color: .blue) {
                        manager.applyProfile(.coding)
                    }
                    
                    ProfileButton(icon: "flame.fill", color: .orange) {
                        manager.applyProfile(.deepWork)
                    }
                    
                    ProfileButton(icon: "book.fill", color: .green) {
                        manager.applyProfile(.learning)
                    }
                }
            }
        }
        .padding()
    }
}

struct WatchActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(color.opacity(0.2)))
                
                Text(title)
                    .font(.body)
                
                Spacer()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.15)))
        }
        .buttonStyle(.plain)
    }
}

struct ProfileButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.15)))
        }
        .buttonStyle(.plain)
    }
}

struct StatsView: View {
    @Query(sort: \PomodoroSession.startTime, order: .reverse) private var sessions: [PomodoroSession]
    
    private var todayMinutes: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return sessions.filter { $0.startTime >= today && $0.completed }.reduce(0) { $0 + $1.durationMinutes }
    }
    
    private var completedSessions: Int {
        sessions.filter { $0.completed }.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Today")
                .font(.headline)
            
            HStack(spacing: 20) {
                WatchStatItem(value: "\(todayMinutes)", label: "Minutes")
                WatchStatItem(value: "\(completedSessions)", label: "Sessions")
            }
            
            Divider()
            
            if sessions.isEmpty {
                Text("No sessions yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                List(sessions.prefix(3)) { session in
                    SessionListItem(session: session)
                }
                .listStyle(.plain)
                .frame(height: 100)
            }
        }
        .padding()
    }
}

struct WatchStatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SessionListItem: View {
    let session: PomodoroSession
    
    var body: some View {
        HStack {
            Image(systemName: session.phaseEnum.icon)
                .font(.caption)
                .foregroundStyle(session.phaseEnum.color)
            
            Text(session.phaseEnum.displayName)
                .font(.caption)
            
            Spacer()
            
            Text("\(session.durationMinutes)m")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
