//
//  BusylightManager.swift
//  Busylight
//
//  Manager for Busylight USB device control via HID protocol.
//  Handles color changes, jingles, and connection state.
//
//  Relationships:
//  - Used by: PomodoroManager (timer colors), SmartFeaturesManager (calendar/focus colors)
//  - Notifications: Posts BusylightColorChanged notification
//  - See: DeviceView.swift for manual color controls
//

import Foundation
import SwiftUI
import Combine

#if !TESTING
import BusylightSDK_Swift
#endif

class BusylightManager: ObservableObject {
    static let shared = BusylightManager()
    
    #if !TESTING
    private var bl: Busylight?
    #else
    private var bl: Any? // Mock para tests
    #endif
    
    @Published var color: Color = .gray
    @Published var status = "No device"
    @Published var isConnected = false
    @Published var deviceName = "No Busylight connected"
    @Published var deviceModel = ""
    
    init() {
        setupBusylight()
    }
    
    func setupBusylight() {
        #if !TESTING
        bl = Busylight()
        bl?.delegate = self
        bl?.start()
        #endif
        checkDevices()
    }
    
    func checkDevices() {
        #if !TESTING
        let devices = bl?.getDevicesArray() ?? []
        print("Dispositivos encontrados: \(devices.count)")
        
        if let firstDevice = devices.first as? [String: String],
           let deviceKey = firstDevice.keys.first {
            
            isConnected = true
            status = "Connected"
            deviceName = deviceKey
            deviceModel = ""
            
            print("Primer dispositivo: \(deviceKey)")
        } else {
            isConnected = false
            status = "Disconnected"
            deviceName = "No Busylight connected"
            deviceModel = ""
        }
        #else
        // Mock para tests
        isConnected = false
        status = "Disconnected (Test Mode)"
        deviceName = "No Busylight connected"
        deviceModel = ""
        #endif
    }
    
    func red() {
        #if !TESTING
        bl?.Light(red: 100, green: 0, blue: 0)
        #endif
        color = .red
        status = "Red"
    }
    
    func green() {
        #if !TESTING
        bl?.Light(red: 0, green: 100, blue: 0)
        #endif
        color = .green
        status = "Green"
    }
    
    func yellow() {
        #if !TESTING
        bl?.Pulse(red: 100, green: 100, blue: 0)
        #endif
        color = .yellow
        status = "Yellow Pulse"
    }
    
    func blue() {
        #if !TESTING
        bl?.Light(red: 0, green: 0, blue: 100)
        #endif
        color = Color(red: 0, green: 0, blue: 1)
        status = "Blue"
    }
    
    func cyan() {
        #if !TESTING
        bl?.Light(red: 0, green: 100, blue: 100)
        #endif
        color = Color(red: 0, green: 1, blue: 1)
        status = "Cyan"
    }

    func magenta() {
        #if !TESTING
        bl?.Light(red: 100, green: 0, blue: 100)
        #endif
        color = Color(red: 1, green: 0, blue: 1)
        status = "Magenta"
    }

    func white() {
        #if !TESTING
        bl?.Light(red: 100, green: 100, blue: 100)
        #endif
        color = .white
        status = "White"
    }

    func orange() {
        #if !TESTING
        bl?.Light(red: 100, green: 65, blue: 0)
        #endif
        color = .orange
        status = "Orange"
    }

    func purple() {
        #if !TESTING
        bl?.Light(red: 75, green: 0, blue: 100)
        #endif
        color = .purple
        status = "Purple"
    }

    func pink() {
        #if !TESTING
        bl?.Light(red: 100, green: 75, blue: 80)
        #endif
        color = .pink
        status = "Pink"
    }
    
    // ============================================
    // EFECTOS PULSE
    // ============================================
        
    func pulseRed() {
        #if !TESTING
        bl?.Pulse(red: 100, green: 0, blue: 0)
        #endif
        color = .red
        status = "Red Pulse"
    }
        
    func pulseGreen() {
        #if !TESTING
        bl?.Pulse(red: 0, green: 100, blue: 0)
        #endif
        color = .green
        status = "Green Pulse"
    }
        
    func pulseBlue() {
        #if !TESTING
        bl?.Pulse(red: 0, green: 0, blue: 100)
        #endif
        color = .blue
        status = "Blue Pulse"
    }
        
    func pulseYellow() {
        #if !TESTING
        bl?.Pulse(red: 100, green: 100, blue: 0)
        #endif
        color = .yellow
        status = "Yellow Pulse"
    }
        
