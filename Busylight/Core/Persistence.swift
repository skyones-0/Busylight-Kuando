//
//  Persistence.swift
//  Busylight
//
//  SwiftData persistence controller
//

import SwiftData
import Foundation

@MainActor
class PersistenceController {
    static let shared = PersistenceController()
    
    let container: ModelContainer
    
    init() {
        // Define schema with all models
        let schema = Schema([
            PomodoroSession.self
        ])
        
        // Configure model container
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // Preview container for SwiftUI previews
    static var preview: ModelContainer {
        let schema = Schema([PomodoroSession.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
            // Add sample data for previews
            let context = container.mainContext
            
            let sampleSessions = [
                PomodoroSession(
                    startTime: Date(),
                    durationMinutes: 25,
                    phase: "work",
                    completed: true
                ),
                PomodoroSession(
                    startTime: Date().addingTimeInterval(-3600),
                    durationMinutes: 5,
                    phase: "shortBreak",
                    completed: true
                ),
                PomodoroSession(
                    startTime: Date().addingTimeInterval(-7200),
                    durationMinutes: 25,
                    phase: "work",
                    completed: false
                )
            ]
            
            for session in sampleSessions {
                context.insert(session)
            }
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}

// MARK: - Helper Extensions
extension ModelContext {
    func saveSafely() {
        do {
            try save()
        } catch {
            BusylightLogger.shared.error("Failed to save context: \(error)")
        }
    }
}
