//
//  TrainedModelLoader.swift
//  Busylight
//
//  Carga modelos entrenados en Create ML (.mlpackage)
//

import Foundation
import CoreML
import Combine

/// Carga y usa modelos entrenados en Create ML
@MainActor
class TrainedModelLoader: ObservableObject {
    static let shared = TrainedModelLoader()
    
    @Published var isReady = false
    @Published var startHourModel: MLModel?
    @Published var endHourModel: MLModel?
    
    // Nombres de los archivos (sin extensión)
    // Tus modelos se llaman: StartHours.mlmodelc y EndHours.mlmodelc
    private let startModelName = "StartHours"
    private let endModelName = "EndHours"
    
    private init() {
        loadModels()
    }
    
    /// Carga los modelos desde el bundle de la app
    func loadModels() {
        BusylightLogger.shared.info(String(repeating: "=", count: 50))
        BusylightLogger.shared.info("🔧 INICIANDO CARGA DE MODELOS COREML")
        BusylightLogger.shared.info("   Buscando: \(startModelName).mlmodelc y \(endModelName).mlmodelc")
        BusylightLogger.shared.info(String(repeating: "=", count: 50))
        
        // Estrategia 1: Buscar ML Package (.mlpackage) - Xcode 14+
        BusylightLogger.shared.info("\n📦 ESTRATEGIA 1: Buscando .mlpackage...")
        if tryLoadMLPackages() {
            BusylightLogger.shared.info("✅ ÉXITO: Modelos .mlpackage cargados\n")
            return
        }
        BusylightLogger.shared.info("❌ FALLÓ: No se encontraron .mlpackage")
        
        // Estrategia 2: Buscar archivos .mlmodelc compilados
        BusylightLogger.shared.info("\n📁 ESTRATEGIA 2: Buscando .mlmodelc...")
        if tryLoadCompiledModels() {
            BusylightLogger.shared.info("✅ ÉXITO: Modelos .mlmodelc cargados\n")
            return
        }
        BusylightLogger.shared.info("❌ FALLÓ: No se encontraron .mlmodelc")
        
        // Estrategia 3: Buscar archivos .mlmodel y compilarlos
        BusylightLogger.shared.info("\n📄 ESTRATEGIA 3: Buscando .mlmodel...")
        if tryLoadAndCompileModels() {
            BusylightLogger.shared.info("✅ ÉXITO: Modelos .mlmodel compilados y cargados\n")
            return
        }
        BusylightLogger.shared.info("❌ FALLÓ: No se encontraron .mlmodel")
        
        // Estrategia 4: Listar todos los recursos del bundle para debug
        BusylightLogger.shared.info("\n🔍 ESTRATEGIA 4: Listando recursos disponibles...")
        logAvailableResources()
        
        BusylightLogger.shared.error("")
        BusylightLogger.shared.error(String(repeating: "=", count: 50))
        BusylightLogger.shared.error("❌ ERROR: NO SE PUDIERON CARGAR LOS MODELOS")
        BusylightLogger.shared.error("   Nombres esperados: \(startModelName), \(endModelName)")
        BusylightLogger.shared.error(String(repeating: "=", count: 50))
    }
    
    /// Intenta cargar ML Packages (.mlpackage) - formato Xcode 14+
    private func tryLoadMLPackages() -> Bool {
        BusylightLogger.shared.info("   Probando nombres: \(startModelName), \(endModelName)")
        
        do {
            let bundle = Bundle.main
            
            // Buscar .mlpackage
            if let startURL = bundle.url(forResource: startModelName, withExtension: "mlpackage") {
                BusylightLogger.shared.info("   ✅ Encontrado: \(startModelName).mlpackage")
                
                if let endURL = bundle.url(forResource: endModelName, withExtension: "mlpackage") {
                    BusylightLogger.shared.info("   ✅ Encontrado: \(endModelName).mlpackage")
                    
                    let config = MLModelConfiguration()
                    config.computeUnits = .cpuAndNeuralEngine
                    
                    BusylightLogger.shared.info("   ⏳ Cargando modelos desde packages...")
                    startHourModel = try MLModel(contentsOf: startURL, configuration: config)
                    endHourModel = try MLModel(contentsOf: endURL, configuration: config)
                    isReady = true
                    
                    BusylightLogger.shared.info("   ✅ Modelos cargados desde .mlpackage")
                    return true
                } else {
                    BusylightLogger.shared.warning("   ❌ No se encontró \(endModelName).mlpackage")
                }
            } else {
                BusylightLogger.shared.info("   ℹ️ No se encontraron archivos .mlpackage")
            }
        } catch {
            BusylightLogger.shared.error("   ❌ Error cargando ML Packages: \(error.localizedDescription)")
        }
        return false
    }
    
