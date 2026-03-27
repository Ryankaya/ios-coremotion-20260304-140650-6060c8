import SwiftUI

enum Theme {
    enum Colors {
        static let primary = Color.blue
        static let success = Color.green
        static let warning = Color.orange
        static let danger = Color.red
        static let background = Color(.systemGroupedBackground)
        static let cardBackground = Color(.secondarySystemGroupedBackground)
        static let text = Color.primary
        static let secondaryText = Color.secondary
    }
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }
    
    enum Typography {
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title = Font.system(.title2, design: .rounded).weight(.semibold)
        static let headline = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .default)
        static let caption = Font.system(.caption, design: .default)
        static let callout = Font.system(.callout, design: .default)
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.lg, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    func glassCardStyle() -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.xl, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xl, style: .continuous)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    func premiumCardStyle(borderColor: Color = .white) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.xl * 1.5, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xl * 1.5, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [borderColor.opacity(0.3), borderColor.opacity(0.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
}
