//
//  DeviceView.swift
//  Busylight
//
//  Device control interface for Busylight hardware
//

import SwiftUI

struct DeviceView: View {
    @ObservedObject var busylight: BusylightManager
    
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
            GlassCard(title: "Solid Colors", icon: "paintpalette.fill") {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 75, maximum: 85), spacing: 10)
                ], spacing: 10) {
                    ForEach(colors, id: \.name) { item in
                        GlassColorButton(
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
            GlassCard(title: "Audio Jingles", icon: "speaker.wave.2.fill") {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 8)
                ], spacing: 8) {
                    ForEach(1...16, id: \.self) { number in
                        GlassJingleButton(number: number) {
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
            GlassCard(title: "Quick Actions", icon: "bolt.fill") {
                HStack(spacing: 12) {
                    GlassActionButton(
                        title: "Off",
                        icon: "power",
                        color: .gray,
                        action: {
                            UserInteractionLogger.shared.deviceAction(action: "Off")
                            busylight.off()
                        }
                    )
                    
                    GlassActionButton(
                        title: "Pulse",
                        icon: "waveform",
                        color: .blue,
                        action: {
                            UserInteractionLogger.shared.deviceAction(action: "Pulse Blue")
                            busylight.pulseBlue()
                        }
                    )
                    
                    GlassActionButton(
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

// MARK: - Supporting Views for Device

struct GlassColorButton: View {
    let name: String
    let color: Color
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: color.opacity(0.5), radius: 4)
                
                Text(name)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(height: 60)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .scaleEffect(isHovered ? 1.05 : 1)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.2), value: isHovered)
    }
}

struct GlassJingleButton: View {
    let number: Int
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Material.thinMaterial)
                
                Text("\(number)")
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .scaleEffect(isHovered ? 1.05 : 1)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.2), value: isHovered)
    }
}

struct GlassActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.thinMaterial)
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(isHovered ? 0.4 : 0.2),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: color.opacity(isHovered ? 0.3 : 0.1), radius: isHovered ? 12 : 4, x: 0, y: isHovered ? 6 : 2)
        .scaleEffect(isHovered ? 1.02 : 1)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
    }
}
