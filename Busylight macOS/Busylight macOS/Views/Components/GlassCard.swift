//
//  GlassCard.swift
//  Busylight
//
//  Reusable glassmorphism card component
//

import SwiftUI

struct GlassCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            content
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Material.thinMaterial)
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
    }
}

// Glass Status Card Component
struct GlassStatusCard: View {
    @ObservedObject var busylight: BusylightManager
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                // Connection indicator
                ZStack {
                    Circle()
                        .fill(busylight.isConnected ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                        .shadow(color: (busylight.isConnected ? Color.green : Color.red).opacity(0.6), radius: 4)
                    
                    if busylight.isConnected {
                        PulsingCircle()
                    }
                }
                
                Text(busylight.isConnected ? "Connected" : "Disconnected")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                
                Spacer()
            }
            
            if busylight.isConnected {
                Text(busylight.deviceName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack(spacing: 8) {
                Text("Active:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Circle()
                    .fill(busylight.color)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: busylight.color.opacity(0.5), radius: 4, x: 0, y: 2)
                
                Spacer()
            }
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.thinMaterial)
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
    }
}

struct PulsingCircle: View {
    var body: some View {
        Circle()
            .fill(Color.green.opacity(0.6))
            .frame(width: 10, height: 10)
    }
}

// MARK: - StatCard

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}
