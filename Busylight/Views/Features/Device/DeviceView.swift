//
//  DeviceView.swift
//  Busylight
//

import SwiftUI

struct DeviceView: View {
    @EnvironmentObject var busylight: BusylightManager  // ← Cambiado: @ObservedObject → @EnvironmentObject

    private var colors: [(name: String, color: Color, action: () -> Void)] {
        [
            ("Red", .red, { busylight.red() }),
            ("Green", .green, { busylight.green() }),
            ("Blue", .blue, { busylight.blue() }),
            ("Yellow", .yellow, { busylight.yellow() }),
            ("Cyan", .cyan, { busylight.cyan() }),
            ("Magenta", .pink, { busylight.magenta() }),
            ("White", .white, { busylight.white() }),
            ("Orange", .orange, { busylight.orange() }),
            ("Purple", .purple, { busylight.purple() }),
            ("Pink", .pink, { busylight.pink() })
        ]
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 4) {
                Text("Light Control")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))

                Text("Test your Busylight device")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Colors Section
            LiquidCard(title: "Solid Colors", icon: "paintpalette.fill") {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 75, maximum: 85), spacing: 10)
                ], spacing: 10) {
                    ForEach(colors, id: \.name) { item in
                        LiquidGlassColorButton(
                            name: item.name,
                            color: item.color,
                            action: {
                                BusylightLogger.shared.info("DeviceView: \(item.name) pressed")
                                UserInteractionLogger.shared.deviceColorChanged(color: item.name)
                                item.action()
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)

            // Jingles Section
            LiquidCard(title: "Audio Jingles", icon: "speaker.wave.2.fill") {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 8)
                ], spacing: 8) {
                    ForEach(1...16, id: \.self) { number in
                        LiquidGlassJingleButton(number: number) {
                            BusylightLogger.shared.info("DeviceView: Jingle \(number) pressed")
                            UserInteractionLogger.shared.deviceJinglePlayed(number: number)
                            busylight.jingle(
                                soundNumber: number,
                                red: Int.random(in: 0...100),
                                green: Int.random(in: 0...100),
                                blue: Int.random(in: 0...100),
                                andVolume: Int.random(in: 30...100)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            // Quick Actions
            LiquidCard(title: "Quick Actions", icon: "bolt.fill") {
                HStack(spacing: 12) {
                    LiquidGlassActionButton(
                        title: "Off",
                        icon: "power",
                        color: .gray,
                        action: {
                            UserInteractionLogger.shared.deviceAction(action: "Off")
                            busylight.off()
                        }
                    )

                    LiquidGlassActionButton(
                        title: "Pulse",
                        icon: "waveform",
                        color: .blue,
                        action: {
                            UserInteractionLogger.shared.deviceAction(action: "Pulse Blue")
                            busylight.pulseBlue()
                        }
                    )

                    LiquidGlassActionButton(
                        title: "Blink",
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        action: {
                            UserInteractionLogger.shared.deviceAction(action: "Blink Red Fast")
                            busylight.blinkRedFast()
                        }
                    )
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 20)
        }
    }
}

// MARK: - Supporting Views (sin cambios)
struct LiquidGlassColorButton: View {
    @State private var isHovered = false
    let name: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)

                Text(name)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(height: 60)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct LiquidGlassJingleButton: View {
    let number: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(.primary)
                .frame(height: 44)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.liquidGlass)
        .focusable(false)
    }
}
