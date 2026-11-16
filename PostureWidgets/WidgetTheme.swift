import SwiftUI
import UIKit
import WidgetKit

/// Mirrors the app's `Theme` so widgets read as part of the same product.
/// (The widget extension can't import the app target, so the tokens are duplicated here.)
enum WidgetTheme {
    static let brand = Color(light: 0x0F9D8A, dark: 0x2DD4BF)
    static let brandSoft = Color(light: 0xE6F6F3, dark: 0x0E2E2A)
    static let onBrand = Color(light: 0xFFFFFF, dark: 0x042F2A)

    static let good = Color(light: 0x16A34A, dark: 0x4ADE80)
    static let warning = Color(light: 0xD97706, dark: 0xFBBF24)
    static let alert = Color(light: 0xDC2626, dark: 0xF87171)
    static let neutral = Color(light: 0x8E8E93, dark: 0x98989F)

    static let background = Color(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let surface = Color(light: 0xF2F2F7, dark: 0x2C2C2E)

    static func scoreTint(_ score: Int) -> Color {
        switch score {
        case 80...: return good
        case 60..<80: return warning
        default: return alert
        }
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

// MARK: - Shared widget pieces

/// Same 240° downward-opening arc as the app's posture gauge.
struct WidgetGaugeArc: Shape {
    var start: Double
    var end: Double
    var sweep: Double = 240

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

/// Compact version of the app's hero gauge.
struct WidgetPostureGauge: View {
    let entry: PostureWidgetEntry
    var lineWidth: CGFloat = 8
    var valueFont: Font = .system(size: 26, weight: .bold, design: .rounded)
    var caption: String = "lean"
    var captionTint: Color? = nil

    private let maxDegrees = 30.0
    private var state: WidgetPostureState { entry.postureState }
    private var isLive: Bool { state == .good || state == .warning || state == .alert }
    private var progress: Double { min(entry.forwardLean / maxDegrees, 1) }
    private var thresholdProgress: Double { min(entry.threshold / maxDegrees, 1) }

    var body: some View {
        ZStack {
            WidgetGaugeArc(start: 0, end: 1)
                .stroke(WidgetTheme.neutral.opacity(0.18), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            WidgetGaugeArc(start: thresholdProgress, end: 1)
                .stroke(WidgetTheme.alert.opacity(isLive ? 0.3 : 0.12), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            if isLive {
                WidgetGaugeArc(start: 0, end: max(progress, 0.02))
                    .stroke(state.tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .widgetAccentable()
            }
            center
        }
        .padding(lineWidth / 2)
    }

    /// Value (or state icon) in the middle; the caption sits in the arc's open bottom so it
    /// never collides with the end caps.
    private var center: some View {
        ZStack {
            if isLive {
                Text("\(Int(entry.forwardLean.rounded()))°")
                    .font(valueFont)
                    .minimumScaleFactor(0.6)
            } else {
                Image(systemName: state.symbolName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(state.tint)
                    .widgetAccentable()
            }

            if isLive || captionTint != nil {
                Text(caption)
                    .font(.system(.caption2, design: .rounded).weight(captionTint == nil ? .regular : .semibold))
                    .foregroundStyle(captionTint ?? .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
    }
}

/// Small circular "today score" ring, matching the app's ScoreRing.
struct WidgetScoreRing: View {
    let score: Int?
    var lineWidth: CGFloat = 5

    var body: some View {
        ZStack {
            Circle().stroke(WidgetTheme.neutral.opacity(0.18), lineWidth: lineWidth)
            if let score {
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(WidgetTheme.scoreTint(score), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .widgetAccentable()
            }
            Text(score.map { "\($0)" } ?? "—")
                .font(.system(.footnote, design: .rounded).weight(.semibold).monospacedDigit())
        }
    }
}

/// Filled pill button used for the primary widget action.
struct WidgetPillLabel: View {
    let title: String
    let systemImage: String
    let filled: Bool

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(.footnote, design: .rounded).weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(filled ? WidgetTheme.onBrand : WidgetTheme.brand)
            .frame(maxWidth: .infinity, minHeight: 34)
            .background(
                filled ? AnyShapeStyle(WidgetTheme.brand) : AnyShapeStyle(WidgetTheme.brand.opacity(0.14)),
                in: Capsule()
            )
            .widgetAccentable()
    }
}

/// Small header used at the top of home screen widgets.
struct WidgetBrandHeader: View {
    let entry: PostureWidgetEntry

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "figure.stand")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(WidgetTheme.onBrand)
                .frame(width: 20, height: 20)
                .background(WidgetTheme.brand, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .widgetAccentable()
            Text("Posture")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            if entry.snapshot.isMonitoring {
                HStack(spacing: 4) {
                    Circle().fill(entry.postureState.tint).frame(width: 6, height: 6)
                    Text(entry.postureState == .onTable ? "PAUSED" : "LIVE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(0.6)
                        .foregroundStyle(entry.postureState.tint)
                }
            }
        }
    }
}

extension View {
    /// Widget background: plain app surface with a faint wash of the current posture color.
    func postureWidgetBackground(_ state: WidgetPostureState) -> some View {
        containerBackground(for: .widget) {
            ZStack {
                WidgetTheme.background
                LinearGradient(
                    colors: [state.tint.opacity(state == .stopped ? 0.0 : 0.12), .clear],
                    startPoint: .top, endPoint: .bottom
                )
            }
        }
    }
}
