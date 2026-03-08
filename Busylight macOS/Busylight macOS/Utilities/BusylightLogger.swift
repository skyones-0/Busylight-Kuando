import Foundation
import os.log

final class BusylightLogger {
    static let shared = BusylightLogger()
    
    private let logDirectory: URL
    private var currentLogFile: URL
    private var fileHandle: FileHandle?
    private let dateFormatter: DateFormatter
    private let queue = DispatchQueue(label: "com.busylight.logger", qos: .utility)
    private var lastWriteDate: String = ""
    
    private init() {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleId = Bundle.main.bundleIdentifier ?? "co.skyones.Busylight"
        
        self.logDirectory = appSupportURL
            .appendingPathComponent(bundleId, isDirectory: true)
            .appendingPathComponent("Logs", isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true, attributes: nil)
            print("✅ Directorio creado: \(logDirectory.path)")
        } catch {
            print("❌ ERROR creando directorio: \(error)")
        }
        
        self.dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        self.lastWriteDate = dateString
        self.currentLogFile = logDirectory.appendingPathComponent("busy_\(dateString).log")
        
        self.setupFileHandle()
        cleanupOldLogs()
        
        log("=== Logger inicializado ===", level: .info)
    }
    
    private func setupFileHandle() {
        // Cerrar handle anterior si existe
        fileHandle?.closeFile()
        
        if !FileManager.default.fileExists(atPath: currentLogFile.path) {
            FileManager.default.createFile(atPath: currentLogFile.path, contents: nil, attributes: nil)
            print("📝 Archivo creado: \(currentLogFile.path)")
        }
        
        do {
            self.fileHandle = try FileHandle(forWritingTo: currentLogFile)
            try self.fileHandle?.seekToEnd()
            print("✅ FileHandle abierto para: \(currentLogFile.lastPathComponent)")
        } catch {
            print("❌ ERROR abriendo FileHandle: \(error)")
        }
    }
    
    deinit {
        fileHandle?.closeFile()
    }
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = (file as NSString).lastPathComponent
        let logEntry = "[\(timestamp)] [\(level.rawValue)] [\(filename):\(line)] \(function): \(message)"
        
        print("📝 [LOG] \(currentLogFile.path)")
        print("    → \(logEntry)")
        
        // Verificar rotación ANTES de escribir
        let currentDateString = dateFormatter.string(from: Date())
        if currentDateString != lastWriteDate {
            print("🔄 Detectada rotación de fecha: \(lastWriteDate) → \(currentDateString)")
            lastWriteDate = currentDateString
            currentLogFile = logDirectory.appendingPathComponent("busy_\(currentDateString).log")
            setupFileHandle()
        }
        
        // Escribir directamente sin cola para debug (o mantener cola pero con retry)
        guard let data = (logEntry + "\n").data(using: .utf8) else {
            print("❌ No se pudo convertir a data")
            return
        }
        
        // Si no hay handle, intentar recrearlo
        if fileHandle == nil {
            print("⚠️ FileHandle nil, intentando recrear...")
            setupFileHandle()
        }
        
        fileHandle?.write(data)
        fileHandle?.synchronizeFile()
        
        os_log("%{public}@", log: .default, type: level.osLogType, message)
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    private func cleanupOldLogs() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: logDirectory,
                                                                        includingPropertiesForKeys: [.creationDateKey]) else { return }
        
        let cutoffDate = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        
        for file in files {
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                  let creationDate = attributes[.creationDate] as? Date,
                  creationDate < cutoffDate else { continue }
            try? FileManager.default.removeItem(at: file)
        }
    }
    
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .error
            case .error: return .fault
            }
        }
    }
}
