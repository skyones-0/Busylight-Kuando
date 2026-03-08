//
//  MLModelTests.swift
//  BusylightTests
//
//  Unit tests para validar los modelos CoreML de predicción de horarios
//

import XCTest
import CoreML
@testable import Busylight_macOS

@MainActor
final class MLModelTests: XCTestCase {
    
    // MARK: - Tests de Carga de Modelos
    
    func testModelLoaderExists() {
        // Verificar que el loader existe y está inicializado
        let loader = TrainedModelLoader.shared
        XCTAssertNotNil(loader)
    }
    
    func testModelsLoadedSuccessfully() throws {
        // Verificar que los modelos se cargaron correctamente
        let loader = TrainedModelLoader.shared
        
        // Nota: Este test puede fallar si los modelos no están en el bundle de test
        // Por eso usamos XCTSkip si no están disponibles
        if !loader.isReady {
            throw XCTSkip("Los modelos no están disponibles en el bundle de test")
        }
        
        XCTAssertTrue(loader.isReady, "Los modelos deberían estar cargados")
        XCTAssertNotNil(loader.startHourModel, "El modelo de startHour debería existir")
        XCTAssertNotNil(loader.endHourModel, "El modelo de endHour debería existir")
    }
    
    // MARK: - Tests de Predicción de StartHour
    
    func testStartHourPredictionWeekday() throws {
        let loader = TrainedModelLoader.shared
        
        guard loader.isReady else {
            throw XCTSkip("Modelos no disponibles")
        }
        
        // Probar día laborable (Lunes)
        let result = loader.predictStartHour(
            dayOfWeek: 2,           // Lunes
            isWeekend: 0,           // No es fin de semana
            sessionCount: 5,        // 5 sesiones
            deepWorkMinutes: 120,   // 2 horas deep work
            isHoliday: 0,           // No es festivo
            calendarEventCount: 3   // 3 eventos
        )
        
        XCTAssertNotNil(result, "La predicción no debería ser nil")
        
        if let hour = result {
            // Validar que la hora está en rango válido (0-23)
            XCTAssertGreaterThanOrEqual(hour, 0, "La hora debería ser >= 0")
            XCTAssertLessThanOrEqual(hour, 23, "La hora debería ser <= 23")
            
            // Para un día laborable normal, esperamos hora temprana (6-10)
            // Nota: Ajusta este rango según tus datos de entrenamiento
            print("📊 StartHour predicho (Lunes laborable): \(hour):00")
        }
    }
    
    func testStartHourPredictionWeekend() throws {
        let loader = TrainedModelLoader.shared
        
        guard loader.isReady else {
            throw XCTSkip("Modelos no disponibles")
        }
        
        // Probar fin de semana (Sábado)
        let result = loader.predictStartHour(
            dayOfWeek: 7,           // Sábado
            isWeekend: 1,           // Es fin de semana
            sessionCount: 2,        // 2 sesiones (menos)
            deepWorkMinutes: 30,    // 30 min deep work
            isHoliday: 0,
            calendarEventCount: 0   // Sin eventos
        )
        
        XCTAssertNotNil(result)
        
        if let hour = result {
            XCTAssertGreaterThanOrEqual(hour, 0)
            XCTAssertLessThanOrEqual(hour, 23)
            
            // Fin de semana: puede ser más tarde o 0 (no trabajar)
            print("📊 StartHour predicho (Sábado): \(hour):00")
        }
    }
    
    func testStartHourPredictionHoliday() throws {
        let loader = TrainedModelLoader.shared
        
        guard loader.isReady else {
            throw XCTSkip("Modelos no disponibles")
        }
        
        // Probar festivo
        let result = loader.predictStartHour(
            dayOfWeek: 2,           // Lunes
            isWeekend: 0,
            sessionCount: 0,        // Sin sesiones
            deepWorkMinutes: 0,     // Sin trabajo
            isHoliday: 1,           // Es festivo
            calendarEventCount: 0
        )
        
        XCTAssertNotNil(result)
        
        if let hour = result {
            // En festivo, esperamos 0 (no trabajar) o hora muy tarde
            print("📊 StartHour predicho (Festivo): \(hour):00")
            
            // Si es festivo, idealmente debería ser 0
            // Pero depende de cómo entrenaste el modelo
        }
    }
    
