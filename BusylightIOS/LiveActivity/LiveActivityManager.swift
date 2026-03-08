//
//  LiveActivityManager.swift
//  iOS Live Activity and Dynamic Island support
//

import Foundation
import ActivityKit
import SwiftUI

// MARK: - Live Activity Attributes
struct BusylightTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var phase: String
        var remainingSeconds: Int
        var isRunning: Bool
        var currentSet: Int
        var totalSets: Int
        var progress: Double
    }
    
    var totalSets: Int
}

// MARK: - Live Activity Manager
@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<BusylightTimerAttributes>?
    
    private init() {}
    
    // MARK: - Start Activity
    func startActivity(
        phase: PomodoroPhase,
        remainingSeconds: Int,
        totalSets: Int,
        currentSet: Int
    ) {
        // Check if Live Activities are available
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("❌ Live Activities not enabled")
            return
        }
        
        // End any existing activity
        endActivity()
        
        let attributes = BusylightTimerAttributes(totalSets: totalSets)
        let contentState = BusylightTimerAttributes.ContentState(
            phase: phase.rawValue,
            remainingSeconds: remainingSeconds,
            isRunning: true,
            currentSet: currentSet,
            totalSets: totalSets,
            progress: 0.0
        )
        
        let activityContent = ActivityContent(
            state: contentState,
            staleDate: Date().addingTimeInterval(3600) // 1 hour stale date
        )
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: activityContent,
                pushType: nil
            )
            print("✅ Live Activity started: \(currentActivity?.id ?? "unknown")")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
    }
    
    // MARK: - Update Activity
    func updateActivity(
        phase: PomodoroPhase,
        remainingSeconds: Int,
        isRunning: Bool,
        currentSet: Int,
        totalSets: Int
    ) {
        guard let activity = currentActivity else { return }
        
        let contentState = BusylightTimerAttributes.ContentState(
            phase: phase.rawValue,
            remainingSeconds: remainingSeconds,
            isRunning: isRunning,
            currentSet: currentSet,
            totalSets: totalSets,
            progress: calculateProgress(phase: phase, remainingSeconds: remainingSeconds)
        )
        
        let activityContent = ActivityContent(
            state: contentState,
            staleDate: Date().addingTimeInterval(3600)
        )
        
        Task {
            await activity.update(activityContent)
        }
    }
    
    // MARK: - End Activity
    func endActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            let finalContent = BusylightTimerAttributes.ContentState(
                phase: PomodoroPhase.work.rawValue,
                remainingSeconds: 0,
                isRunning: false,
                currentSet: 1,
                totalSets: 4,
                progress: 1.0
            )
            
            await activity.end(
                ActivityContent(state: finalContent, staleDate: nil),
                dismissalPolicy: .default
            )
            
            currentActivity = nil
            print("✅ Live Activity ended")
        }
    }
    
    // MARK: - Helper
    private func calculateProgress(phase: PomodoroPhase, remainingSeconds: Int) -> Double {
        let manager = UnifiedPomodoroManager.shared
        let total: Int
        
        switch phase {
        case .work:
            total = manager.workTimeMinutes * 60
        case .shortBreak:
            total = manager.shortBreakMinutes * 60
        case .longBreak:
            total = manager.longBreakMinutes * 60
        }
        
        guard total > 0 else { return 0 }
        return Double(total - remainingSeconds) / Double(total)
    }
}

// MARK: - Live Activity Views
struct BusylightTimerWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BusylightTimerAttributes.self) { context in
            // Lock Screen / Notification Center
            LockScreenView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: phaseIcon(for: context.state.phase))
                            .font(.title2)
                            .foregroundStyle(phaseColor(for: context.state.phase))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.phase)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.leading, 4)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timeString(from: context.state.remainingSeconds))
                        .font(.system(size: 38, weight: .thin, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .padding(.trailing, 4)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(phaseColor(for: context.state.phase))
                        .padding(.horizontal, 8)
                }
            } compactLeading: {
                // Compact leading
                Image(systemName: phaseIcon(for: context.state.phase))
                    .font(.caption2)
                    .foregroundStyle(phaseColor(for: context.state.phase))
            } compactTrailing: {
                // Compact trailing
                Text(timeString(from: context.state.remainingSeconds))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.primary)
            } minimal: {
                // Minimal
                Image(systemName: "timer")
                    .font(.caption2)
                    .foregroundStyle(phaseColor(for: context.state.phase))
            }
        }
    }
    
    private func phaseIcon(for phase: String) -> String {
        PomodoroPhase(rawValue: phase)?.icon ?? "timer"
    }
    
    private func phaseColor(for phase: String) -> Color {
        PomodoroPhase(rawValue: phase)?.color ?? .gray
    }
    
    private func timeString(from seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Lock Screen View
struct LockScreenView: View {
    let context: ActivityViewContext<BusylightTimerAttributes>
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.ultraThinMaterial)
            
            VStack(spacing: 12) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: phaseIcon)
                            .font(.subheadline)
                            .foregroundStyle(phaseColor)
                        
                        Text(context.state.phase)
                            .font(.subheadline.weight(.semibold))
                    }
                    
                    Spacer()
                    
                    Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(phaseColor.opacity(0.15))
                        )
                }
                
                // Timer
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 56, weight: .thin, design: .rounded))
                        .monospacedDigit()
                    
                    if context.state.isRunning {
                        Image(systemName: "play.fill")
                            .font(.caption)
                            .foregroundStyle(phaseColor)
                    } else {
                        Image(systemName: "pause.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Progress
                ProgressView(value: context.state.progress)
                    .tint(phaseColor)
                    .scaleEffect(y: 1.5)
            }
            .padding(20)
        }
        .padding(.horizontal, 4)
    }
    
    private var phase: PomodoroPhase {
        PomodoroPhase(rawValue: context.state.phase) ?? .work
    }
    
    private var phaseIcon: String {
        phase.icon
    }
    
    private var phaseColor: Color {
        phase.color
    }
    
    private var timeString: String {
        String(format: "%02d:%02d", context.state.remainingSeconds / 60, context.state.remainingSeconds % 60)
    }
}

// MARK: - Preview
#Preview("Live Activity", as: .content, using: BusylightTimerAttributes(totalSets: 4)) {
    BusylightTimerWidget()
} contentStates: {
    BusylightTimerAttributes.ContentState(
        phase: "Work",
        remainingSeconds: 1423,
        isRunning: true,
        currentSet: 2,
        totalSets: 4,
        progress: 0.35
    )
    BusylightTimerAttributes.ContentState(
        phase: "Short Break",
        remainingSeconds: 245,
        isRunning: true,
        currentSet: 2,
        totalSets: 4,
        progress: 0.18
    )
}
