//
//  PomodoroLiveActivity.swift
//  Busylight Live Activity
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Activity Attributes

struct PomodoroLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let endTime: Date
        let taskName: String?
        let timerState: String // "focusing", "shortBreak", "longBreak", "paused"
    }
    
    let sessionId: UUID
}

// MARK: - Live Activity Widget

@main
struct PomodoroLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroLiveActivityAttributes.self) { context in
            // Lock Screen / Notification Center
            PomodoroLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.8))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            // Dynamic Island
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Image(systemName: "brain")
                            .font(.title2)
                            .foregroundStyle(timerColor(for: context.state.timerState))
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(timerText(for: context.state.endTime))
                            .font(.title2.bold())
                            .monospacedDigit()
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack {
                        Text(context.state.taskName ?? "Focus Session")
                            .font(.headline)
                            .lineLimit(1)
                        Text(context.state.timerState.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(
                        timerInterval: Date()...context.state.endTime,
                        countsDown: true,
                        label: { EmptyView() },
                        currentValueLabel: { EmptyView() }
                    )
                    .progressViewStyle(.linear)
                    .tint(timerColor(for: context.state.timerState))
                }
            } compactLeading: {
                // Compact leading
                Image(systemName: "brain")
                    .foregroundStyle(timerColor(for: context.state.timerState))
            } compactTrailing: {
                // Compact trailing
                Text(timerText(for: context.state.endTime))
                    .monospacedDigit()
                    .font(.caption2)
            } minimal: {
                // Minimal
                Image(systemName: "brain")
                    .foregroundStyle(timerColor(for: context.state.timerState))
            }
        }
    }
    
    private func timerColor(for state: String) -> Color {
        switch state {
        case "focusing": return .red
        case "shortBreak", "longBreak": return .green
        case "paused": return .orange
        default: return .blue
        }
    }
    
    private func timerText(for endTime: Date) -> String {
        let remaining = endTime.timeIntervalSince(Date())
        let minutes = max(0, Int(remaining) / 60)
        let seconds = max(0, Int(remaining) % 60)
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Live Activity View

struct PomodoroLiveActivityView: View {
    let context: ActivityViewContext<PomodoroLiveActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(timerColor)
                
                VStack(alignment: .leading) {
                    Text(context.state.taskName ?? "Focus Session")
                        .font(.headline)
                    Text(context.state.timerState.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(timerText)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(timerColor)
            }
            
            ProgressView(
                timerInterval: Date()...context.state.endTime,
                countsDown: true,
                label: { EmptyView() },
                currentValueLabel: { EmptyView() }
            )
            .progressViewStyle(.linear)
            .tint(timerColor)
        }
        .padding()
    }
    
    private var timerColor: Color {
        switch context.state.timerState {
        case "focusing": return .red
        case "shortBreak", "longBreak": return .green
        case "paused": return .orange
        default: return .blue
        }
    }
    
    private var iconName: String {
        switch context.state.timerState {
        case "focusing": return "brain"
        case "shortBreak", "longBreak": return "cup.and.saucer"
        default: return "timer"
        }
    }
    
    private var timerText: String {
        let remaining = context.state.endTime.timeIntervalSince(Date())
        let minutes = max(0, Int(remaining) / 60)
        let seconds = max(0, Int(remaining) % 60)
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview("Live Activity", as: .content, using: PomodoroLiveActivityAttributes(sessionId: UUID())) {
    PomodoroLiveActivityWidget()
} contentStates: {
    PomodoroLiveActivityAttributes.ContentState(
        endTime: Date().addingTimeInterval(25 * 60),
        taskName: "Work on Project",
        timerState: "focusing"
    )
    PomodoroLiveActivityAttributes.ContentState(
        endTime: Date().addingTimeInterval(5 * 60),
        taskName: nil,
        timerState: "shortBreak"
    )
}
