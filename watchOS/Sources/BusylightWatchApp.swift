//
//  BusylightWatchApp.swift
//  Busylight Watch
//

import SwiftUI
import SwiftData
import BusylightShared

@main
struct BusylightWatchApp: App {
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            PomodoroSession.self,
            UserSettings.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                WatchPomodoroView()
            }
        }
        .modelContainer(container)
    }
}

// MARK: - Watch Pomodoro View

struct WatchPomodoroView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var timerState: PomodoroTimerState = .idle
    @State private var remainingTime: TimeInterval = 25 * 60
    @State private var isRunning = false
    
    private let focusDuration: TimeInterval = 25 * 60
    
    var body: some View {
        VStack(spacing: 12) {
            // Timer display
            Text(formattedTime(remainingTime))
                .font(.system(size: 48, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(timerColor)
            
            // Status
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            // Control buttons
            HStack(spacing: 20) {
                Button(action: resetTimer) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                }
                .buttonStyle(.bordered)
                .tint(.gray)
                .disabled(timerState == .idle)
                
                Button(action: toggleTimer) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)
                .tint(timerColor)
            }
        }
        .padding()
        .navigationTitle("Focus")
    }
    
    private var timerColor: Color {
        isRunning ? .red : (timerState == .idle ? .blue : .orange)
    }
    
    private var statusText: String {
        switch timerState {
        case .focusing: return "Focusing"
        case .paused: return "Paused"
        default: return "Ready"
        }
    }
    
    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        if timerState == .idle {
            timerState = .focusing
            remainingTime = focusDuration
            
            // Create session
            let session = PomodoroSession(
                startTime: Date(),
                duration: focusDuration,
                type: "focus"
            )
            modelContext.insert(session)
        } else {
            timerState = .focusing
        }
        
        isRunning = true
        
        // Start timer
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if !isRunning {
                timer.invalidate()
                return
            }
            
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                timer.invalidate()
                completeTimer()
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timerState = .paused
    }
    
    private func completeTimer() {
        isRunning = false
        timerState = .idle
        remainingTime = focusDuration
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.success)
    }
    
    private func resetTimer() {
        isRunning = false
        timerState = .idle
        remainingTime = focusDuration
    }
}