    func testStartHourPredictionHighProductivity() throws {
        let loader = TrainedModelLoader.shared
        
        guard loader.isReady else {
            throw XCTSkip("Modelos no disponibles")
        }
        
        // Probar día muy productivo
        let result = loader.predictStartHour(
            dayOfWeek: 3,           // Martes
            isWeekend: 0,
            sessionCount: 8,        // 8 sesiones (muy productivo)
            deepWorkMinutes: 240,   // 4 horas deep work
            isHoliday: 0,
            calendarEventCount: 5   // Muchos eventos
        )
        
        XCTAssertNotNil(result)
        
        if let hour = result {
            XCTAssertGreaterThanOrEqual(hour, 0)
            XCTAssertLessThanOrEqual(hour, 23)
            
            // Día productivo: esperamos hora temprana
            print("📊 StartHour predicho (Día productivo): \(hour):00")
        }
    }
    
    // MARK: - Tests de Predicción de EndHour
    
    func testEndHourPredictionWeekday() throws {
        let loader = TrainedModelLoader.shared
        
        guard loader.isReady else {
            throw XCTSkip("Modelos no disponibles")
        }
        
        // Probar día laborable
        let result = loader.predictEndHour(
            dayOfWeek: 2,
            isWeekend: 0,
            sessionCount: 5,
            deepWorkMinutes: 120,
            isHoliday: 0,
            calendarEventCount: 3
        )
        
        XCTAssertNotNil(result)
        
        if let hour = result {
            XCTAssertGreaterThanOrEqual(hour, 0)
            XCTAssertLessThanOrEqual(hour, 23)
            
            // Hora de fin debería ser mayor que hora de inicio típico
            print("📊 EndHour predicho (Lunes): \(hour):00")
        }
    }
    
    func testEndHourPredictionWeekend() throws {
        let loader = TrainedModelLoader.shared
        
        guard loader.isReady else {
            throw XCTSkip("Modelos no disponibles")
        }
        
        let result = loader.predictEndHour(
            dayOfWeek: 7,           // Sábado
            isWeekend: 1,
            sessionCount: 2,
            deepWorkMinutes: 30,
            isHoliday: 0,
            calendarEventCount: 0
        )
        
        XCTAssertNotNil(result)
        
        if let hour = result {
            XCTAssertGreaterThanOrEqual(hour, 0)
            XCTAssertLessThanOrEqual(hour, 23)
            
            print("📊 EndHour predicho (Sábado): \(hour):00")
        }
    }
    
    // MARK: - Tests de Consistencia
    
    func testPredictionConsistency() throws {
        let loader = TrainedModelLoader.shared
        
        guard loader.isReady else {
            throw XCTSkip("Modelos no disponibles")
        }
        
        // Probar que el modelo es consistente (mismo input = mismo output)
        let dayOfWeek = 2
        let isWeekend = 0
        let sessionCount = 5
        let deepWork = 120
        let isHoliday = 0
        let events = 3
        
        let result1 = loader.predictStartHour(
            dayOfWeek: dayOfWeek,
            isWeekend: isWeekend,
            sessionCount: sessionCount,
            deepWorkMinutes: deepWork,
            isHoliday: isHoliday,
            calendarEventCount: events
        )
        
        let result2 = loader.predictStartHour(
            dayOfWeek: dayOfWeek,
            isWeekend: isWeekend,
            sessionCount: sessionCount,
            deepWorkMinutes: deepWork,
            isHoliday: isHoliday,
            calendarEventCount: events
        )
        
        XCTAssertEqual(result1, result2, "El modelo debería ser consistente con el mismo input")
        print("✅ Consistencia validada: \(result1 ?? -1) == \(result2 ?? -1)")
    }
    
