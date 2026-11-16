import SwiftUI

/// Arc gauge showing forward lean against the user's threshold.
/// The safe zone is drawn in the brand-neutral track; past the threshold the arc
/// warms to amber, and the indicator dot carries the live posture color.
struct PostureGauge: View {
    let leanDegrees: Double          // forward lean, >= 0
    let threshold: Double
    let state: PostureState
    let isActive: Bool

    private let maxDegrees: Double = 30
    private let sweep: Double = 240  // degrees of arc
    private let lineWidth: CGFloat = 14
    static let heightRatio: CGFloat = 0.8

    private var progress: Double { min(max(leanDegrees / maxDegrees, 0), 1) }
    private var thresholdProgress: Double { min(threshold / maxDegrees, 1) }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size.width
            ZStack {
                // Track
                GaugeArc(start: 0, end: 1, sweep: sweep)
                    .stroke(Theme.Colors.neutral.opacity(0.15), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                // Danger zone (beyond threshold)
                GaugeArc(start: thresholdProgress, end: 1, sweep: sweep)
                    .stroke(
                        LinearGradient(
                            colors: [Theme.Colors.warning.opacity(0.35), Theme.Colors.alert.opacity(0.45)],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .opacity(isActive ? 1 : 0.4)

                // Live fill
                if isActive {
                    GaugeArc(start: 0, end: max(progress, 0.001), sweep: sweep)
                        .stroke(state.tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .shadow(color: state.tint.opacity(0.35), radius: 8)
                }

                // Threshold tick
                ThresholdTick(progress: thresholdProgress, sweep: sweep, radius: (size - lineWidth) / 2, lineWidth: lineWidth)

                centerLabel
            }
            .padding(lineWidth / 2)
            .frame(width: size, height: size)
            .frame(height: proxy.size.height, alignment: .top)
        }
        // A 240° arc opening downward only needs ~3/4 of a square's height.
        .aspectRatio(1 / Self.heightRatio, contentMode: .fit)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: progress)
        .animation(.easeInOut(duration: 0.3), value: state)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isActive ? "\(Int(leanDegrees)) degrees forward lean. \(state.headline)" : "Not monitoring")
    }

    private var centerLabel: some View {
        VStack(spacing: Theme.Spacing.xs) {
            if isActive {
                Text("\(Int(leanDegrees.rounded()))°")
                    .font(Theme.Typography.display)
                    .contentTransition(.numericText(value: leanDegrees))
                    .foregroundStyle(Theme.Colors.text)
                Text("forward lean")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "figure.stand")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(Theme.Colors.brand)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .offset(y: 6)
    }
}

/// An arc in a gauge that opens downward. `start`/`end` are 0...1 along the sweep.
struct GaugeArc: Shape {
    var start: Double
    var end: Double
    let sweep: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(start, end) }
        set { start = newValue.first; end = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        let begin = 90 + (360 - sweep) / 2
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: .degrees(begin + sweep * start),
            endAngle: .degrees(begin + sweep * end),
            clockwise: false
        )
        return path
    }
}

private struct ThresholdTick: View {
    let progress: Double
    let sweep: Double
    let radius: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        let begin = 90 + (360 - sweep) / 2
        let angle = Angle.degrees(begin + sweep * progress)
        Capsule()
            .fill(Theme.Colors.text.opacity(0.55))
            .frame(width: 3, height: lineWidth + 10)
            .offset(y: -radius)
            .rotationEffect(angle + .degrees(90))
    }
}

#Preview {
    PostureGauge(leanDegrees: 9, threshold: 12, state: .good, isActive: true)
        .padding(40)
}