    /// Intenta cargar modelos ya compilados (.mlmodelc)
    private func tryLoadCompiledModels() -> Bool {
        BusylightLogger.shared.info("🔍 Buscando modelos .mlmodelc con nombres: \(startModelName) y \(endModelName)")
        
        do {
            let bundle = Bundle.main
            
            // Buscar el modelo de inicio
            guard let startURL = bundle.url(forResource: startModelName, withExtension: "mlmodelc") else {
                BusylightLogger.shared.warning("❌ No se encontró \(startModelName).mlmodelc")
                return false
            }
            BusylightLogger.shared.info("✅ Encontrado: \(startModelName).mlmodelc en \(startURL.path)")
            
            // Buscar el modelo de fin
            guard let endURL = bundle.url(forResource: endModelName, withExtension: "mlmodelc") else {
                BusylightLogger.shared.warning("❌ No se encontró \(endModelName).mlmodelc")
                return false
            }
            BusylightLogger.shared.info("✅ Encontrado: \(endModelName).mlmodelc en \(endURL.path)")
            
            // Intentar cargar los modelos
            BusylightLogger.shared.info("⏳ Cargando modelos en memoria...")
            
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine
            
            BusylightLogger.shared.info("   - Cargando \(startModelName)...")
            startHourModel = try MLModel(contentsOf: startURL, configuration: config)
            BusylightLogger.shared.info("   ✅ \(startModelName) cargado correctamente")
            
            BusylightLogger.shared.info("   - Cargando \(endModelName)...")
            endHourModel = try MLModel(contentsOf: endURL, configuration: config)
            BusylightLogger.shared.info("   ✅ \(endModelName) cargado correctamente")
            
            isReady = true
            BusylightLogger.shared.info("🎉 AMBOS MODELOS CARGADOS EXITOSAMENTE - Listos para usar!")
            return true
            
        } catch {
            BusylightLogger.shared.error("❌ ERROR al cargar modelos: \(error.localizedDescription)")
            BusylightLogger.shared.error("   Detalle: \(error)")
            return false
        }
    }
    
    /// Intenta cargar archivos .mlmodel y compilarlos
    private func tryLoadAndCompileModels() -> Bool {
        BusylightLogger.shared.info("   Probando nombres: \(startModelName), \(endModelName)")
        
        do {
            let bundle = Bundle.main
            
            if let startURL = bundle.url(forResource: startModelName, withExtension: "mlmodel") {
                BusylightLogger.shared.info("   ✅ Encontrado: \(startModelName).mlmodel")
                
                if let endURL = bundle.url(forResource: endModelName, withExtension: "mlmodel") {
                    BusylightLogger.shared.info("   ✅ Encontrado: \(endModelName).mlmodel")
                    BusylightLogger.shared.info("   ⏳ Compilando modelos...")
                    
                    let startCompiled = try MLModel.compileModel(at: startURL)
                    let endCompiled = try MLModel.compileModel(at: endURL)
                    
                    let config = MLModelConfiguration()
                    startHourModel = try MLModel(contentsOf: startCompiled, configuration: config)
                    endHourModel = try MLModel(contentsOf: endCompiled, configuration: config)
                    isReady = true
                    
                    BusylightLogger.shared.info("   ✅ Modelos .mlmodel compilados y cargados")
                    return true
                } else {
                    BusylightLogger.shared.warning("   ❌ No se encontró \(endModelName).mlmodel")
                }
            } else {
                BusylightLogger.shared.info("   ℹ️ No se encontraron archivos .mlmodel")
            }
        } catch {
            BusylightLogger.shared.error("   ❌ Error compilando .mlmodel: \(error.localizedDescription)")
        }
        return false
    }
    