    func pulseCyan() {
        #if !TESTING
        bl?.Pulse(red: 0, green: 100, blue: 100)
        #endif
        color = Color(red: 0, green: 1, blue: 1)
        status = "Cyan Pulse"
    }
        
    func pulseMagenta() {
        #if !TESTING
        bl?.Pulse(red: 100, green: 0, blue: 100)
        #endif
        color = Color(red: 1, green: 0, blue: 1)
        status = "Magenta Pulse"
    }
        
    func pulseWhite() {
        #if !TESTING
        bl?.Pulse(red: 100, green: 100, blue: 100)
        #endif
        color = .white
        status = "White Pulse"
    }
        
    // ============================================
    // EFECTOS BLINK
    // ============================================
        
    func blinkRedSlow() {
        #if !TESTING
        bl?.Blink(red: 100, green: 0, blue: 0, ontime: 10, offtime: 10)
        #endif
        color = .red
        status = "Red Blink Slow"
    }
        
    func blinkRedMedium() {
        #if !TESTING
        bl?.Blink(red: 100, green: 0, blue: 0, ontime: 5, offtime: 5)
        #endif
        color = .red
        status = "Red Blink Medium"
    }
        
    func blinkRedFast() {
        #if !TESTING
        bl?.Blink(red: 100, green: 0, blue: 0, ontime: 2, offtime: 2)
        #endif
        color = .red
        status = "Red Blink Fast"
    }
        
    func blinkGreenSlow() {
        #if !TESTING
        bl?.Blink(red: 0, green: 100, blue: 0, ontime: 10, offtime: 10)
        #endif
        color = .green
        status = "Green Blink Slow"
    }
        
    func blinkYellowFast() {
        #if !TESTING
        bl?.Blink(red: 100, green: 100, blue: 0, ontime: 3, offtime: 3)
        #endif
        color = .yellow
        status = "Yellow Blink Fast"
    }
        
    // ============================================
    // EFECTOS ESPECIALES
    // ============================================
    
    func alertLoud() {
        #if !TESTING
        bl?.Alert(red: 100, green: 0, blue: 0, andSound: 8, andVolume: 100)
        #endif
        color = .red
        status = "Alert Loud!"
    }
        
    func soundOnly(soundNumber: Int) {
        #if !TESTING
        bl?.Jingle(red: 0, green: 0, blue: 0, Sound: UInt8(soundNumber), andVolume: 50)
        #endif
        status = "Sound \(soundNumber)"
    }
    
    func jingle(soundNumber: Int, red: Int, green: Int, blue: Int, andVolume: Int) {
        #if !TESTING
        bl?.Alert(
            red: UInt8(red),
            green: UInt8(green),
            blue: UInt8(blue),
            andSound: UInt8(soundNumber),
            andVolume: UInt8(andVolume)
        )
        #endif
        color = Color(red: Double(red)/100.0, green: Double(green)/100.0, blue: Double(blue)/100.0)
        status = "Jingle \(soundNumber)"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            #if !TESTING
            self?.bl?.Off()
            #endif
            self?.color = .gray
            self?.status = "Listo"
        }
    }
    
    func off() {
        #if !TESTING
        bl?.Off()
        #endif
        color = .gray
        status = "Off"
    }
    
    func alert() {
        #if !TESTING
        bl?.Alert(red: 100, green: 0, blue: 0, andSound: 5, andVolume: 50)
        #endif
    }
}

#if !TESTING
extension BusylightManager: BusylightDelegate {
    func deviceConnected(devices: [String : String]) {
        isConnected = true
        status = "Connected"
        
        if let firstKey = devices.keys.first {
            deviceName = firstKey
            deviceModel = ""
        } else {
            deviceName = "Busylight"
            deviceModel = ""
        }
        
        print(">>> DISPOSITIVO CONECTADO <<<")
        print("Nombre: \(deviceName)")
        print("Datos completos: \(devices)")
    }
    
    func deviceDisconnected(devices: [String : String]) {
        print(">>> DISPOSITIVO DESCONECTADO <<<")
        print("Datos: \(devices)")
        
        isConnected = false
        status = "Disconnected"
        deviceName = "No Busylight connected"
        deviceModel = ""
    }
}
#else
// Mock extension para tests
extension BusylightManager {
    // Métodos mock para testing
}
#endif
