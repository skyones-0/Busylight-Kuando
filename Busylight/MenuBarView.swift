import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @StateObject private var busylight = BusylightManager()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Circle()
                        .fill(busylight.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(busylight.isConnected ? "Connected" : "Disconnected")
                    Text(busylight.deviceName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                Divider()
                
                // VISIBILIDAD - Checkboxes nativos de macOS
                VStack(alignment: .leading, spacing: 10) {
                    Text("Visibilidad")
                        .font(.headline)
                    
                    Toggle("Mostrar en Dock", isOn: $appDelegate.showInDock)
                        .toggleStyle(.checkbox)
                    
                    Toggle("Mostrar en Menu Bar", isOn: $appDelegate.showInMenuBar)
                        .toggleStyle(.checkbox)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                

                
                Divider()
                
                // Colores rápidos
                VStack(alignment: .leading, spacing: 8) {
                    Text("Colores")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 35))], spacing: 5) {
                        ColorButton(color: .red, action: { busylight.red() })
                        ColorButton(color: .green, action: { busylight.green() })
                        ColorButton(color: .blue, action: { busylight.blue() })
                        ColorButton(color: .yellow, action: { busylight.yellow() })
                        ColorButton(color: .cyan, action: { busylight.cyan() })
                        ColorButton(color: .purple, action: { busylight.purple() })
                        ColorButton(color: .white, action: { busylight.white() })
                        ColorButton(color: .orange, action: { busylight.orange() })
                    }
                }
                
                // Jingles
                VStack(alignment: .leading, spacing: 8) {
                    Text("Jingles")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 35))], spacing: 5) {
                        ForEach(1...16, id: \.self) { number in
                            Button("\(number)") {
                                busylight.jingle(
                                    soundNumber: number,
                                    red: Int.random(in: 0...100),
                                    green: Int.random(in: 0...100),
                                    blue: Int.random(in: 0...100),
                                    andVolume: Int.random(in: 30...100)
                                )
                            }
                            .frame(width: 35, height: 35)
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                Spacer(minLength: 20)
                
                // BOTÓN NOTIFICATIONCENTER
                Button("Abrir Ventana Principal") {
                    NotificationCenter.default.post(name: .openMainWindow, object: nil)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                
                Button("Salir") {
                    NSApp.terminate(nil)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .frame(width: 300, height: 500)
    }
}

struct ColorButton: View {
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.borderless)
    }
}
