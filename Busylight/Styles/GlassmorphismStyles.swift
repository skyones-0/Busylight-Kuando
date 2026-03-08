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
    
    @State private var isPressed: Bool = false
    @State private var shimmerOffset: CGFloat = -1
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(isProminent ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    // Base gradient background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: isProminent 
                                    ? [color.opacity(0.9), color.opacity(0.6)]
                                    : [Color.gray.opacity(0.25), Color.gray.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Shimmer effect
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.4),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.5)
                        .offset(x: geo.size.width * shimmerOffset)
                        .blur(radius: 5)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    
                    // Pressed glow
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            RadialGradient(
                                colors: [
                                    color.opacity(isPressed ? 0.5 : 0.0),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                    
                    // Border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: isProminent
                                    ? [color.opacity(0.8), color.opacity(0.4)]
                                    : [.white.opacity(0.4), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .shadow(
                color: isProminent 
                    ? color.opacity(isPressed ? 0.6 : 0.4)
                    : .black.opacity(0.1),
                radius: isPressed ? 15 : 8,
                x: 0,
                y: isPressed ? 6 : 3
            )
            .scaleEffect(isPressed ? 0.96 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
                if pressed {
                    HapticFeedback.medium()
                    // Trigger shimmer
                    withAnimation(.linear(duration: 0.6)) {
                        shimmerOffset = 2
                    }
                } else {
                    shimmerOffset = -1
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
    
    @State private var isPressed: Bool = false
    @State private var shimmerOffset: CGFloat = -1
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.caption, design: .rounded).weight(.medium))
            .foregroundStyle(isProminent ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    // Base gradient
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: isProminent
                                    ? [color.opacity(0.85), color.opacity(0.55)]
                                    : [Color.gray.opacity(0.2), Color.gray.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Shimmer
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.5), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.4)
                        .offset(x: geo.size.width * shimmerOffset)
                        .blur(radius: 3)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    
                    // Press glow
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            RadialGradient(
                                colors: [color.opacity(isPressed ? 0.4 : 0), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                    
                    // Border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            isProminent
                                ? color.opacity(0.6)
                                : .white.opacity(0.3),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: isProminent
                    ? color.opacity(isPressed ? 0.5 : 0.3)
                    : .black.opacity(0.08),
                radius: isPressed ? 8 : 4,
                x: 0,
                y: isPressed ? 4 : 2
            )
            .scaleEffect(isPressed ? 0.95 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
                if pressed {
                    HapticFeedback.light()
                    withAnimation(.linear(duration: 0.5)) {
                        shimmerOffset = 2
                    }
                } else {
                    shimmerOffset = -1
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
    @State private var isPressed = false
    @State private var rippleScale: CGFloat = 0.5
    @State private var rippleOpacity: Double = 0
    
    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            action()
        }) {
            VStack(spacing: 8) {
                // Color circle with wave effect
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
                    
                    // Wave ripple effect
                    Circle()
                        .stroke(color.opacity(0.6), lineWidth: 2)
                        .frame(width: 40, height: 40)
                        .scaleEffect(rippleScale)
                        .opacity(rippleOpacity)
                }
                .scaleEffect(isPressed ? 0.9 : isHovered ? 1.1 : 1)
                
                Text(name)
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
        }
        .buttonStyle(.plain)
        .padding(8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.thinMaterial)
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(isHovered ? 0.3 : 0.15), lineWidth: 1)
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(isHovered ? 0.15 : 0.05),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .shadow(color: .black.opacity(0.08), radius: isHovered ? 12 : 4, x: 0, y: isHovered ? 6 : 2)
        .scaleEffect(isPressed ? 0.95 : 1)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .pressEvents {
            isPressed = true
            // Trigger wave
            withAnimation(.easeOut(duration: 0.3)) {
                rippleScale = 1.3
                rippleOpacity = 0.8
            }
        } onRelease: {
            isPressed = false
            withAnimation(.easeIn(duration: 0.3)) {
                rippleScale = 1.8
                rippleOpacity = 0
            }
        }
    }
}

// MARK: - Jingle Button (Glass with Haptic)
struct GlassJingleButton: View {
    let number: Int
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    @State private var rippleScale: CGFloat = 0.5
    @State private var rippleOpacity: Double = 0
    
    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            Text("\(number)")
                .font(.system(.callout, design: .rounded).weight(.bold))
                .foregroundStyle(
                    isHovered ? .primary : .secondary
                )
                .frame(width: 50, height: 40)
        }
        .buttonStyle(.plain)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Material.thinMaterial)
                
                // Wave effect
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.5), lineWidth: 1.5)
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
                
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(isHovered ? 0.5 : 0.2),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                
                // Inner highlight
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(isHovered ? 0.1 : 0.05),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .shadow(
            color: .black.opacity(0.1),
            radius: isHovered ? 8 : 3,
            x: 0,
            y: isHovered ? 4 : 1
        )
        .scaleEffect(isPressed ? 0.92 : isHovered ? 1.05 : 1)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .pressEvents {
            isPressed = true
            withAnimation(.easeOut(duration: 0.25)) {
                rippleScale = 1.1
                rippleOpacity = 1.0
            }
        } onRelease: {
            isPressed = false
            withAnimation(.easeIn(duration: 0.25)) {
                rippleScale = 1.4
                rippleOpacity = 0
            }
        }
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
                
                // Top highlight
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

// MARK: - Glass Stepper
struct GlassStepper: View {
    @Binding var value: Int
    var suffix: String = ""
    var range: ClosedRange<Int> = 1...99
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(value)\(suffix.isEmpty ? "" : "\(suffix)")")
                .font(.system(.callout, design: .rounded).weight(.semibold))
                .frame(minWidth: 40)
            
            Spacer()
            
            HStack(spacing: 4) {
                Button {
                    if value > range.lowerBound {
                        value -= 1
                        HapticFeedback.light()
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.caption.weight(.bold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .background(
                    Circle()
                        .fill(Material.thinMaterial)
                        .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))
                )
                
                Button {
                    if value < range.upperBound {
                        value += 1
                        HapticFeedback.light()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .background(
                    Circle()
                        .fill(Material.thinMaterial)
                        .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))
                )
            }
        }
        .padding(10)
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
                
                // Highlight
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

// MARK: - Press Events Helper
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
struct MeshGradientBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                Color(NSColor.windowBackgroundColor)
                
                // Animated blobs
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .blur(radius: 60)
                    .frame(width: 300, height: 300)
                    .offset(x: -geometry.size.width * 0.2, y: -geometry.size.height * 0.2)
                
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .blur(radius: 80)
                    .frame(width: 400, height: 400)
                    .offset(x: geometry.size.width * 0.3, y: geometry.size.height * 0.1)
                
                Circle()
                    .fill(Color.cyan.opacity(0.12))
                    .blur(radius: 50)
                    .frame(width: 250, height: 250)
                    .offset(x: geometry.size.width * 0.1, y: geometry.size.height * 0.4)
                
                Circle()
                    .fill(Color.pink.opacity(0.1))
                    .blur(radius: 70)
                    .frame(width: 350, height: 350)
                    .offset(x: -geometry.size.width * 0.1, y: geometry.size.height * 0.3)
            }
        }
        .ignoresSafeArea()
    }
}
