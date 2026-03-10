//
//  LiquidGlassStyles.swift
//  Busylight
//
//  NATIVE Apple Liquid Glass components (macOS 15+/26+).
//  
//  Uses:
//  - RoundedRectangle(cornerRadius: 16-20) for consistent shapes
//  - Capsule() for pill-style buttons
//  - .ultraThinMaterial for native vibrancy
//  - 16-24pt corner radius across all components
//
//  Relationships:
//  - Used by: All View files (ContentView, PomodoroView, SettingsView, etc.)
//  - See: LiquidCard.swift for card containers
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
    
    static func prolonged() {
        let performer = NSHapticFeedbackManager.defaultPerformer
        performer.perform(.generic, performanceTime: .now)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            performer.perform(.generic, performanceTime: .now)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            performer.perform(.generic, performanceTime: .now)
        }
    }
}

// MARK: - Native Liquid Glass Background
struct LiquidGlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func liquidGlassBackground() -> some View {
        modifier(LiquidGlassBackground())
    }
}

// MARK: - Native Liquid Glass Button Style
struct LiquidGlassButtonStyle: ButtonStyle {
    var color: Color = .accentColor
    var isProminent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(isProminent ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isProminent ? color : Color.clear)
                    .background(.ultraThinMaterial)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .focusable(false)
    }
}

extension ButtonStyle where Self == LiquidGlassButtonStyle {
    static var liquidGlass: LiquidGlassButtonStyle { LiquidGlassButtonStyle() }
    static func liquidGlass(color: Color, prominent: Bool = false) -> LiquidGlassButtonStyle {
        LiquidGlassButtonStyle(color: color, isProminent: prominent)
    }
}

// MARK: - Native Liquid Glass Action Button
struct LiquidGlassActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var isProminent: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: isProminent ? 18 : 16, weight: .semibold))
                Text(title)
                    .font(.system(isProminent ? .headline : .subheadline, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(isProminent ? .white : color)
            .frame(maxWidth: .infinity)
            .frame(height: isProminent ? 56 : 48)
        }
        .buttonStyle(.liquidGlass(color: color, prominent: isProminent))
        .focusable(false)
    }
}

// MARK: - Native Liquid Glass Icon Button
struct LiquidGlassIconButton: View {
    let icon: String
    let color: Color
    var isLarge: Bool = false
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: isLarge ? 28 : 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: isLarge ? 70 : 50, height: isLarge ? 70 : 50)
                .background(color)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .scaleEffect(isHovered ? 0.9 : 1.0)
        .shadow(color: color.opacity(isHovered ? 0.6 : 0.3), radius: isHovered ? 10 : 5, x: 0, y: isHovered ? 5 : 2)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .focusable(false)
    }
}

// MARK: - Native Liquid Glass Toggle Row
struct LiquidGlassToggleRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: subtitle != nil ? 2 : 0) {
                Text(title)
                    .font(.system(.body, design: .rounded))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Native Liquid Glass Text Field
struct LiquidGlassTextField: View {
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Native Liquid Glass Status Badge
struct LiquidGlassStatusBadge: View {
    var text: String
    var isActive: Bool
    var icon: String?
    @State private var isHovered = false

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
        .background(isActive ? Color.green : Color.clear)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .onHover { hovering in
            isHovered = hovering
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .brightness(isHovered ? 0.05 : 0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

// MARK: - Native Liquid Glass Timer Card
struct LiquidGlassTimerCard: View {
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
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Native Liquid Glass Sidebar Item
struct LiquidGlassSidebarItem: View {
    let item: SidebarItem
    var isSelected: Bool
    @State private var isHovered = false

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
            isSelected ? Color.accentColor : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .scaleEffect(isHovered ? (isSelected ? 1.02 : 0.98) : 1.0)
        .brightness(isHovered ? 0.03 : 0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

// MARK: - Presentation Background
struct PresentationBackgroundView: View {
    var body: some View {
        ZStack {
            Color.clear
                .background(.ultraThinMaterial)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Press Effect Modifier
struct PressEffectModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

extension View {
    func pressEffect() -> some View {
        modifier(PressEffectModifier())
    }
}
