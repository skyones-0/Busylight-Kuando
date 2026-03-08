//
//  SharedStyles.swift
//  Modern Glassmorphism styles for all platforms
//

import SwiftUI

// MARK: - Glass Background
struct GlassBackground: ViewModifier {
    var material: Material = .ultraThinMaterial
    var cornerRadius: CGFloat = 20
    var strokeColor: Color = .white
    var strokeOpacity: Double = 0.2
    var strokeWidth: CGFloat = 1
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(material)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(strokeColor.opacity(strokeOpacity), lineWidth: strokeWidth)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
    }
}

extension View {
    func glass(
        material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = 20,
        strokeOpacity: Double = 0.2
    ) -> some View {
        modifier(GlassBackground(
            material: material,
            cornerRadius: cornerRadius,
            strokeOpacity: strokeOpacity
        ))
    }
}

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    var title: String?
    var icon: String?
    var material: Material = .thinMaterial
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = title {
                HStack(spacing: 8) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text(title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
            }
            
            content
        }
        .padding(20)
        .glass(material: material, cornerRadius: cornerRadius)
    }
}

// MARK: - Glass Button
struct GlassButton: View {
    let title: String
    let icon: String?
    let color: Color
    let isProminent: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(isProminent ? .semibold : .medium))
            }
            .foregroundStyle(isProminent ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            isProminent
                                ? color.opacity(isPressed ? 0.9 : 0.8)
                                : color.opacity(isPressed ? 0.25 : 0.15)
                        )
                    
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isProminent
                                ? color.opacity(0.5)
                                : color.opacity(0.3),
                            lineWidth: 1.5
                        )
                }
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Circle Button
struct GlassCircleButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(color)
                    .blur(radius: isHovered ? 15 : 0)
                    .opacity(isHovered ? 0.4 : 0)
                    .frame(width: size + 10, height: size + 10)
                
                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(isPressed ? 0.6 : 0.3),
                                color.opacity(isPressed ? 0.4 : 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.4), lineWidth: 1)
                    )
                    .frame(width: size, height: size)
                
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(color)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
    }
}

// MARK: - Press Events Modifier
struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Animated Mesh Gradient Background
struct MeshGradientBackground: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base color
                Color(.systemBackground)
                
                // Animated blobs
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 80)
                    .frame(width: 300, height: 300)
                    .offset(
                        x: animate ? 50 : -50,
                        y: animate ? -30 : 30
                    )
                    .opacity(0.4)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 90)
                    .frame(width: 350, height: 350)
                    .offset(
                        x: animate ? -40 : 40,
                        y: animate ? 50 : -50
                    )
                    .opacity(0.3)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 70)
                    .frame(width: 280, height: 280)
                    .offset(
                        x: animate ? 30 : -30,
                        y: animate ? 60 : -40
                    )
                    .opacity(0.25)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

// MARK: - Glass Progress Bar
struct GlassProgressBar: View {
    let progress: Double
    let color: Color
    var height: CGFloat = 8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: height / 2)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
                
                // Progress
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, min(geometry.size.width, geometry.size.width * CGFloat(progress))))
                    .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 0)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Phase Badge
struct PhaseBadge: View {
    let phase: PomodoroPhase
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: phase.icon)
                .font(.caption)
            Text(phase.displayName)
                .font(.system(.caption, design: .rounded).weight(.semibold))
        }
        .foregroundStyle(isActive ? .white : phase.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isActive ? phase.color : phase.color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(phase.color.opacity(0.3), lineWidth: 1)
                )
        )
        .overlay(
            isActive ?
            Capsule()
                .stroke(phase.color.opacity(0.5), lineWidth: 2)
                .blur(radius: 4)
            : nil
        )
    }
}

// MARK: - Timer Display
struct TimerDisplay: View {
    let timeString: String
    let phase: PomodoroPhase
    let isRunning: Bool
    let size: TimerDisplaySize
    
    enum TimerDisplaySize {
        case small
        case medium
        case large
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 48
            case .medium: return 72
            case .large: return 96
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Glow effect when running
            if isRunning {
                Text(timeString)
                    .font(.system(size: size.fontSize, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(phase.color)
                    .blur(radius: 20)
                    .opacity(0.5)
            }
            
            Text(timeString)
                .font(.system(size: size.fontSize, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Glass Toggle
struct GlassToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                )
            
            Text(title)
                .font(.system(.body, design: .rounded))
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .labelsHidden()
        }
        .padding(16)
        .glass(material: .thinMaterial, cornerRadius: 14)
    }
}

// MARK: - Glass Stepper
struct GlassStepper: View {
    let icon: String
    let title: String?
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
            
            if let title = title {
                Text(title)
                    .font(.system(.body, design: .rounded))
                Spacer()
            }
            
            HStack(spacing: 0) {
                Button {
                    if value > range.lowerBound {
                        value -= 1
                        Haptics.shared.perform(.button)
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.caption.weight(.bold))
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Text("\(value)")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .monospacedDigit()
                    .frame(minWidth: 44)
                
                Button {
                    if value < range.upperBound {
                        value += 1
                        Haptics.shared.perform(.button)
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .glass(material: .thinMaterial, cornerRadius: 14)
    }
}

// MARK: - Color Picker Grid
struct ColorPickerGrid: View {
    @Binding var selectedColor: LightColor
    let columns: Int
    let size: CGFloat
    
    var body: some View {
        let gridItems = Array(repeating: GridItem(.flexible()), count: columns)
        
        LazyVGrid(columns: gridItems, spacing: 12) {
            ForEach(LightColor.allCases.filter { $0 != .off }, id: \.self) { color in
                ColorButton(
                    color: color,
                    isSelected: selectedColor == color,
                    size: size
                ) {
                    selectedColor = color
                }
            }
        }
    }
}

// MARK: - Color Button
struct ColorButton: View {
    let color: LightColor
    let isSelected: Bool
    let size: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Glow when selected
                Circle()
                    .fill(color.swiftUIColor)
                    .blur(radius: isSelected ? 15 : 0)
                    .opacity(isSelected ? 0.5 : 0)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.swiftUIColor.opacity(0.9),
                                color.swiftUIColor
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: size
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                    )
                    .shadow(
                        color: color.swiftUIColor.opacity(isSelected ? 0.6 : 0.3),
                        radius: isSelected ? 12 : 6,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.35, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                }
            }
            .frame(width: size, height: size)
            .scaleEffect(isSelected ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
