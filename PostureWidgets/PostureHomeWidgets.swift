import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Shared controls

private struct SessionButton: View {
    let entry: PostureWidgetEntry
    var compactTitle = false

    var body: some View {
        let isOn = entry.snapshot.isMonitoring
        Button(intent: SetMonitoringIntent(value: !isOn)) {
            WidgetPillLabel(
                title: isOn ? (compactTitle ? "End" : "End Session") : (compactTitle ? "Start" : "Start Session"),
                systemImage: isOn ? "stop.fill" : "play.fill",
                filled: !isOn
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CircleLink: View {
    let url: String
    let systemImage: String
    var dimmed = false

    var body: some View {
        Link(destination: URL(string: url)!) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(WidgetTheme.brand)
                .frame(width: 34, height: 34)
                .background(WidgetTheme.brand.opacity(0.14), in: Circle())
                .opacity(dimmed ? 0.4 : 1)
                .widgetAccentable()
        }
    }
}

// MARK: - Small: status + start/stop

struct MonitoringToggleWidget: Widget {
    let kind = "MonitoringToggleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PostureTimelineProvider()) { entry in
            SmallPostureView(entry: entry)
                .postureWidgetBackground(entry.postureState)
                .widgetURL(URL(string: "posturehelp://today"))
        }
        .configurationDisplayName("Posture")
        .description("Your live posture with a one-tap session button.")
        .supportedFamilies([.systemSmall])
    }
}

private struct SmallPostureView: View {
    let entry: PostureWidgetEntry

    var body: some View {
        VStack(spacing: 6) {
            WidgetBrandHeader(entry: entry)
            WidgetPostureGauge(
                entry: entry, lineWidth: 7,
                valueFont: .system(size: 20, weight: .bold, design: .rounded),
                caption: entry.postureState.shortText, captionTint: entry.postureState.tint
            )
            .aspectRatio(1, contentMode: .fit)
            .frame(maxHeight: .infinity)
            SessionButton(entry: entry, compactTitle: true)
        }
    }
}

// MARK: - Medium: status, gauge, today, actions

struct PostureControlsWidget: Widget {
    let kind = "PostureControlsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PostureTimelineProvider()) { entry in
            MediumPostureView(entry: entry)
                .postureWidgetBackground(entry.postureState)
                .widgetURL(URL(string: "posturehelp://today"))
        }
        .configurationDisplayName("Posture Session")
        .description("Live posture, today's score, and session controls.")
        .supportedFamilies([.systemMedium])
    }
}

private struct MediumPostureView: View {
    let entry: PostureWidgetEntry

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                WidgetBrandHeader(entry: entry)
                Spacer(minLength: 6)
                Text(entry.postureState.displayText)
                    .font(.system(.headline, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(entry.postureState.subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                HStack(spacing: 8) {
                    SessionButton(entry: entry)
                    CircleLink(url: "posturehelp://calibrate", systemImage: "scope", dimmed: entry.snapshot.isMonitoring)
                }
            }

            VStack(spacing: 4) {
                WidgetPostureGauge(entry: entry)
                    .frame(width: 96, height: 96)
                HStack(spacing: 4) {
                    Text("Today")
                        .foregroundStyle(.secondary)
                    Text(entry.snapshot.todayScore.map { "\($0)%" } ?? "—")
                        .fontWeight(.semibold)
                        .foregroundStyle(entry.snapshot.todayScore.map(WidgetTheme.scoreTint) ?? .secondary)
                }
                .font(.system(.caption, design: .rounded))
            }
        }
    }
}

// MARK: - Large: full dashboard

struct PostureDashboardWidget: Widget {
    let kind = "PostureDashboardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PostureTimelineProvider()) { entry in
            LargePostureView(entry: entry)
                .postureWidgetBackground(entry.postureState)
                .widgetURL(URL(string: "posturehelp://today"))
        }
        .configurationDisplayName("Posture Dashboard")
        .description("Live posture, today's progress, smart pause, and controls.")
        .supportedFamilies([.systemLarge])
    }
}

private struct LargePostureView: View {
    let entry: PostureWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetBrandHeader(entry: entry)

            HStack(spacing: 16) {
                WidgetPostureGauge(entry: entry, lineWidth: 8, valueFont: .system(size: 26, weight: .bold, design: .rounded))
                    .frame(width: 88, height: 88)
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.postureState.displayText)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(entry.postureState.subtitleText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                WidgetScoreRing(score: entry.snapshot.todayScore)
                    .frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Today")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    Text(entry.todaySummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Link(destination: URL(string: "posturehelp://insights")!) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(8)
            .background(WidgetTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(spacing: 0) {
                SmartPauseToggle(
                    title: "Pause on a table", systemImage: "iphone.gen3",
                    isOn: entry.snapshot.detectDeviceOnTable,
                    intent: SetDetectTableIntent(value: !entry.snapshot.detectDeviceOnTable)
                )
                SmartPauseToggle(
                    title: "Only while interacting", systemImage: "hand.tap.fill",
                    isOn: entry.snapshot.onlyAlertWhenActive,
                    intent: SetSmartAlertsIntent(value: !entry.snapshot.onlyAlertWhenActive)
                )
                SmartPauseToggle(
                    title: "Portrait only", systemImage: "rectangle.portrait.rotate",
                    isOn: entry.snapshot.onlyAlertInPortrait,
                    intent: SetPortraitOnlyIntent(value: !entry.snapshot.onlyAlertInPortrait)
                )
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                SessionButton(entry: entry)
                CircleLink(url: "posturehelp://calibrate", systemImage: "scope", dimmed: entry.snapshot.isMonitoring)
                CircleLink(url: "posturehelp://settings", systemImage: "gearshape.fill")
            }
        }
    }
}

/// Custom switch row. Interactive widget `Toggle`s render as capsule buttons on recent iOS,
/// which looked inconsistent here, so this draws a settings-style row with a real switch look.
private struct SmartPauseToggle<Intent: AppIntent>: View {
    let title: String
    let systemImage: String
    let isOn: Bool
    let intent: Intent

    var body: some View {
        Button(intent: intent) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WidgetTheme.brand)
                    .frame(width: 24, height: 24)
                    .background(WidgetTheme.brand.opacity(0.14), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                WidgetSwitch(isOn: isOn)
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

private struct WidgetSwitch: View {
    let isOn: Bool

    var body: some View {
        Capsule()
            .fill(isOn ? AnyShapeStyle(WidgetTheme.brand) : AnyShapeStyle(WidgetTheme.neutral.opacity(0.3)))
            .frame(width: 38, height: 22)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.12), radius: 1, y: 1)
                    .padding(2)
            }
            .widgetAccentable()
    }
}

// MARK: - Previews

#Preview("Small · good", as: .systemSmall) {
    MonitoringToggleWidget()
} timeline: {
    PostureWidgetEntry.sample()
    PostureWidgetEntry.sample("alert", lean: -19)
    PostureWidgetEntry.sample(monitoring: false)
}

#Preview("Medium", as: .systemMedium) {
    PostureControlsWidget()
} timeline: {
    PostureWidgetEntry.sample()
    PostureWidgetEntry.sample("warning", lean: -14)
    PostureWidgetEntry.sample(onTable: true)
    PostureWidgetEntry.sample(monitoring: false)
}

#Preview("Large", as: .systemLarge) {
    PostureDashboardWidget()
} timeline: {
    PostureWidgetEntry.sample()
    PostureWidgetEntry.sample(monitoring: false)
}
