//
//  GlassmorphismStyles.swift
//  Busylight
//
//  Modern Glassmorphism UI Components
//

import SwiftUI

// MARK: - Haptic Feedback Helper
struct HapticFeedback {
    static func light() {
        let performer = NSHapticFeedbackManager.defaultPerformer
        performer.perform(.generic, performanceTime: .now)
    }
    
    static func medium() {
        let performer = NSHapticFeedbackManager.defaultPerformer
        performer.perform(.generic, performanceTime: .now)
    }
    
    static func strong() {
        let performer = NSHapticFeedbackManager.defaultPerformer
        performer.perform(.generic, performanceTime: .now)
    }
    
    // Prolonged haptic for main actions (Play/Pause/Stop)
    static func prolonged() {
        let performer = NSHapticFeedbackManager.defaultPerformer
        // Perform multiple haptics in sequence for prolonged effect
        performer.perform(.generic, performanceTime: .now)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            performer.perform(.generic, performanceTime: .now)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            performer.perform(.generic, performanceTime: .now)
        }
    }
}

// MARK: - Glassmorphism Background
struct GlassBackground: ViewModifier {
    var material: Material = .ultraThinMaterial
    var cornerRadius: CGFloat = 16
    var strokeColor: Color = .white.opacity(0.2)
    var strokeWidth: CGFloat = 1
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(material)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(strokeColor, lineWidth: strokeWidth)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            )
    }
}

extension View {
    func glassBackground(material: Material = .ultraThinMaterial, cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassBackground(material: material, cornerRadius: cornerRadius))
    }
}

// MARK: - Animated Gradient Button Style
struct GradientWaveButtonStyle: ButtonStyle {
    var color: Color = .accentColor
    var isProminent: Bool = false
    var cornerRadius: CGFloat = 12
    
    @State private var shimmerOffset: CGFloat = -1
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(isProminent ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .focusable(false)
            .background(
                ZStack {
                    // Base gradient background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            configuration.isPressed
                                ? color.opacity(isProminent ? 0.9 : 0.3)
                                : color.opacity(isProminent ? 0.7 : 0.15)
                        )
                    
                    // Border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            isProminent
                                ? color.opacity(0.8)
                                : .white.opacity(0.3),
                            lineWidth: 1.5
                        )
                }
            )
            .shadow(
                color: isProminent
                    ? color.opacity(configuration.isPressed ? 0.6 : 0.4)
                    : .black.opacity(0.1),
                radius: configuration.isPressed ? 12 : 6,
                x: 0,
                y: configuration.isPressed ? 4 : 2
            )
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    HapticFeedback.prolonged()
                }
            }
    }
}

extension ButtonStyle where Self == GradientWaveButtonStyle {
    static var gradientWave: GradientWaveButtonStyle { GradientWaveButtonStyle() }
    static func gradientWave(color: Color, prominent: Bool = false) -> GradientWaveButtonStyle {
        GradientWaveButtonStyle(color: color, isProminent: prominent)
    }
}

// MARK: - Small Gradient Button Style (for MenuBar)
struct SmallGradientButtonStyle: ButtonStyle {
    var color: Color = .accentColor
    var isProminent: Bool = false
    var cornerRadius: CGFloat = 8
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.caption, design: .rounded).weight(.medium))
            .foregroundStyle(isProminent ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .focusable(false)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            configuration.isPressed
                                ? color.opacity(isProminent ? 0.9 : 0.3)
                                : color.opacity(isProminent ? 0.7 : 0.12)
                        )
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            isProminent
                                ? color.opacity(0.6)
                                : .white.opacity(0.25),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: isProminent
                    ? color.opacity(configuration.isPressed ? 0.5 : 0.3)
                    : .black.opacity(0.08),
                radius: configuration.isPressed ? 6 : 3,
                x: 0,
                y: configuration.isPressed ? 3 : 1
            )
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    HapticFeedback.light()
                }
            }
    }
}

extension ButtonStyle where Self == SmallGradientButtonStyle {
    static var smallGradient: SmallGradientButtonStyle { SmallGradientButtonStyle() }
    static func smallGradient(color: Color, prominent: Bool = false) -> SmallGradientButtonStyle {
        SmallGradientButtonStyle(color: color, isProminent: prominent)
    }
}

// MARK: - Color Circle Button (Glass with Haptic)
struct GlassColorButton: View {
    let name: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            action()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    // Glow layer
                    Circle()
                        .fill(color)
                        .blur(radius: isHovered ? 8 : 0)
                        .opacity(isHovered ? 0.6 : 0)
                        .frame(width: 44, height: 44)
                    
