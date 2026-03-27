import SwiftUI

struct PostureStatusCard: View {
    let postureState: PostureState
    let leanDelta: Double
    
    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground(state: postureState)
            
            VStack(spacing: Theme.Spacing.xl) {
                // Hero status circle with mesh gradient
                ZStack {
                    // Outer glow rings
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [stateColor.opacity(0.3), stateColor.opacity(0.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 140 + CGFloat(index * 20), height: 140 + CGFloat(index * 20))
                            .opacity(1.0 - Double(index) * 0.3)
                    }
                    
                    // Main status circle with mesh gradient effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    stateColor.opacity(0.9),
                                    stateColor.opacity(0.7),
                                    stateColor
                                ],
                                center: .topLeading,
                                startRadius: 5,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                        .overlay {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.5), .white.opacity(0.0)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        }
                        .shadow(color: stateColor.opacity(0.5), radius: 30, x: 0, y: 10)
                        .shadow(color: stateColor.opacity(0.3), radius: 50, x: 0, y: 20)
                    
                    // Icon with glow
                    Image(systemName: stateIcon)
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .padding(.top, Theme.Spacing.xl)
                
                // Status text with style
                VStack(spacing: Theme.Spacing.sm) {
                    Text(postureState.displayText)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [stateColor, stateColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    if leanDelta < 0 {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "angle")
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text("\(Int(abs(leanDelta)))° forward")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(stateColor.opacity(0.8))
                                .shadow(color: stateColor.opacity(0.4), radius: 8, x: 0, y: 4)
                        )
                    }
                }
                .padding(.bottom, Theme.Spacing.lg)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 360)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xl * 1.5, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl * 1.5, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        }
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
    
    private var stateColor: Color {
        switch postureState {
        case .unknown:
            return Color.gray
        case .good:
            return Theme.Colors.success
        case .warning:
            return Theme.Colors.warning
        case .alert:
            return Theme.Colors.danger
        }
    }
    
    private var stateIcon: String {
        switch postureState {
        case .unknown:
            return "questionmark"
        case .good:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .alert:
            return "xmark.circle.fill"
        }
    }
}

// MARK: - Animated Gradient Background (Performance optimized)
struct AnimatedGradientBackground: View {
    let state: PostureState
    
    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .opacity(0.9)
    }
    
    private var gradientColors: [Color] {
        switch state {
        case .good:
            return [
                Color.green.opacity(0.6),
                Color.mint.opacity(0.4),
                Color.cyan.opacity(0.3)
            ]
        case .warning:
            return [
                Color.orange.opacity(0.6),
                Color.yellow.opacity(0.4),
                Color.pink.opacity(0.3)
            ]
        case .alert:
            return [
                Color.red.opacity(0.7),
                Color.pink.opacity(0.5),
                Color.purple.opacity(0.4)
            ]
        case .unknown:
            return [
                Color.gray.opacity(0.4),
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.2)
            ]
        }
    }
}
