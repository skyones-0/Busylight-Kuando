//
//  MLModelTests.swift
//  BusylightTests
//

import XCTest
@testable import Busylight

@MainActor
final class MLModelTests: XCTestCase {

    func testDebugBundle() {
        print("📦 Bundle: \(Bundle.main.bundlePath)")

        if let resources = try? FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath) {
            print("📁 Contenido:")
            resources.filter { $0.contains("mlmodel") }.forEach {
                print("   - \($0)")
            }
        }
    }

    func testDayCategoryClassifierWrapperExists() {
        let wrapper = DayCategoryClassifierWrapper.shared
        XCTAssertNotNil(wrapper)
        print("✅ Wrapper inicializado, modelo cargado: \(wrapper.isModelLoaded)")
    }

    func testPredictToday() async {
        let wrapper = DayCategoryClassifierWrapper.shared

        let prediction = await wrapper.predictToday(
            meetings: 5,
            totalMeetingMinutes: 180,
            freeTimeSlots: 3
        )

        XCTAssertNotNil(prediction)

        if let pred = prediction {
            print("🎯 Categoría: \(pred.category.displayName) \(pred.category.emoji)")
            print("🎯 Confianza: \(Int(pred.confidence * 100))%")
            print("🎯 Descripción: \(pred.description)")

            XCTAssertFalse(pred.category.displayName.isEmpty)
            XCTAssertGreaterThan(pred.confidence, 0)
            XCTAssertLessThanOrEqual(pred.confidence, 1.0)
        }
    }

    func testPredictDay() async {
        let wrapper = DayCategoryClassifierWrapper.shared

        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let prediction = await wrapper.predictDay(
            date: futureDate,
            meetings: 8,
            totalMeetingMinutes: 300,
            freeTimeSlots: 1
        )

        XCTAssertNotNil(prediction)

        if let pred = prediction {
            print("📅 Mañana: \(pred.category.displayName) \(pred.category.emoji)")
            XCTAssertFalse(pred.category.displayName.isEmpty)
        }
    }

    func testPredictWithDayInput() async {
        let wrapper = DayCategoryClassifierWrapper.shared

        let input = DayInput(
            dayOfWeek: 2,           // Lunes
            isWeekend: 0,
            isHoliday: 0,
            totalMeetingCount: 3,
            hasImportantDeadline: 0,
            backToBackMeetings: 0,
            freeTimeBlocks: 4,
            meetingDensityScore: 30,
            interruptionRiskScore: 20
        )

        let prediction = await wrapper.predict(input: input)

        XCTAssertNotNil(prediction)

        if let pred = prediction {
            print("🔮 Input manual: \(pred.category.displayName) \(pred.category.emoji)")
        }
    }

    func testWeekendPrediction() async {
        let wrapper = DayCategoryClassifierWrapper.shared

        let saturday = DayInput(
            dayOfWeek: 7,           // Sábado
            isWeekend: 1,
            isHoliday: 0,
            totalMeetingCount: 0,
            hasImportantDeadline: 0,
            backToBackMeetings: 0,
            freeTimeBlocks: 8,
            meetingDensityScore: 0,
            interruptionRiskScore: 0
        )

        let prediction = await wrapper.predict(input: saturday)

        XCTAssertNotNil(prediction)

        if let pred = prediction {
            print("🌴 Fin de semana: \(pred.category.displayName) \(pred.category.emoji)")
            // Debería ser Rest o Calm
            XCTAssertTrue(pred.category == .rest || pred.category == .calm)
        }
    }

    func testBurnoutRiskPrediction() async {
        let wrapper = DayCategoryClassifierWrapper.shared

        let intenseDay = DayInput(
            dayOfWeek: 3,           // Martes
            isWeekend: 0,
            isHoliday: 0,
            totalMeetingCount: 10,
            hasImportantDeadline: 1,
            backToBackMeetings: 1,
            freeTimeBlocks: 0,
            meetingDensityScore: 90,
            interruptionRiskScore: 95
        )

        let prediction = await wrapper.predict(input: intenseDay)

        XCTAssertNotNil(prediction)

        if let pred = prediction {
            print("🚨 Día intenso: \(pred.category.displayName) \(pred.category.emoji)")
        }
    }

    func testPredictionConsistency() async {
        let wrapper = DayCategoryClassifierWrapper.shared

        let input = DayInput(
            dayOfWeek: 2, isWeekend: 0, isHoliday: 0,
            totalMeetingCount: 5, hasImportantDeadline: 0,
            backToBackMeetings: 0, freeTimeBlocks: 3,
            meetingDensityScore: 40, interruptionRiskScore: 30
        )

        let pred1 = await wrapper.predict(input: input)
        let pred2 = await wrapper.predict(input: input)

        XCTAssertEqual(pred1?.category, pred2?.category)
        print("✅ Consistente: \(pred1?.category.displayName ?? "nil")")
    }

    func testStatistics() {
        // Accede directamente al singleton sin asignar a variable
        let stats = DayCategoryClassifierWrapper.shared.getStatistics()

        print("📊 Total predicciones: \(stats.totalPredictions)")
        print("📊 Confianza promedio: \(Int(stats.averageConfidence * 100))%")
        print("📊 Balance score: \(stats.workLifeBalanceScore)/100")

        XCTAssertGreaterThanOrEqual(stats.workLifeBalanceScore, 0)
        XCTAssertLessThanOrEqual(stats.workLifeBalanceScore, 100)
    }

    func testPerformance() async {
        let wrapper = DayCategoryClassifierWrapper.shared
        let input = DayInput(
            dayOfWeek: 2, isWeekend: 0, isHoliday: 0,
            totalMeetingCount: 5, hasImportantDeadline: 0,
            backToBackMeetings: 0, freeTimeBlocks: 3,
            meetingDensityScore: 40, interruptionRiskScore: 30
        )

        // Warm-up (primera carga del modelo)
        _ = await wrapper.predict(input: input)

        // Medición real
        let iterations = 1000
        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            _ = await wrapper.predict(input: input)
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start

        print("📊 Performance: \(iterations) predicciones en \(String(format: "%.3f", elapsed))s")
        print("📊 Latencia promedio: \(String(format: "%.4f", elapsed/Double(iterations)))s")

        // ML en device debería ser < 10ms por predicción
        XCTAssertLessThan(elapsed/Double(iterations), 0.01, "Latencia debe ser < 10ms")
    }
}
