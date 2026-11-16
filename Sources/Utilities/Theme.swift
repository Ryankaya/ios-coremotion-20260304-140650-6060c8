import SwiftUI
import UIKit

/// Single source of truth for the app's visual language.
/// Calm, clinical-but-friendly: soft neutral surfaces, one brand accent,
/// and posture state colors that read clearly in both light and dark mode.
enum Theme {
    enum Colors {
        static let brand = Color(light: 0x0F9D8A, dark: 0x2DD4BF)
        static let brandSoft = Color(light: 0xE6F6F3, dark: 0x0E2E2A)
        /// Foreground for content placed on a solid brand fill.
        static let onBrand = Color(light: 0xFFFFFF, dark: 0x042F2A)

        static let good = Color(light: 0x16A34A, dark: 0x4ADE80)
        static let warning = Color(light: 0xD97706, dark: 0xFBBF24)
        static let alert = Color(light: 0xDC2626, dark: 0xF87171)
        static let neutral = Color(light: 0x8E8E93, dark: 0x98989F)

        static let background = Color(.systemGroupedBackground)
        static let surface = Color(.secondarySystemGroupedBackground)
        static let surfaceRaised = Color(.tertiarySystemGroupedBackground)
        static let separator = Color(.separator)
        static let text = Color.primary
        static let secondaryText = Color.secondary

        // Kept for older call sites.
        static let primary = brand
        static let success = good
        static let danger = alert
        static let cardBackground = surface
    }

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum CornerRadius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }

    enum Typography {
        static let display = Font.system(size: 56, weight: .bold, design: .rounded)
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title = Font.system(.title2, design: .rounded).weight(.bold)
        static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)
        static let headline = Font.system(.headline, design: .rounded)
        static let body = Font.body
        static let callout = Font.callout
        static let caption = Font.caption
        static let overline = Font.system(.caption2, design: .rounded).weight(.semibold)
        static let metric = Font.system(.title2, design: .rounded).weight(.semibold).monospacedDigit()
    }
}

// MARK: - Color helpers

extension Color {
    /// Dynamic color from two hex values, resolved per trait collection.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Posture state presentation

extension PostureState {
    var tint: Color {
        switch self {
        case .unknown: return Theme.Colors.neutral
        case .good: return Theme.Colors.good
        case .warning: return Theme.Colors.warning
        case .alert: return Theme.Colors.alert
        }
    }

    var symbol: String {
        switch self {
        case .unknown: return "figure.stand"
        case .good: return "checkmark"
        case .warning: return "exclamationmark"
        case .alert: return "arrow.up"
        }
    }

    var headline: String {
        switch self {
        case .unknown: return "Ready when you are"
        case .good: return "Looking good"
        case .warning: return "Leaning forward"
        case .alert: return "Sit up straight"
        }
    }
}

// MARK: - Surfaces

extension View {
    /// Standard grouped card used across the app.
    func cardStyle(padding: CGFloat = Theme.Spacing.md) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.lg, style: .continuous))
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.Colors.brand
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(isEnabled ? Theme.Colors.onBrand : Color.white.opacity(0.8))
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                    .fill(isEnabled ? tint : Theme.Colors.neutral.opacity(0.4))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.Colors.brand

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                    .fill(tint.opacity(0.12))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static func primary(_ tint: Color) -> PrimaryButtonStyle { PrimaryButtonStyle(tint: tint) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

// MARK: - Small shared pieces

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Theme.Typography.title3)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.xs)
    }
}

struct IconBadge: View {
    let systemName: String
    var tint: Color = Theme.Colors.brand
    var size: CGFloat = 36

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
    }
}
