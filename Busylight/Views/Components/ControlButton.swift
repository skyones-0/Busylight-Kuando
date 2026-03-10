//
//  ControlButton.swift
//  Busylight
//
//  Reusable control button with haptic feedback
//

import SwiftUI

struct ControlButton: View {
    let title: String
    let icon: String
    let color: Color
    let isProminent: Bool
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        Button(action: {
            HapticFeedback.prolonged()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.callout)
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(isProminent ? .semibold : .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(ControlButtonStyle(color: isEnabled ? color : .gray, isProminent: isEnabled && isProminent))
        .focusable(false)
    }
}

struct ControlButtonStyle: ButtonStyle {
    let color: Color
    let isProminent: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isProminent ? .white : color)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            configuration.isPressed
                                ? color.opacity(isProminent ? 1 : 0.3)
                                : color.opacity(isProminent ? 0.8 : 0.15)
                        )
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(configuration.isPressed ? 0.8 : 0.4), lineWidth: 1)
                }
            )
            .shadow(
                color: color.opacity(configuration.isPressed ? 0.4 : 0.2),
                radius: configuration.isPressed ? 8 : 4,
                x: 0,
                y: configuration.isPressed ? 4 : 2
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .focusable(false)
    }
}
