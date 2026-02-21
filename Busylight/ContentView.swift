//
//  ContentView.swift
//  Busylight
//
//  Created by Jose Araujo on 20/02/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var busylight = BusylightManager()
    @State private var showingTimer = false
    
    var body: some View {
        NavigationSplitView {
            List {
                // SECCIÓN: Estado del dispositivo
                Section {
                    HStack {
                        Circle()
                            .fill(busylight.isConnected ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading) {
                            Text("Options")
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        Text(busylight.isConnected ? "Connected" : "Disconnected")
                            .font(.caption)
                            .foregroundColor(busylight.isConnected ? .green : .red)
                    }
                }
                
                // SECCIÓN: BOTONES DE CONTROL
                Section("Colors") {
                    Button("🔴 Red") { busylight.red() }
                    Button("🟢 Green") { busylight.green() }
                    Button("🔵 Blue") { busylight.blue() }
                    Button("🟡 Yellow") { busylight.yellow() }
                    Button("🩵 Cyan") { busylight.cyan() }
                    Button("🩷 Magenta") { busylight.magenta() }
                    Button("⚪ White") { busylight.white() }
                    Button("🟠 Orange") { busylight.orange() }
                    Button("🟣 Purple") { busylight.purple() }
                    Button("🩷 Pink") { busylight.pink() }
                }
                
                // Jingles
                Section("Jingles") {
                    Button("🔔 Jingle 1") { busylight.jingle(soundNumber: 1, red: 20, green: 20, blue: 20, andVolume: 0) }
                    Button("🔔 Jingle 2") { busylight.jingle(soundNumber: 2, red: 20, green: 20, blue: 20, andVolume: 50) }
                    Button("🔔 Jingle 3") { busylight.jingle(soundNumber: 3, red: 20, green: 20, blue: 20, andVolume: 50) }
                    Button("🔔 Jingle 4") { busylight.jingle(soundNumber: 4, red: 20, green: 20, blue: 20, andVolume: 50) }
                    Button("🔔 Jingle 5") { busylight.jingle(soundNumber: 5, red: 20, green: 20, blue: 20, andVolume: 50) }
                    Button("🔔 Jingle 6") { busylight.jingle(soundNumber: 6, red: 20, green: 20, blue: 20, andVolume: 10) }
                    Button("🔔 Jingle 7") { busylight.jingle(soundNumber: 7, red: 20, green: 20, blue: 20, andVolume: 20) }
                    Button("🔔 Jingle 8") { busylight.jingle(soundNumber: 8, red: 20, green: 20, blue: 20, andVolume: 30) }
                    Button("🔔 Jingle 9") { busylight.jingle(soundNumber: 9, red: 20, green: 20, blue: 20, andVolume: 40) }
                    Button("🔔 Jingle 10") { busylight.jingle(soundNumber: 10, red: 20, green: 20, blue: 20, andVolume: 50) }
                    Button("🔔 Jingle 11") { busylight.jingle(soundNumber: 11, red: 20, green: 20, blue: 20, andVolume: 60) }
                    Button("🔔 Jingle 12") { busylight.jingle(soundNumber: 12, red: 20, green: 20, blue: 20, andVolume: 60) }
                    Button("🔔 Jingle 13") { busylight.jingle(soundNumber: 13, red: 20, green: 20, blue: 20, andVolume: 60) }
                    Button("🔔 Jingle 14") { busylight.jingle(soundNumber: 14, red: 20, green: 20, blue: 20, andVolume: 60) }
                    Button("🔔 Jingle 15") { busylight.jingle(soundNumber: 15, red: 20, green: 20, blue: 20, andVolume: 60) }
                    Button("🔔 Jingle 16") { busylight.jingle(soundNumber: 16, red: 20, green: 20, blue: 20, andVolume: 60) }
                }
                
                // SECCIÓN: Timer
                Section("Timer") {
                    Button("⏱️ Start Pomodoro") {
                        showingTimer = true
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Busylight")
        } detail: {
            ZStack {
                // Contenido principal centrado
                VStack(spacing: 20) {
                    Text("Busylight Control")
                        .font(.largeTitle)
                    
                    Circle()
                        .fill(busylight.color)
                        .frame(width: 150, height: 150)
                    
                    Text(busylight.status)
                        .font(.headline)
                }
                
                // Label del modelo en esquina superior derecha
                VStack {
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(busylight.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(busylight.deviceName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .padding()
                    
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showingTimer) {
            TimerView(busylight: busylight)
        }
        .frame(minWidth: 600, minHeight: 400)
        .onReceive(NotificationCenter.default.publisher(for: .openMainWindow)) { _ in
            bringWindowToFront()
        }
    }
    
    // FUNCIÓN PARA TRAER VENTANA AL FRENTE
    private func bringWindowToFront() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.unhide(nil)  // ← Esto muestra la app si estaba oculta
        
        // Dar tiempo a que la ventana aparezca
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for window in NSApp.windows {
                // Incluir ventanas minimizadas u ocultas
                if window.isVisible || !window.isMiniaturized {
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                    return
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



