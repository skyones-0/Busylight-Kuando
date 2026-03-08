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
        // Define schema
        let schema = Schema([
            PomodoroSession.self,
            MLWorkPattern.self,
            MLConfiguration.self,
            HolidayCalendar.self
        ])
        
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
        let schema = Schema([
            PomodoroSession.self,
            MLWorkPattern.self,
            MLConfiguration.self,
            HolidayCalendar.self
        ])
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
                    duration: 25 * 60,
                    type: "focus",
                    taskName: "Sample Task 1"
                ),
                PomodoroSession(
                    startTime: Date().addingTimeInterval(-3600),
                    duration: 5 * 60,
                    type: "shortBreak"
                ),
                PomodoroSession(
                    startTime: Date().addingTimeInterval(-7200),
                    duration: 25 * 60,
                    type: "focus",
                    taskName: "Sample Task 2"
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
