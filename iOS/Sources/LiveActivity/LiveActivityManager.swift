//
//  LiveActivityManager.swift
//  BusylightIOS
//
//  Live Activity and Dynamic Island support
//

import Foundation
import ActivityKit
import SwiftUI

public struct BusylightTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var phase: String
        public var remainingSeconds: Int
        public var isRunning: Bool
        public var currentSet: Int
        public var totalSets: Int
        public var progress: Double
        
        public init(phase: String, remainingSeconds: Int, isRunning: Bool, currentSet: Int, totalSets: Int, progress: Double) {
            self.phase = phase
            self.remainingSeconds = remainingSeconds
            self.isRunning = isRunning
            self.currentSet = currentSet
            self.totalSets = totalSets
            self.progress = progress
        }
    }
    
    public var totalSets: Int
    
    public init(totalSets: Int) {
        self.totalSets = totalSets
    }
}

@MainActor
public final class LiveActivityManager: ObservableObject {
    public static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<BusylightTimerAttributes>?
    
    private init() {}
    
    public func start(phase: PomodoroPhase, remainingSeconds: Int, totalSets: Int, currentSet: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        end()
        
        let attributes = BusylightTimerAttributes(totalSets: totalSets)
        let contentState = BusylightTimerAttributes.ContentState(
            phase: phase.rawValue,
            remainingSeconds: remainingSeconds,
            isRunning: true,
            currentSet: currentSet,
            totalSets: totalSets,
            progress: 0.0
        )
        
        let content = ActivityContent(state: contentState, staleDate: Date().addingTimeInterval(3600))
        
        do {
            currentActivity = try Activity.request(attributes: attributes, content: content, pushType: nil)
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    public func update(phase: PomodoroPhase, remainingSeconds: Int, isRunning: Bool, currentSet: Int, totalSets: Int) {
        guard let activity = currentActivity else { return }
        
        let manager = UnifiedPomodoroManager.shared
        let total = phase == .work ? manager.workTimeMinutes * 60 : phase == .shortBreak ? manager.shortBreakMinutes * 60 : manager.longBreakMinutes * 60
        let progress = total > 0 ? Double(total - remainingSeconds) / Double(total) : 0
        
        let contentState = BusylightTimerAttributes.ContentState(
            phase: phase.rawValue,
            remainingSeconds: remainingSeconds,
            isRunning: isRunning,
            currentSet: currentSet,
            totalSets: totalSets,
            progress: progress
        )
        
        let content = ActivityContent(state: contentState, staleDate: Date().addingTimeInterval(3600))
        
        Task {
            await activity.update(content)
        }
    }
    
    public func end() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
}

public struct BusylightLiveActivityWidget: Widget {
    public init() {}
    
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: BusylightTimerAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    BottomView(context: context)
                }
            } compactLeading: {
                CompactLeadingView(context: context)
            } compactTrailing: {
                CompactTrailingView(context: context)
            } minimal: {
                MinimalView(context: context)
            }
        }
    }
}

struct LockScreenView: View {
    let context: ActivityViewContext<BusylightTimerAttributes>
    
    var phase: PomodoroPhase {
        PomodoroPhase(rawValue: context.state.phase) ?? .work
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.ultraThinMaterial)
            
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: phase.icon)
                            .foregroundStyle(phase.color)
                        Text(context.state.phase)
                            .font(.subheadline.weight(.semibold))
                    }
                    Spacer()
                    Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(phase.color.opacity(0.15)))
                }
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(String(format: "%02d:%02d", context.state.remainingSeconds / 60, context.state.remainingSeconds % 60))
                        .font(.system(size: 56, weight: .thin, design: .rounded))
                        .monospacedDigit()
                    
                    Image(systemName: context.state.isRunning ? "play.fill" : "pause.fill")
                        .font(.caption)
                        .foregroundStyle(phase.color)
                }
                
                ProgressView(value: context.state.progress)
                    .tint(phase.color)
                    .scaleEffect(y: 1.5)
            }
            .padding(20)
        }
        .padding(.horizontal, 4)
    }
}

struct LeadingView: View {
    let context: ActivityViewContext<BusylightTimerAttributes>
    
    var phase: PomodoroPhase {
        PomodoroPhase(rawValue: context.state.phase) ?? .work
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: phase.icon)
                .font(.title2)
                .foregroundStyle(phase.color)
            
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
}

struct TrailingView: View {
    let context: ActivityViewContext<BusylightTimerAttributes>
    
    var body: some View {
        Text(String(format: "%02d:%02d", context.state.remainingSeconds / 60, context.state.remainingSeconds % 60))
            .font(.system(size: 38, weight: .thin, design: .rounded))
            .monospacedDigit()
            .padding(.trailing, 4)
    }
}

struct BottomView: View {
    let context: ActivityViewContext<BusylightTimerAttributes>
    
    var phase: PomodoroPhase {
        PomodoroPhase(rawValue: context.state.phase) ?? .work
    }
    
    var body: some View {
        ProgressView(value: context.state.progress)
            .tint(phase.color)
            .padding(.horizontal, 8)
    }
}

struct CompactLeadingView: View {
    let context: ActivityViewContext<BusylightTimerAttributes>
    
    var phase: PomodoroPhase {
        PomodoroPhase(rawValue: context.state.phase) ?? .work
    }
    
    var body: some View {
        Image(systemName: phase.icon)
            .font(.caption2)
            .foregroundStyle(phase.color)
    }
}

struct CompactTrailingView: View {
    let context: ActivityViewContext<BusylightTimerAttributes>
    
    var body: some View {
        Text(String(format: "%02d:%02d", context.state.remainingSeconds / 60, context.state.remainingSeconds % 60))
            .font(.caption.monospacedDigit())
            .foregroundStyle(.primary)
    }
}

struct MinimalView: View {
    let context: ActivityViewContext<BusylightTimerAttributes>
    
    var phase: PomodoroPhase {
        PomodoroPhase(rawValue: context.state.phase) ?? .work
    }
    
    var body: some View {
        Image(systemName: "timer")
            .font(.caption2)
            .foregroundStyle(phase.color)
    }
}
