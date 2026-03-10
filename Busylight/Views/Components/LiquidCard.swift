//
//  LiquidCard.swift
//  Busylight
//
//  NATIVE Apple Liquid Glass card components (macOS 15+/26+).
//
//  Uses:
//  - RoundedRectangle(cornerRadius: 20) for card shapes
//  - .ultraThinMaterial for native vibrancy
//  - Consistent 16-20pt corner radius across components
//
//  Relationships:
//  - Used by: ContentView.swift, SettingsView.swift, DashboardView.swift, etc.
//  - See: LiquidGlassStyles.swift for button and toggle components
//

import SwiftUI

// MARK: - Native Liquid Card
struct LiquidCard<Content: View>: View {
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Native Liquid Glass Status Card
struct LiquidGlassStatusCard: View {
    @ObservedObject var busylight: BusylightManager
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                // Connection indicator
                ZStack {
                    Circle()
                        .fill(busylight.isConnected ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    
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
                
                Spacer()
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct PulsingCircle: View {
    var body: some View {
        Circle()
            .fill(Color.green.opacity(0.6))
            .frame(width: 10, height: 10)
    }
}

// MARK: - StatCard (Native)
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - StatBox (Native)
struct StatBox: View {
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
