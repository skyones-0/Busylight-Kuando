//
//  SharedStyles.swift
//  BusylightShared
//
//  Modern Glassmorphism styles for all platforms
//

import SwiftUI

public struct GlassBackground: ViewModifier {
    var material: Material
    var cornerRadius: CGFloat
    var strokeOpacity: Double
    
    public init(
        material: Material = .ultraThinMaterial,
        cornerRadius: CGFloat = 20,
        strokeOpacity: Double = 0.2
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.strokeOpacity = strokeOpacity
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(material)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
    }
}

public extension View {
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

public struct GlassCard<Content: View>: View {
    var title: String?
    var icon: String?
    var material: Material
    var cornerRadius: CGFloat
    @ViewBuilder var content: Content
    
    public init(
        title: String? = nil,
        icon: String? = nil,
        material: Material = .thinMaterial,
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.material = material
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    public var body: some View {
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

public struct GlassButton: View {
    let title: String
    let icon: String?
    let color: Color
    let isProminent: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    public init(
        title: String,
        icon: String? = nil,
        color: Color,
        isProminent: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isProminent = isProminent
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
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
                        .stroke(isProminent ? color.opacity(0.5) : color.opacity(0.3), lineWidth: 1.5)
                }
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

public struct GlassStepper: View {
    let icon: String
    let title: String?
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    public init(
        icon: String,
        title: String? = nil,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) {
        self.icon = icon
        self.title = title
        self._value = value
        self.range = range
    }
    
    public var body: some View {
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

public struct PhaseBadge: View {
    let phase: PomodoroPhase
    let isActive: Bool
    
    public init(phase: PomodoroPhase, isActive: Bool) {
        self.phase = phase
        self.isActive = isActive
    }
    
    public var body: some View {
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
                .overlay(Capsule().stroke(phase.color.opacity(0.3), lineWidth: 1))
        )
    }
}

public struct TimerDisplay: View {
    let timeString: String
    let phase: PomodoroPhase
    let isRunning: Bool
    let size: TimerSize
    
    public enum TimerSize {
        case small, medium, large
        var fontSize: CGFloat {
            switch self {
            case .small: return 48
            case .medium: return 72
            case .large: return 96
            }
        }
    }
    
    public init(timeString: String, phase: PomodoroPhase, isRunning: Bool, size: TimerSize) {
        self.timeString = timeString
        self.phase = phase
        self.isRunning = isRunning
        self.size = size
    }
    
    public var body: some View {
        ZStack {
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

public struct GlassProgressBar: View {
    let progress: Double
    let color: Color
    var height: CGFloat
    
    public init(progress: Double, color: Color, height: CGFloat = 8) {
        self.progress = progress
        self.color = color
        self.height = height
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.2))
                
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(LinearGradient(colors: [color.opacity(0.8), color], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geometry.size.width * CGFloat(progress))
                    .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 0)
            }
        }
        .frame(height: height)
    }
}

public struct MeshGradientBackground: View {
    @State private var animate = false
    
    public init() {}
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                #if os(iOS)
                Color(.systemBackground)
                #else
                Color(NSColor.windowBackgroundColor)
                #endif
                
                Circle()
                    .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .blur(radius: 80)
                    .frame(width: 300, height: 300)
                    .offset(x: animate ? 50 : -50, y: animate ? -30 : 30)
                    .opacity(0.3)
                
                Circle()
                    .fill(LinearGradient(colors: [.cyan, .green], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .blur(radius: 90)
                    .frame(width: 350, height: 350)
                    .offset(x: animate ? -40 : 40, y: animate ? 50 : -50)
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

public struct GlassToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    public init(icon: String, title: String, isOn: Binding<Bool>) {
        self.icon = icon
        self.title = title
        self._isOn = isOn
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.gray.opacity(0.15)))
            
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
