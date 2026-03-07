import Foundation
import SwiftUI
import Combine
import BusylightSDK_Swift

class BusylightManager: ObservableObject {
    private var bl: Busylight?
    @Published var color: Color = .gray
    @Published var status = "No device"
    @Published var isConnected = false
    @Published var deviceName = "No Busylight connected"
    @Published var deviceModel = ""
    
    init() {
        setupBusylight()
    }
    
    func setupBusylight() {
        bl = Busylight()
        bl?.delegate = self
        bl?.start()
        
        checkDevices()
    }
    
    func checkDevices() {
        let devices = bl?.getDevicesArray() ?? []
        print("Dispositivos encontrados: \(devices.count)")
        
        if let firstDevice = devices.first as? [String: String],
           let deviceKey = firstDevice.keys.first {
            
            isConnected = true
            status = "Connected"
            deviceName = deviceKey  // "Busylight Omega model 2"
            deviceModel = ""
            
            print("Primer dispositivo: \(deviceKey)")
        } else {
            isConnected = false
            status = "Disconnected"
            deviceName = "No Busylight connected"
            deviceModel = ""
        }
    }
    
    func red() {
        bl?.Light(red: 100, green: 0, blue: 0)
        color = .red
        status = "Red"
    }
    
    func green() {
        bl?.Light(red: 0, green: 100, blue: 0)
        color = .green
        status = "Green"
    }
    
    func yellow() {
        bl?.Pulse(red: 100, green: 100, blue: 0)
        color = .yellow
        status = "Yellow Pulse"
    }
    func blue() {
        bl?.Light(red: 0, green: 0, blue: 100)
        color = Color(red: 0, green: 0, blue: 1)  // Azul puro en SwiftUI
        status = "Blue"
    }
    func cyan() {
        bl?.Light(red: 0, green: 100, blue: 100)
        color = Color(red: 0, green: 1, blue: 1)  // Cyan = verde + azul
        status = "Cyan"
    }

    func magenta() {
        bl?.Light(red: 100, green: 0, blue: 100)
        color = Color(red: 1, green: 0, blue: 1)  // Magenta = rojo + azul
        status = "Magenta"
    }

    func white() {
        bl?.Light(red: 100, green: 100, blue: 100)
        color = .white
        status = "White"
    }

    func orange() {
        bl?.Light(red: 100, green: 65, blue: 0)
        color = .orange
        status = "Orange"
    }

    func purple() {
        bl?.Light(red: 75, green: 0, blue: 100)
        color = .purple
        status = "Purple"
    }

    func pink() {
        bl?.Light(red: 100, green: 75, blue: 80)
        color = .pink
        status = "Pink"
    }
    // ============================================
        // EFECTOS PULSE (Se enciende y apaga suavemente)
        // ============================================
        
    func pulseRed() {
        bl?.Pulse(red: 100, green: 0, blue: 0)
        color = .red
        status = "Red Pulse"
    }
        
    func pulseGreen() {
        bl?.Pulse(red: 0, green: 100, blue: 0)
        color = .green
        status = "Green Pulse"
    }
        
    func pulseBlue() {
        bl?.Pulse(red: 0, green: 0, blue: 100)
        color = .blue
        status = "Blue Pulse"
    }
        
    func pulseYellow() {
        bl?.Pulse(red: 100, green: 100, blue: 0)
        color = .yellow
        status = "Yellow Pulse"
    }
        
    func pulseCyan() {
        bl?.Pulse(red: 0, green: 100, blue: 100)
        color = Color(red: 0, green: 1, blue: 1)
        status = "Cyan Pulse"
    }
        
    func pulseMagenta() {
        bl?.Pulse(red: 100, green: 0, blue: 100)
        color = Color(red: 1, green: 0, blue: 1)
        status = "Magenta Pulse"
    }
        
    func pulseWhite() {
        bl?.Pulse(red: 100, green: 100, blue: 100)
        color = .white
        status = "White Pulse"
    }
        
