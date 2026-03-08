//
//  SessionsView.swift
//  Busylight iOS
//

import SwiftUI
import SwiftData
import BusylightShared

struct SessionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PomodoroSession.startTime, order: .reverse) private var sessions: [PomodoroSession]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(groupedSessions.keys.sorted(by: >), id: \.self) { date in
                    Section(header: Text(date, style: .date)) {
                        ForEach(groupedSessions[date] ?? []) { session in
                            SessionRow(session: session)
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
    
    private var groupedSessions: [Date: [PomodoroSession]] {
        Dictionary(grouping: sessions) { session in
            Calendar.current.startOfDay(for: session.startTime)
        }
    }
}

struct SessionRow: View {
    let session: PomodoroSession
    
    var body: some View {
        HStack {
            // Icon
            ZStack {
                Circle()
                    .fill(session.type == "focus" ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: session.type == "focus" ? "brain" : "cup.and.saucer")
                    .foregroundStyle(session.type == "focus" ? .red : .green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.taskName ?? (session.type == "focus" ? "Focus Session" : "Break"))
                    .font(.body.weight(.medium))
                
                HStack {
                    Text(session.startTime, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if session.completed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            Spacer()
            
            Text(formatDuration(session.duration))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}
