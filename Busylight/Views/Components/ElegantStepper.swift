//
//  ElegantStepper.swift
//  Busylight
//
//  Reusable stepper component with liquid glass style
//

import SwiftUI

struct ElegantStepper: View {
    let icon: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        HStack(spacing: 11) {
            Button {
                if value > range.lowerBound {
                    value -= 1
                    HapticFeedback.light()
                }
            } label: {
                Image(systemName: "minus")
                    .font(.callout.weight(.bold))
                    .frame(width: 33, height: 33)
            }
            .buttonStyle(ElegantStepperButtonStyle())
            
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(value)")
                    .font(.system(.body, design: .rounded).weight(.semibold))
            }
            .frame(minWidth: 41)
            
            Button {
                if value < range.upperBound {
                    value += 1
                    HapticFeedback.light()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.callout.weight(.bold))
                    .frame(width: 33, height: 33)
            }
            .buttonStyle(ElegantStepperButtonStyle())
        }
        .padding(9)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ElegantStepperButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? .white : .secondary)
            .background(
                Circle()
                    .fill(configuration.isPressed ? Color.accentColor : Color.gray.opacity(0.2))
            )
            .focusable(false)
    }
}