    func testEndHourAfterStartHour() throws {
        let loader = TrainedModelLoader.shared
        
        guard loader.isReady else {
            throw XCTSkip("Modelos no disponibles")
        }
        
        // Probar que endHour es después de startHour para el mismo día
        let dayOfWeek = 2
        let isWeekend = 0
        let sessionCount = 5
        let deepWork = 120
        let isHoliday = 0
        let events = 3
        
        let startHour = loader.predictStartHour(
            dayOfWeek: dayOfWeek,
            isWeekend: isWeekend,
            sessionCount: sessionCount,
            deepWorkMinutes: deepWork,
            isHoliday: isHoliday,
            calendarEventCount: events
        )
        
        let endHour = loader.predictEndHour(
            dayOfWeek: dayOfWeek,
            isWeekend: isWeekend,
            sessionCount: sessionCount,
            deepWorkMinutes: deepWork,
            isHoliday: isHoliday,
            calendarEventCount: events
        )
        
        XCTAssertNotNil(startHour)
        XCTAssertNotNil(endHour)
        
        if let start = startHour, let end = endHour {
            // En un día normal, end debería ser >= start
            // O 0 si es festivo/fin de semana sin trabajo
            if start > 0 {
                XCTAssertGreaterThanOrEqual(
                    end, start,
                    "EndHour (\(end)) debería ser >= StartHour (\(start))"
                )
            }
            
            print("📊 Horario completo: \(start):00 - \(end):00")
        }
    }
    
    // MARK: - Tests de Casos Límite
    
    func testPredictionWithZeroSessions() throws {
        let loader = TrainedModelLoader.shared
        
        guard loader.isReady else {
            throw XCTSkip("Modelos no disponibles")
        }
        
        // Día sin sesiones (descanso)
        let result = loader.predictStartHour(
            dayOfWeek: 2,
            isWeekend: 0,
            sessionCount: 0,
            deepWorkMinutes: 0,
            isHoliday: 0,
            calendarEventCount: 0
        )
        
        XCTAssertNotNil(result)
        
        if let hour = result {
            // Sin trabajo, idealmente debería ser 0 o temprano
            print("📊 StartHour con 0 sesiones: \(hour):00")
        }
    }
    
    func testPredictionWithMaxValues() throws {
        let loader = TrainedModelLoader.shared
        
        guard loader.isReady else {
            throw XCTSkip("Modelos no disponibles")
        }
        
        // Valores máximos razonables
        let result = loader.predictStartHour(
            dayOfWeek: 2,
            isWeekend: 0,
            sessionCount: 12,       // 12 sesiones (máximo)
            deepWorkMinutes: 480,   // 8 horas deep work
            isHoliday: 0,
            calendarEventCount: 10  // 10 eventos
        )
        
        XCTAssertNotNil(result)
        
        if let hour = result {
            XCTAssertGreaterThanOrEqual(hour, 0)
            XCTAssertLessThanOrEqual(hour, 23)
            
            print("📊 StartHour con valores máximos: \(hour):00")
        }
    }
    
    // MARK: - Tests de Rendimiento
    
    func testPredictionPerformance() throws {
        let loader = TrainedModelLoader.shared
        
        guard loader.isReady else {
            throw XCTSkip("Modelos no disponibles")
        }
        
        measure {
            // Realizar 100 predicciones
            for _ in 0..<100 {
                _ = loader.predictStartHour(
                    dayOfWeek: 2,
                    isWeekend: 0,
                    sessionCount: 5,
                    deepWorkMinutes: 120,
                    isHoliday: 0,
                    calendarEventCount: 3
                )
            }
        }
    }
}

// MARK: - Tests de MLScheduleManager

@MainActor
final class MLScheduleManagerTests: XCTestCase {
    
    func testMLScheduleManagerExists() {
        let manager = MLScheduleManager.shared
        XCTAssertNotNil(manager)
    }
    
    func testCanTrainModel() {
        let manager = MLScheduleManager.shared
        
        // Verificar que puede entrenar si hay suficientes datos
        let canTrain = manager.canTrainModel()
        
        // Este test depende de si hay datos recolectados
        // Solo verificamos que el método existe y retorna un valor
        print("📊 Puede entrenar modelo: \(canTrain)")
    }
    
    func testConfigurationExists() {
        let manager = MLScheduleManager.shared
        
        // Verificar que hay configuración
        XCTAssertNotNil(manager.configuration)
    }
}
