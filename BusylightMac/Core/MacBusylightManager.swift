//
//  MacBusylightManager.swift
//  macOS Hardware Manager with SDK Integration
//

import Foundation
import SwiftUI
import Combine
import BusylightSDK_Swift

// MARK: - Mac Busylight Manager
@MainActor
class MacBusylightManager: NSObject, ObservableObject {
    static let shared = MacBusylightManager()
    
    // MARK: - Published Properties
    @Published var currentColor: LightColor = .off
    @Published var status = "No device"
    @Published var isConnected = false
    @Published var deviceName = "No Busylight connected"
    
    // MARK: - Private Properties
    private var busylightSDK: Busylight?
    private var cancellables = Set<AnyCancellable>()
    
    // Sync with pomodoro
    @Published var syncWithPomodoro = true
    
    private override init() {
        super.init()
        setupBusylight()
        setupPomodoroSync()
    }
    
    // MARK: - Setup
    private func setupBusylight() {
        busylightSDK = Busylight()
        busylightSDK?.delegate = self
        busylightSDK?.start()
        
        checkDevices()
    }
    
    private func setupPomodoroSync() {
        // Listen to pomodoro phase changes
        UnifiedPomodoroManager.shared.$currentPhase
            .dropFirst()
            .sink { [weak self] phase in
                guard self?.syncWithPomodoro == true else { return }
                self?.updateColorForPhase(phase)
            }
            .store(in: &cancellables)
        
        UnifiedPomodoroManager.shared.$isRunning
            .dropFirst()
            .sink { [weak self] isRunning in
                guard self?.syncWithPomodoro == true else { return }
                if !isRunning {
                    self?.off()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateColorForPhase(_ phase: PomodoroPhase) {
        switch phase {
        case .work:
            green()
        case .shortBreak:
            blue()
        case .longBreak:
            orange()
        }
    }
    
    // MARK: - Device Detection
    func checkDevices() {
        let devices = busylightSDK?.getDevicesArray() ?? []
        print("📟 Dispositivos encontrados: \(devices.count)")
        
        if let firstDevice = devices.first as? [String: String],
           let deviceKey = firstDevice.keys.first {
            isConnected = true
            status = "Connected"
            deviceName = deviceKey
            print("✅ Busylight conectado: \(deviceKey)")
        } else {
            isConnected = false
            status = "Disconnected"
            deviceName = "No Busylight connected"
        }
    }
    
    // MARK: - Color Control
    func setColor(_ color: LightColor) {
        switch color {
        case .red: red()
        case .green: green()
        case .blue: blue()
        case .yellow: yellow()
        case .cyan: cyan()
        case .magenta: magenta()
        case .white: white()
        case .orange: orange()
        case .purple: purple()
        case .pink: pink()
        case .off: off()
        }
    }
    
    func red() {
        busylightSDK?.Light(red: 100, green: 0, blue: 0)
        currentColor = .red
        status = "Red"
    }
    
    func green() {
        busylightSDK?.Light(red: 0, green: 100, blue: 0)
        currentColor = .green
        status = "Green"
    }
    
    func yellow() {
        busylightSDK?.Pulse(red: 100, green: 100, blue: 0)
        currentColor = .yellow
        status = "Yellow Pulse"
    }
    
    func blue() {
        busylightSDK?.Light(red: 0, green: 0, blue: 100)
        currentColor = .blue
        status = "Blue"
    }
    
    func cyan() {
        busylightSDK?.Light(red: 0, green: 100, blue: 100)
        currentColor = .cyan
        status = "Cyan"
    }
    
    func magenta() {
        busylightSDK?.Light(red: 100, green: 0, blue: 100)
        currentColor = .magenta
        status = "Magenta"
    }
    
    func white() {
        busylightSDK?.Light(red: 100, green: 100, blue: 100)
        currentColor = .white
        status = "White"
    }
    
    func orange() {
        busylightSDK?.Light(red: 100, green: 65, blue: 0)
        currentColor = .orange
        status = "Orange"
    }
    
    func purple() {
        busylightSDK?.Light(red: 75, green: 0, blue: 100)
        currentColor = .purple
        status = "Purple"
    }
    
    func pink() {
        busylightSDK?.Light(red: 100, green: 75, blue: 80)
        currentColor = .pink
        status = "Pink"
    }
    
    // MARK: - Effects
    func pulseRed() {
        busylightSDK?.Pulse(red: 100, green: 0, blue: 0)
        currentColor = .red
        status = "Red Pulse"
    }
    
    func pulseGreen() {
        busylightSDK?.Pulse(red: 0, green: 100, blue: 0)
        currentColor = .green
        status = "Green Pulse"
    }
    
    func pulseBlue() {
        busylightSDK?.Pulse(red: 0, green: 0, blue: 100)
        currentColor = .blue
        status = "Blue Pulse"
    }
    
    func blinkRedFast() {
        busylightSDK?.Blink(red: 100, green: 0, blue: 0, ontime: 2, offtime: 2)
        currentColor = .red
        status = "Red Blink Fast"
    }
    
    // MARK: - Audio
    func jingle(soundNumber: Int, red: Int, green: Int, blue: Int, volume: Int) {
        busylightSDK?.Alert(
            red: UInt8(red),
            green: UInt8(green),
            blue: UInt8(blue),
            andSound: UInt8(soundNumber),
            andVolume: UInt8(volume)
        )
        
        // Auto-off after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.off()
        }
    }
    
    func alert() {
        busylightSDK?.Alert(red: 100, green: 0, blue: 0, andSound: 5, andVolume: 50)
    }
    
    func off() {
        busylightSDK?.Off()
        currentColor = .off
        status = "Off"
    }
}

// MARK: - Busylight Delegate
extension MacBusylightManager: BusylightDelegate {
    func deviceConnected(devices: [String: String]) {
        isConnected = true
        status = "Connected"
        
        if let firstKey = devices.keys.first {
            deviceName = firstKey
        } else {
            deviceName = "Busylight"
        }
        
        print(">>> BUSYLIGHT CONECTADO: \(deviceName) <<<")
        
        // Sync state to other devices
        Task {
            await SyncManager.shared.syncToCloud()
        }
    }
    
    func deviceDisconnected(devices: [String: String]) {
        print(">>> BUSYLIGHT DESCONECTADO <<<")
        isConnected = false
        status = "Disconnected"
        deviceName = "No Busylight connected"
        currentColor = .off
    }
}