                    // Main circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    color.opacity(0.9),
                                    color
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: color.opacity(0.5), radius: isHovered ? 10 : 4, x: 0, y: 2)
                }
                .scaleEffect(isHovered ? 1.1 : 1)
                .animation(.easeOut(duration: 0.2), value: isHovered)
                
                Text(name)
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
        }
        .buttonStyle(ColorButtonStyle(color: color))
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Color Button Style
struct ColorButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .focusable(false)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            configuration.isPressed
                                ? color.opacity(0.5)
                                : .white.opacity(0.15),
                            lineWidth: configuration.isPressed ? 2 : 1
                        )
                }
            )
            .shadow(
                color: .black.opacity(0.08),
                radius: configuration.isPressed ? 8 : 4,
                x: 0,
                y: configuration.isPressed ? 4 : 2
            )
    }
}

// MARK: - Jingle Button (Glass with Haptic)
struct GlassJingleButton: View {
    let number: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            Text("\(number)")
                .font(.system(.callout, design: .rounded).weight(.bold))
                .frame(width: 50, height: 40)
        }
        .buttonStyle(JingleButtonStyle())
    }
}

// MARK: - Jingle Button Style
struct JingleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? .white : .secondary)
            .focusable(false)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            configuration.isPressed
                                ? Color.accentColor.opacity(0.7)
                                : Color.gray.opacity(0.1)
                        )
                    
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            configuration.isPressed
                                ? Color.accentColor.opacity(0.5)
                                : .white.opacity(0.2),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: .black.opacity(0.1),
                radius: configuration.isPressed ? 6 : 3,
                x: 0,
                y: configuration.isPressed ? 3 : 1
            )
    }
}

// MARK: - Stepper Button Component
struct StepperButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(StepperButtonStyle())
    }
}

// MARK: - Stepper Button Style
struct StepperButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? .white : .primary)
            .focusable(false)
            .background(
                ZStack {
                    Circle()
                        .fill(
                            configuration.isPressed
                                ? Color.accentColor.opacity(0.7)
                                : Color.gray.opacity(0.15)
                        )
                    
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
            )
    }
}

// MARK: - Glass Stepper
struct GlassStepper: View {
    @Binding var value: Int
    var suffix: String = ""
    var range: ClosedRange<Int> = 1...99
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(value)\(suffix.isEmpty ? "" : " \(suffix)")")
                .font(.system(.callout, design: .rounded).weight(.semibold))
                .frame(minWidth: 50, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 8) {
                StepperButton(icon: "minus") {
                    if value > range.lowerBound {
                        value -= 1
                    }
                }
                
                StepperButton(icon: "plus") {
                    if value < range.upperBound {
                        value += 1
                    }
                }
            }
        }
        .padding(10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            }
        )
    }
}

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    var title: String?
    var icon: String?
    var material: Material = .thinMaterial
    var cornerRadius: CGFloat = 16
    var strokeOpacity: Double = 0.2
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                HStack(spacing: 6) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text(title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            
            content
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(material)
                
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(strokeOpacity),
                                .white.opacity(strokeOpacity * 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.1),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        )
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Glass Input Field
struct GlassTextField: View {
    var placeholder: String
    @Binding var text: String
    var icon: String?
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.plain)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
            }
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Material.thinMaterial)
                
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            }
        )
    }
}

// MARK: - Status Badge (Glass)
struct GlassStatusBadge: View {
    var text: String
    var isActive: Bool
    var icon: String?
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.system(.caption, design: .rounded).weight(.medium))
        }
        .foregroundStyle(isActive ? .white : .secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            ZStack {
                Capsule()
                    .fill(isActive ? Color.green.opacity(0.8) : Color.gray.opacity(0.2))
                
                Capsule()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            }
        )
    }
}

// MARK: - Glass Timer Card
struct GlassTimerCard: View {
    let time: String
    let color: Color
    let icon: String
    var isNumber: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            Text(time)
                .font(.system(size: isNumber ? 28 : 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.9),
                                color
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        )
        .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Glass Sidebar Item
struct GlassSidebarItem: View {
    let item: SidebarItem
    var isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(width: 24)
            
            Text(item.rawValue)
                .font(.system(.body, design: .rounded).weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.9),
                                    Color.accentColor.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 3)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                }
            }
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Press Events Helper (deprecated - use ButtonStyle instead)
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

// MARK: - Animated Gradient Background
struct AnimatedGradientBackground: View {
    @State private var start = UnitPoint(x: 0, y: 0)
    @State private var end = UnitPoint(x: 1, y: 1)
    
    var colors: [Color] = [
        Color.purple.opacity(0.15),
        Color.blue.opacity(0.15),
        Color.cyan.opacity(0.1),
        Color.pink.opacity(0.1)
    ]
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: start,
            endPoint: end
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                start = UnitPoint(x: 1, y: 1)
                end = UnitPoint(x: 0, y: 0)
            }
        }
    }
}

// MARK: - Mesh Gradient Background (macOS 14+)
// Versión segura sin GeometryReader para evitar layout loops
struct MeshGradientBackground: View {
    var body: some View {
        ZStack {
            // Base color
            Color(NSColor.windowBackgroundColor)
            
            // Gradient background estático (sin GeometryReader)
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.08),
                    Color.cyan.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}