    /// Lista todos los recursos del bundle para debug
    private func logAvailableResources() {
        BusylightLogger.shared.info("📋 ARCHIVOS DE MODELO ENCONTRADOS:")
        
        if let resourcePath = Bundle.main.resourcePath {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                let modelFiles = files.filter { 
                    $0.hasSuffix(".mlpackage") || 
                    $0.hasSuffix(".mlmodel") || 
                    $0.hasSuffix(".mlmodelc") 
                }
                
                if modelFiles.isEmpty {
                    BusylightLogger.shared.warning("   ⚠️ NO HAY ARCHIVOS .mlpackage, .mlmodel o .mlmodelc")
                    BusylightLogger.shared.info("\n   📁 Primeros 30 archivos en el bundle:")
                    for file in files.prefix(30) {
                        BusylightLogger.shared.info("      - \(file)")
                    }
                } else {
                    BusylightLogger.shared.info("   ✅ Archivos de modelo encontrados:")
                    for file in modelFiles {
                        BusylightLogger.shared.info("      → \(file)")
                    }
                    
                    // Verificar específicamente los que buscamos
                    BusylightLogger.shared.info("\n   🔍 Verificando nombres específicos:")
                    let hasStart = modelFiles.contains { $0 == "\(startModelName).mlmodelc" || $0 == "\(startModelName).mlpackage" || $0 == "\(startModelName).mlmodel" }
                    let hasEnd = modelFiles.contains { $0 == "\(endModelName).mlmodelc" || $0 == "\(endModelName).mlpackage" || $0 == "\(endModelName).mlmodel" }
                    
                    BusylightLogger.shared.info("      \(startModelName): \(hasStart ? "✅ ENCONTRADO" : "❌ NO ENCONTRADO")")
                    BusylightLogger.shared.info("      \(endModelName): \(hasEnd ? "✅ ENCONTRADO" : "❌ NO ENCONTRADO")")
                }
            } catch {
                BusylightLogger.shared.error("   ❌ Error listando recursos: \(error)")
            }
        } else {
            BusylightLogger.shared.error("   ❌ No se pudo acceder al resourcePath del bundle")
        }
    }
    
    /// Predice hora de inicio
    func predictStartHour(
        dayOfWeek: Int,
        isWeekend: Int,
        sessionCount: Int,
        deepWorkMinutes: Int,
        isHoliday: Int = 0,
        calendarEventCount: Int = 3
    ) -> Int? {
        guard let model = startHourModel else { return nil }
        
        let input: [String: Any] = [
            "dayOfWeek": dayOfWeek,
            "isWeekend": isWeekend,
            "isHoliday": isHoliday,
            "sessionCount": sessionCount,
            "deepWorkMinutes": deepWorkMinutes,
            "calendarEventCount": calendarEventCount
        ]
        
        do {
            BusylightLogger.shared.debug("🧪 Prediciendo startHour con: dayOfWeek=\(dayOfWeek), isWeekend=\(isWeekend), isHoliday=\(isHoliday), sessions=\(sessionCount), deepWork=\(deepWorkMinutes), events=\(calendarEventCount)")
            let provider = try MLDictionaryFeatureProvider(dictionary: input)
            let output = try model.prediction(from: provider)
            let result = Int(output.featureValue(for: "startHour")?.doubleValue ?? 0)
            BusylightLogger.shared.info("✅ Predicción startHour: \(result):00")
            return result
        } catch {
            BusylightLogger.shared.error("❌ Error en predicción startHour: \(error)")
            return nil
        }
    }
    
    /// Predice hora de fin
    func predictEndHour(
        dayOfWeek: Int,
        isWeekend: Int,
        sessionCount: Int,
        deepWorkMinutes: Int,
        isHoliday: Int = 0,
        calendarEventCount: Int = 3
    ) -> Int? {
        guard let model = endHourModel else { return nil }
        
        let input: [String: Any] = [
            "dayOfWeek": dayOfWeek,
            "isWeekend": isWeekend,
            "isHoliday": isHoliday,
            "sessionCount": sessionCount,
            "deepWorkMinutes": deepWorkMinutes,
            "calendarEventCount": calendarEventCount
        ]
        
        do {
            BusylightLogger.shared.debug("🧪 Prediciendo endHour con: dayOfWeek=\(dayOfWeek), isWeekend=\(isWeekend), isHoliday=\(isHoliday), sessions=\(sessionCount), deepWork=\(deepWorkMinutes), events=\(calendarEventCount)")
            let provider = try MLDictionaryFeatureProvider(dictionary: input)
            let output = try model.prediction(from: provider)
            let result = Int(output.featureValue(for: "endHour")?.doubleValue ?? 0)
            BusylightLogger.shared.info("✅ Predicción endHour: \(result):00")
            return result
        } catch {
            BusylightLogger.shared.error("❌ Error en predicción endHour: \(error)")
            return nil
        }
    }
}
