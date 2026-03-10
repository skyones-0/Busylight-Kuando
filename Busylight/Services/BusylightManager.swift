//
//  BusylightManager.swift
//  Busylight
//

import Foundation
import SwiftUI
import Combine

// MARK: - Device Model
struct BusylightDevice: Identifiable {
    let id: String
    let name: String
}

@MainActor
final class BusylightManager: NSObject, ObservableObject {
    static let shared = BusylightManager()

    @Published var isConnected = false
    @Published var currentDevice: BusylightDevice?
    @Published var currentColor: Color = .gray

    private var bl: BusylightWrapper?

    override init() {
        super.init()
        print("[BusylightManager] Inicializando...")
        bl = BusylightWrapper()
        print("[BusylightManager] Wrapper creado: \(bl != nil)")
        bl?.delegate = self
        bl?.start()
        print("[BusylightManager] start() llamado")
        scanDevices()
    }

    // MARK: - Computed Properties for UI
    var deviceName: String {
        currentDevice?.name ?? "Unknown Device"
    }

    var color: Color {
        isConnected ? currentColor : .gray
    }

    func scanDevices() {
        let devices = bl?.getDevicesArray() ?? []
        print("[BusylightManager] Dispositivos encontrados: \(devices.count)")

        if let firstDevice = devices.first as? String {
            isConnected = true
            currentDevice = BusylightDevice(id: firstDevice, name: firstDevice)
            print("[BusylightManager] Device CONNECTED: \(firstDevice)")
        } else {
            isConnected = false
            currentDevice = nil
        }
    }

    // MARK: - Colors
    func red() {
        print("[BusylightManager] red() llamado")
        setColor(.red)
        bl?.light(withRed: 100, green: 0, blue: 0)
        print("[BusylightManager] light() ejecutado")
    }
    func green() {
        print("[BusylightManager] green() llamado")
        setColor(.green)
        bl?.light(withRed: 0, green: 100, blue: 0)
    }
    func blue() {
        print("[BusylightManager] blue() llamado")
        setColor(.blue)
        bl?.light(withRed: 0, green: 0, blue: 100)
    }
    func yellow() {
        setColor(.yellow)
        bl?.light(withRed: 100, green: 100, blue: 0)
    }
    func cyan() {
        setColor(.cyan)
        bl?.light(withRed: 0, green: 100, blue: 100)
    }
    func magenta() {
        setColor(Color(red: 1, green: 0, blue: 1))
        bl?.light(withRed: 100, green: 0, blue: 100)
    }
    func white() {
        setColor(.white)
        bl?.light(withRed: 100, green: 100, blue: 100)
    }
    func orange() {
        setColor(.orange)
        bl?.light(withRed: 100, green: 65, blue: 0)
    }
    func purple() {
        setColor(.purple)
        bl?.light(withRed: 75, green: 0, blue: 100)
    }
    func pink() {
        setColor(.pink)
        bl?.light(withRed: 100, green: 75, blue: 80)
    }

    private func setColor(_ color: Color) {
        currentColor = color
    }

    // MARK: - Pulse
    func pulseRed() { bl?.pulse(withRed: 100, green: 0, blue: 0) }
    func pulseGreen() { bl?.pulse(withRed: 0, green: 100, blue: 0) }
    func pulseBlue() { bl?.pulse(withRed: 0, green: 0, blue: 100) }
    func pulseYellow() { bl?.pulse(withRed: 100, green: 100, blue: 0) }
    func pulseCyan() { bl?.pulse(withRed: 0, green: 100, blue: 100) }
    func pulseMagenta() { bl?.pulse(withRed: 100, green: 0, blue: 100) }
    func pulseWhite() { bl?.pulse(withRed: 100, green: 100, blue: 100) }

    // MARK: - Blink
    func blinkRedSlow() { bl?.blink(withRed: 100, green: 0, blue: 0, ontime: 10, offtime: 10) }
    func blinkRedMedium() { bl?.blink(withRed: 100, green: 0, blue: 0, ontime: 5, offtime: 5) }
    func blinkRedFast() { bl?.blink(withRed: 100, green: 0, blue: 0, ontime: 2, offtime: 2) }
    func blinkGreenSlow() { bl?.blink(withRed: 0, green: 100, blue: 0, ontime: 10, offtime: 10) }
    func blinkYellow() { bl?.blink(withRed: 100, green: 100, blue: 0, ontime: 3, offtime: 3) }

    // MARK: - Alert
    func alertRed() {
        print("[BusylightManager] alertRed() llamado")
        bl?.alert(withRed: 100, green: 0, blue: 0, andSound: 8, andVolume: 100)
    }

    // Alias para PomodoroManager
    func alert() { alertRed() }

    // MARK: - Jingle
    func jingle(soundNumber: Int, red: Int, green: Int, blue: Int, andVolume: Int) {
        print("[BusylightManager] jingle(sound:\(soundNumber))")
        bl?.jingle(withRed: UInt8(red), green: UInt8(green), blue: UInt8(blue), sound: UInt8(soundNumber), andVolume: UInt8(andVolume))
    }

    // MARK: - Off
    func off() {
        print("[BusylightManager] off() llamado")
        bl?.off()
        currentColor = .gray
    }

    // MARK: - Timer
    func scheduleOff(after seconds: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            self?.off()
        }
    }
}

// MARK: - BusylightWrapperDelegate
extension BusylightManager: BusylightWrapperDelegate {
    func deviceConnected(_ devices: [String: String]) {
        isConnected = true
        if let (id, name) = devices.first {
            currentDevice = BusylightDevice(id: id, name: name)
        }
        print("[BusylightManager] >>> DISPOSITIVO CONECTADO <<<")
        print("[BusylightManager] Nombre: \(currentDevice?.name ?? "Unknown")")
        print("[BusylightManager] Datos completos: \(devices)")
    }

    func deviceDisconnected(_ devices: [String: String]) {
        isConnected = false
        currentDevice = nil
        currentColor = .gray
        print("[BusylightManager] >>> DISPOSITIVO DESCONECTADO <<<")
    }
}
