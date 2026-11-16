import SwiftUI
import WidgetKit
import AppIntents

/// Circular lock screen control: shows the live lean as a gauge while a session runs,
/// and taps to start/stop the session.
struct LockScreenToggleWidget: Widget {
    let kind = "LockScreenToggleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PostureTimelineProvider()) { entry in
            CircularPostureView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Posture Session")
        .description("See your lean and start or end a session from the Lock Screen.")
        .supportedFamilies([.accessoryCircular])
    }
}

private struct CircularPostureView: View {
    let entry: PostureWidgetEntry

    var body: some View {
        Button(intent: SetMonitoringIntent(value: !entry.snapshot.isMonitoring)) {
            ZStack {
                AccessoryWidgetBackground()
                if entry.snapshot.isMonitoring && entry.postureState != .onTable {
                    Gauge(value: min(entry.forwardLean, 30), in: 0...30) {
                        Image(systemName: "figure.stand")
                    } currentValueLabel: {
                        Text("\(Int(entry.forwardLean.rounded()))°")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                    }
                    .gaugeStyle(.accessoryCircular)
                } else {
                    VStack(spacing: 1) {
                        Image(systemName: entry.snapshot.isMonitoring ? "pause.fill" : "figure.stand")
                            .font(.system(size: 20, weight: .semibold))
                            .widgetAccentable()
                        Text(entry.snapshot.isMonitoring ? "Paused" : "Start")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct LockScreenStatusWidget: Widget {
    let kind = "LockScreenStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PostureTimelineProvider()) { entry in
            LockScreenStatusView(entry: entry)
                .containerBackground(.clear, for: .widget)
                .widgetURL(URL(string: "posturehelp://today"))
        }
        .configurationDisplayName("Posture Status")
        .description("Your current posture and today's score.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}

private struct LockScreenStatusView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PostureWidgetEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Label(inlineText, systemImage: "figure.stand")
        default:
            rectangular
        }
    }

    private var inlineText: String {
        guard entry.snapshot.isMonitoring else {
            return entry.snapshot.todayScore.map { "Posture · \($0)% today" } ?? "Posture · Not tracking"
        }
        if entry.postureState == .onTable { return "Posture · Paused" }
        return "\(entry.postureState.shortText) · \(Int(entry.forwardLean.rounded()))°"
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Image(systemName: "figure.stand")
                    .widgetAccentable()
                Text("Posture")
                    .widgetAccentable()
                if entry.snapshot.isMonitoring {
                    Text(entry.postureState == .onTable ? "· Paused" : "· Live")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.system(.caption, design: .rounded).weight(.semibold))

            Text(entry.postureState.displayText)
                .font(.system(.headline, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(detailText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var detailText: String {
        let today = entry.snapshot.todayScore.map { "Today \($0)%" }
        if entry.snapshot.isMonitoring && entry.postureState != .onTable {
            return ["\(Int(entry.forwardLean.rounded()))° lean", today].compactMap { $0 }.joined(separator: " · ")
        }
        return today ?? entry.postureState.subtitleText
    }
}

#Preview("Circular", as: .accessoryCircular) {
    LockScreenToggleWidget()
} timeline: {
    PostureWidgetEntry.sample()
    PostureWidgetEntry.sample(monitoring: false)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    LockScreenStatusWidget()
} timeline: {
    PostureWidgetEntry.sample()
    PostureWidgetEntry.sample(monitoring: false)
}

#Preview("Inline", as: .accessoryInline) {
    LockScreenStatusWidget()
} timeline: {
    PostureWidgetEntry.sample()
}