        // ============================================
        // EFECTOS BLINK (Parpadeo controlado)
        // ============================================
        
        // Parpadeo LENTO (1s on, 1s off)
    func blinkRedSlow() {
        bl?.Blink(red: 100, green: 0, blue: 0, ontime: 10, offtime: 10)
        color = .red
        status = "Red Blink Slow"
    }
        
        // Parpadeo MEDIO (0.5s on, 0.5s off)
    func blinkRedMedium() {
        bl?.Blink(red: 100, green: 0, blue: 0, ontime: 5, offtime: 5)
        color = .red
        status = "Red Blink Medium"
    }
        
        // Parpadeo RÁPIDO (0.2s on, 0.2s off)
    func blinkRedFast() {
        bl?.Blink(red: 100, green: 0, blue: 0, ontime: 2, offtime: 2)
        color = .red
        status = "Red Blink Fast"
    }
        
        // Parpadeo verde lento
    func blinkGreenSlow() {
        bl?.Blink(red: 0, green: 100, blue: 0, ontime: 10, offtime: 10)
        color = .green
        status = "Green Blink Slow"
    }
        
        // Parpadeo amarillo rápido
    func blinkYellowFast() {
        bl?.Blink(red: 100, green: 100, blue: 0, ontime: 3, offtime: 3)
        color = .yellow
        status = "Yellow Blink Fast"
    }
        
        // ============================================
        // EFECTOS ESPECIALES
        // ============================================
    
        
        // Alerta con sonido fuerte
    func alertLoud() {
        bl?.Alert(red: 100, green: 0, blue: 0, andSound: 8, andVolume: 100)
        color = .red
        status = "Alert Loud!"
    }
        
        // Solo sonido, sin luz
    func soundOnly(soundNumber: Int) {
        // Jingle con luz negra (apagada) + sonido
        // Nota: "Sound" con S mayúscula, no "andSound"
        bl?.Jingle(red: 0, green: 0, blue: 0, Sound: UInt8(soundNumber), andVolume: 50)
        status = "Sound \(soundNumber)"
    }
    
    func jingle(soundNumber: Int, red: Int, green: Int, blue: Int, andVolume: Int) {
        bl?.Alert(
            red: UInt8(red),
            green: UInt8(green),
            blue: UInt8(blue),
            andSound: UInt8(soundNumber),
            andVolume: UInt8(andVolume)
        )
        
        color = Color(red: Double(red)/100.0, green: Double(green)/100.0, blue: Double(blue)/100.0)
        status = "Jingle \(soundNumber)"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            self?.bl?.Off()
            self?.color = .gray
            self?.status = "Listo"
        }
    }
    
    func off() {
        bl?.Off()
        color = .gray
        status = "Off"
    }
    
    func alert() {
        bl?.Alert(red: 100, green: 0, blue: 0, andSound: 5, andVolume: 50)
    }

}

extension BusylightManager: BusylightDelegate {
    func deviceConnected(devices: [String : String]) {
        isConnected = true
        status = "Connected"
        
        // La clave es el nombre del dispositivo, el valor es "Unknown"
        if let firstKey = devices.keys.first {
            deviceName = firstKey  // "Busylight Omega model 2"
            //deviceModel = ""       // No hay modelo separado
        } else {
            deviceName = "Busylight"
            deviceModel = ""
        }
        
        print(">>> DISPOSITIVO CONECTADO <<<")
        print("Nombre: \(deviceName)")
        print("Datos completos: \(devices)")
        
        //windowTitle = "Busylight - \(deviceName)"
    }
    
    func deviceDisconnected(devices: [String : String]) {
        print(">>> DISPOSITIVO DESCONECTADO <<<")
        print("Datos: \(devices)")
        
        isConnected = false
        status = "Disconnected"
        deviceName = "No Busylight connected"  // ← Cambiar esto
        deviceModel = ""
    }
    

}
   
