//
//  WebhookServer.swift
//  Busylight
//
//  Local HTTP API for external integrations
//

import Foundation
import Network
import Combine
import SwiftUI

class WebhookServer: ObservableObject {
    static let shared = WebhookServer()
    
    @Published var isRunning = false
    @Published var lastRequest: String = ""
    @Published var requestCount: Int = 0
    
    private var listener: NWListener?
    private let port: UInt16 = 8080
    private var connections = [NWConnection]()
    
    var serverEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "webhookServerEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "webhookServerEnabled") }
    }
    
    var authToken: String {
        get { UserDefaults.standard.string(forKey: "webhookAuthToken") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "webhookAuthToken") }
    }
    
    private init() {}
    
    func start() {
        guard serverEnabled, !isRunning else { return }
        
        do {
            let parameters = NWParameters.tcp
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: port))
            
            listener?.stateUpdateHandler = { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .ready:
                    DispatchQueue.main.async { self.isRunning = true }
                    print("Webhook server started on port \(self.port)")
                case .failed(let error):
                    print("Webhook server failed: \(error)")
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.start(queue: .global())
            
        } catch {
            print("Failed to start webhook server: \(error)")
        }
    }
    
    func stop() {
        listener?.cancel()
        connections.forEach { $0.cancel() }
        connections.removeAll()
        DispatchQueue.main.async { self.isRunning = false }
        print("Webhook server stopped")
    }
    
    private func handleConnection(_ connection: NWConnection) {
        DispatchQueue.main.async { self.connections.append(connection) }
        
        connection.stateUpdateHandler = { [weak self] state in
            if case .failed = state {
                DispatchQueue.main.async {
                    self?.connections.removeAll { $0 === connection }
                }
            }
        }
        
        connection.start(queue: .global())
        receiveData(from: connection)
    }
    
    private func receiveData(from connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let data = data, let request = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.lastRequest = String(request.prefix(100))
                    self.requestCount += 1
                }
                self.processRequest(request, connection: connection)
            }
            
            if isComplete {
                connection.cancel()
                DispatchQueue.main.async {
                    self.connections.removeAll { $0 === connection }
                }
            } else if error == nil {
                self.receiveData(from: connection)
            }
        }
    }
    
    private func processRequest(_ request: String, connection: NWConnection) {
        // Parse HTTP request
        let lines = request.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else {
            sendResponse("HTTP/1.1 400 Bad Request\r\n\r\n", to: connection)
            return
        }
        
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            sendResponse("HTTP/1.1 400 Bad Request\r\n\r\n", to: connection)
            return
        }
        
        let method = parts[0]
        let path = parts[1]
        
        // Check auth token if configured
        if !authToken.isEmpty {
            let hasAuth = lines.contains { $0.lowercased().contains("authorization: bearer \(authToken)") }
            if !hasAuth {
                sendResponse("""
                    HTTP/1.1 401 Unauthorized\r\n
                    Content-Type: application/json\r\n
                    \r\n
                    {"error": "Unauthorized"}
                    """, to: connection)
                return
            }
        }
        
        // Handle endpoints
        var response = ""
        
        switch (method, path) {
        case ("GET", "/status"):
            response = handleGetStatus()
            
        case ("POST", "/color"):
            if let body = request.components(separatedBy: "\r\n\r\n").last,
               let data = body.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                response = handleSetColor(json)
            } else {
                response = jsonResponse(status: 400, data: ["error": "Invalid JSON"])
            }
            
        case ("POST", "/status"):
            if let body = request.components(separatedBy: "\r\n\r\n").last,
               let data = body.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                response = handleSetStatus(json)
            } else {
                response = jsonResponse(status: 400, data: ["error": "Invalid JSON"])
            }
            
        case ("POST", "/timer/start"):
            DispatchQueue.main.async {
                PomodoroManager.shared.start()
            }
            response = jsonResponse(status: 200, data: ["message": "Timer started"])
            
        case ("POST", "/timer/pause"):
            DispatchQueue.main.async {
                PomodoroManager.shared.pause()
            }
            response = jsonResponse(status: 200, data: ["message": "Timer paused"])
            
        case ("POST", "/timer/stop"):
            DispatchQueue.main.async {
                PomodoroManager.shared.stop()
            }
            response = jsonResponse(status: 200, data: ["message": "Timer stopped"])
            
        case ("GET", "/"):
            response = handleGetDocs()
            
        default:
            response = jsonResponse(status: 404, data: ["error": "Not found"])
        }
        
        sendResponse(response, to: connection)
    }
    
    private func handleGetStatus() -> String {
        let data: [String: Any] = [
            "api": "Busylight",
            "version": "1.0",
            "endpoints": [
                "GET /status": "Get current status",
                "POST /color": "Set light color",
                "POST /status": "Set presence status",
                "POST /timer/start": "Start timer",
                "POST /timer/pause": "Pause timer",
                "POST /timer/stop": "Stop timer"
            ]
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonResponse(status: 200, body: jsonString)
        }
        
        return jsonResponse(status: 500, data: ["error": "Failed to encode status"])
    }
    
    private func handleSetColor(_ json: [String: Any]) -> String {
        guard let color = json["color"] as? String else {
            return jsonResponse(status: 400, data: ["error": "Missing 'color' field"])
        }
        
        DispatchQueue.main.async {
            let light = BusylightManager.shared
            switch color.lowercased() {
            case "red": light.red()
            case "green": light.green()
            case "blue": light.blue()
            case "yellow": light.yellow()
            case "cyan": light.cyan()
            case "magenta", "pink": light.magenta()
            case "white": light.white()
            case "orange": light.orange()
            case "purple": light.purple()
            case "off": light.off()
            default: break
            }
        }
        
        return jsonResponse(status: 200, data: ["message": "Color set to \(color)"])
    }
    
    private func handleSetStatus(_ json: [String: Any]) -> String {
        guard let status = json["status"] as? String else {
            return jsonResponse(status: 400, data: ["error": "Missing 'status' field"])
        }
        
        DispatchQueue.main.async {
            let light = BusylightManager.shared
            switch status.lowercased() {
            case "available", "free":
                light.green()
            case "busy", "occupied":
                light.red()
            case "away", "afk":
                light.orange()
            case "dnd", "donotdisturb":
                light.pulseRed()
            default: break
            }
        }
        
        return jsonResponse(status: 200, data: ["message": "Status set to \(status)"])
    }
    
    private func handleGetDocs() -> String {
        let docs = """
        {
            "name": "Busylight API",
            "version": "1.0",
            "endpoints": [
                {"method": "GET", "path": "/status", "description": "Get current timer and light status"},
                {"method": "POST", "path": "/color", "body": {"color": "red|green|blue|..."}, "description": "Set light color"},
                {"method": "POST", "path": "/status", "body": {"status": "available|busy|away|dnd"}, "description": "Set presence status"},
                {"method": "POST", "path": "/timer/start", "description": "Start pomodoro timer"},
                {"method": "POST", "path": "/timer/pause", "description": "Pause pomodoro timer"},
                {"method": "POST", "path": "/timer/stop", "description": "Stop pomodoro timer"}
            ]
        }
        """
        return jsonResponse(status: 200, body: docs)
    }
    
    private func jsonResponse(status: Int, data: [String: Any]) -> String {
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonResponse(status: status, body: jsonString)
        }
        return "HTTP/1.1 \(status)\r\n\r\n"
    }
    
    private func jsonResponse(status: Int, body: String) -> String {
        return """
            HTTP/1.1 \(status)\r\n
            Content-Type: application/json\r\n
            Content-Length: \(body.utf8.count)\r\n
            \r\n
            \(body)
            """
    }
    
    private func sendResponse(_ response: String, to connection: NWConnection) {
        let data = Data(response.utf8)
        connection.send(content: data, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
