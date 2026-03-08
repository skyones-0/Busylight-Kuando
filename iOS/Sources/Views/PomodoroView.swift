//
//  PomodoroView.swift
//  Busylight iOS
//

import SwiftUI
import SwiftData
import ActivityKit
import BusylightShared

struct PomodoroView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PomodoroSession.startTime, order: .reverse) private var sessions: [PomodoroSession]
    
    @State private var timerState: PomodoroTimerState = .idle
    @State private var remainingTime: TimeInterval = 25 * 60
    @State private var currentSession: PomodoroSession?
    @State private var taskName = ""
    @State private var currentSet = 1
    
    private let focusDuration: TimeInterval = 25 * 60
    private let shortBreakDuration: TimeInterval = 5 * 60
    private let longBreakDuration: TimeInterval = 15 * 60
    private let setsBeforeLongBreak = 4
    
    private var progress: Double {
        let total = currentDuration
        return total > 0 ? 1.0 - (remainingTime / total) : 0
    }
    
    private var currentDuration: TimeInterval {
        switch timerState {
        case .focusing: return focusDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak: return longBreakDuration
        default: return focusDuration
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Timer Display
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(timerColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: progress)
                    
                    // Time text
                    VStack(spacing: 8) {
                        Text(formattedTime(remainingTime))
                            .font(.system(size: 64, weight: .light, design: .rounded))
                            .monospacedDigit()
                        
                        Text(statusText)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        Text("Set \(currentSet)/\(setsBeforeLongBreak)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 280, height: 280)
                .padding(.top, 20)
                
                // Task name input
                TextField("What are you working on?", text: $taskName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .disabled(timerState != .idle && timerState != .paused)
                
                // Control buttons
                HStack(spacing: 40) {
                    // Reset button
                    Button(action: resetTimer) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(timerState == .idle)
                    
                    // Main action button
                    Button(action: mainAction) {
                        ZStack {
                            Circle()
                                .fill(timerColor)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: mainButtonIcon)
                                .font(.title)
                                .foregroundStyle(.white)
                        }
                    }
                    
                    // Skip button
                    Button(action: skipTimer) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(timerState == .idle)
                }
                
                // Live Activity indicator
                if Activity<PomodoroLiveActivityWidget>.activities.isEmpty == false {
                    HStack {
                        Image(systemName: "livephoto")
                            .foregroundStyle(.red)
                        Text("Live Activity Active")
                            .font(.caption)
                        Spacer()
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Focus")
        }
    }
    
    private var timerColor: Color {
        switch timerState {
        case .focusing: return .red
        case .shortBreak, .longBreak: return .green
        case .paused: return .orange
        case .idle: return .blue
        }
    }
    
    private var statusText: String {
        switch timerState {
        case .focusing: return "Focusing"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        case .paused: return "Paused"
        case .idle: return "Ready to focus"
        }
    }
    
    private var mainButtonIcon: String {
        switch timerState {
        case .idle: return "play.fill"
        case .paused: return "play.fill"
        case .focusing, .shortBreak, .longBreak: return "pause.fill"
        }
    }
    
    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func mainAction() {
        switch timerState {
        case .idle:
            startFocus()
        case .paused:
            resumeTimer()
        case .focusing, .shortBreak, .longBreak:
            pauseTimer()
        }
    }
    
    private func startFocus() {
        timerState = .focusing
        remainingTime = focusDuration
        
        // Create session
        let session = PomodoroSession(
            startTime: Date(),
            duration: focusDuration,
            type: "focus",
            taskName: taskName.isEmpty ? nil : taskName
        )
        modelContext.insert(session)
        currentSession = session
        
        // Start Live Activity
        startLiveActivity(session: session)
        
        // Start timer
        startTimer()
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timerState == .paused || timerState == .idle {
                timer.invalidate()
                return
            }
            
            if remainingTime > 0 {
                remainingTime -= 1
                updateLiveActivity()
            } else {
                timer.invalidate()
                completeTimer()
            }
        }
    }
    
    private func pauseTimer() {
        timerState = .paused
    }
    
    private func resumeTimer() {
        timerState = currentSession?.type == "focus" ? .focusing : .shortBreak
        startTimer()
    }
    
    private func completeTimer() {
        currentSession?.completed = true
        currentSession?.endTime = Date()
        try? modelContext.save()
        
        endLiveActivity()
        
        // Move to next state
        if timerState == .focusing {
            if currentSet >= setsBeforeLongBreak {
                startLongBreak()
            } else {
                startShortBreak()
            }
        } else {
            // Break finished
            currentSet += 1
            if currentSet > setsBeforeLongBreak {
                currentSet = 1
            }
            timerState = .idle
        }
    }
    
    private func startShortBreak() {
        timerState = .shortBreak
        remainingTime = shortBreakDuration
        startTimer()
    }
    
    private func startLongBreak() {
        timerState = .longBreak
        remainingTime = longBreakDuration
        currentSet = 1
        startTimer()
    }
    
    private func resetTimer() {
        timerState = .idle
        remainingTime = focusDuration
        currentSession = nil
        endLiveActivity()
    }
    
    private func skipTimer() {
        endLiveActivity()
        completeTimer()
    }
}

// MARK: - Live Activity Support

extension PomodoroView {
    func startLiveActivity(session: PomodoroSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = PomodoroLiveActivityAttributes(sessionId: session.id)
        let state = PomodoroLiveActivityAttributes.ContentState(
            endTime: Date().addingTimeInterval(focusDuration),
            taskName: taskName.isEmpty ? nil : taskName,
            timerState: timerState
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: state,
                pushType: nil
            )
            print("Live Activity started: \(activity.id)")
        } catch {
            print("Error starting Live Activity: \(error)")
        }
    }
    
    func updateLiveActivity() {
        Task {
            for activity in Activity<PomodoroLiveActivityAttributes>.activities {
                let state = PomodoroLiveActivityAttributes.ContentState(
                    endTime: Date().addingTimeInterval(remainingTime),
                    taskName: taskName.isEmpty ? nil : taskName,
                    timerState: timerState
                )
                await activity.update(using: state)
            }
        }
    }
    
    func endLiveActivity() {
        Task {
            for activity in Activity<PomodoroLiveActivityAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }
}

// MARK: - Live Activity Types

struct PomodoroLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let endTime: Date
        let taskName: String?
        let timerState: PomodoroTimerState
    }
    
    let sessionId: UUID
}

// Placeholder for widget - will be in separate file
struct PomodoroLiveActivityWidget {
    // This will be implemented in the Live Activity widget extension
}
