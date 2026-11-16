import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var viewModel: PostureViewModel
    let onCalibrate: () -> Void
    let onOpenInsights: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    if !viewModel.isMotionAvailable {
                        NoticeCard(
                            icon: "sensor.fill",
                            tint: Theme.Colors.warning,
                            title: "Motion sensors unavailable",
                            message: "Posture tracking needs a physical iPhone. The Simulator can't provide motion data."
                        )
                    } else if !viewModel.notificationsEnabled {
                        NoticeCard(
                            icon: "bell.badge.fill",
                            tint: Theme.Colors.brand,
                            title: "Get nudged in other apps",
                            message: "Turn on notifications so reminders reach you while you scroll.",
                            actionTitle: "Turn On"
                        ) {
                            Task { await viewModel.requestNotifications() }
                        }
                    }

                    heroCard
                    if viewModel.isMonitoring || viewModel.sessionStartDate != nil {
                        sessionCard
                    }
                    smartPauseCard
                    todayCard
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.lg)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onCalibrate) {
                        Label("Calibrate", systemImage: "scope")
                    }
                    .disabled(viewModel.isMonitoring)
                }
            }
        }
    }

    // MARK: Hero

    private var leanDegrees: Double { max(0, -viewModel.metrics.leanDeltaDegrees) }
    private var state: PostureState { viewModel.isMonitoring ? viewModel.metrics.postureState : .unknown }

    private var heroCard: some View {
        VStack(spacing: Theme.Spacing.lg) {
            PostureGauge(
                leanDegrees: leanDegrees,
                threshold: viewModel.configuration.forwardLeanThresholdDegrees,
                state: state,
                isActive: viewModel.isMonitoring
            )
            .frame(maxWidth: 260)
            .padding(.top, Theme.Spacing.lg)
            .padding(.horizontal, Theme.Spacing.lg)

            VStack(spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.sm) {
                    if viewModel.isMonitoring {
                        Circle()
                            .fill(viewModel.pauseReason == nil ? state.tint : Theme.Colors.neutral)
                            .frame(width: 8, height: 8)
                    }
                    Text(viewModel.isMonitoring ? state.headline : "Ready when you are")
                        .font(Theme.Typography.title)
                        .contentTransition(.opacity)
                }
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .animation(.easeInOut(duration: 0.25), value: state)

            primaryControls
        }
        .cardStyle(padding: Theme.Spacing.md)
        .sensoryFeedback(.selection, trigger: viewModel.isMonitoring)
    }

    private var subtitle: String {
        guard viewModel.isMonitoring else {
            return viewModel.metrics.isBaselineSet
                ? "Your upright posture is calibrated. Start a session and keep using your phone as usual."
                : "Sit upright and start a session. We'll calibrate to your natural posture first."
        }
        if let reason = viewModel.pauseReason {
            return "Alerts paused · \(reason)"
        }
        switch state {
        case .good, .unknown:
            return "We'll nudge you if you lean past \(Int(viewModel.configuration.forwardLeanThresholdDegrees))° for \(Int(viewModel.configuration.sustainedSeconds))s."
        case .warning:
            return "Lift your phone or your chin a little."
        case .alert:
            return "Roll your shoulders back and raise your screen to eye level."
        }
    }

    @ViewBuilder
    private var primaryControls: some View {
        if viewModel.isMonitoring {
            Button(role: .destructive, action: viewModel.stopMonitoring) {
                Label("End Session", systemImage: "stop.fill")
            }
            .buttonStyle(.secondary)
        } else {
            Button(action: viewModel.startMonitoring) {
                Label("Start Session", systemImage: "play.fill")
            }
            .buttonStyle(.primary)
            .disabled(!viewModel.isMotionAvailable)
        }
    }

    // MARK: Session

    private var sessionCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text(viewModel.isMonitoring ? "This session" : "Last session")
                    .font(Theme.Typography.headline)
                Spacer()
                if viewModel.isMonitoring {
                    LiveBadge()
                }
            }

            HStack(spacing: 0) {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    StatColumn(value: sessionDurationText, label: "Duration")
                }
                Divider().frame(height: 36)
                StatColumn(
                    value: viewModel.sessionScore.map { "\($0)%" } ?? "—",
                    label: "Upright",
                    tint: viewModel.sessionScore.map(scoreTint)
                )
                Divider().frame(height: 36)
                StatColumn(value: "\(viewModel.sessionAlerts)", label: "Nudges")
            }
        }
        .cardStyle()
    }

    private var sessionDurationText: String {
        guard let start = viewModel.sessionStartDate else { return "—" }
        let seconds = Int(Date().timeIntervalSince(start))
        let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    // MARK: Smart pause

    private var smartPauseCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Smart pause")
                .font(Theme.Typography.headline)

            HStack(spacing: Theme.Spacing.sm) {
                ContextChip(
                    icon: viewModel.isHumanHolding ? "hand.raised.fill" : "iphone.gen3",
                    label: viewModel.isHumanHolding ? "In hand" : "On surface",
                    isPausing: viewModel.isMonitoring && viewModel.detectDeviceOnTable && !viewModel.isHumanHolding
                )
                ContextChip(
                    icon: viewModel.isScreenLocked ? "lock.fill" : "lock.open.fill",
                    label: viewModel.isScreenLocked ? "Locked" : "Unlocked",
                    isPausing: viewModel.isMonitoring && viewModel.isScreenLocked
                )
                ContextChip(
                    icon: "bag.fill",
                    label: viewModel.isInPocket ? "In pocket" : "Not pocketed",
                    isPausing: viewModel.isMonitoring && viewModel.isInPocket
                )
            }
            .opacity(viewModel.isMonitoring ? 1 : 0.5)

            Text("Alerts pause automatically when your phone is pocketed, locked, or resting on a table.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    // MARK: Today summary

    private var todayCard: some View {
        Button(action: onOpenInsights) {
            HStack(spacing: Theme.Spacing.md) {
                ScoreRing(score: viewModel.today.score, size: 56, lineWidth: 6)
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text("Today")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.text)
                    Text(todaySummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private var todaySummary: String {
        let minutes = Int(viewModel.today.monitoredSeconds / 60)
        guard minutes > 0 else { return "No tracked time yet" }
        let nudges = viewModel.today.alerts
        return "\(formatMinutes(minutes)) tracked · \(nudges) nudge\(nudges == 1 ? "" : "s")"
    }
}

// MARK: - Shared pieces

func scoreTint(_ score: Int) -> Color {
    switch score {
    case 80...: return Theme.Colors.good
    case 60..<80: return Theme.Colors.warning
    default: return Theme.Colors.alert
    }
}

func formatMinutes(_ minutes: Int) -> String {
    minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
}

struct StatColumn: View {
    let value: String
    let label: String
    var tint: Color? = nil

    var body: some View {
        VStack(spacing: Theme.Spacing.xxs) {
            Text(value)
                .font(Theme.Typography.metric)
                .foregroundStyle(tint ?? Theme.Colors.text)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ScoreRing: View {
    let score: Int?
    var size: CGFloat = 64
    var lineWidth: CGFloat = 7

    var body: some View {
        ZStack {
            Circle().stroke(Theme.Colors.neutral.opacity(0.15), lineWidth: lineWidth)
            if let score {
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(scoreTint(score), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Text(score.map { "\($0)" } ?? "—")
                .font(.system(size: size * 0.3, weight: .semibold, design: .rounded).monospacedDigit())
        }
        .frame(width: size, height: size)
        .accessibilityLabel(score.map { "Score \($0) percent" } ?? "No score yet")
    }
}

private struct ContextChip: View {
    let icon: String
    let label: String
    let isPausing: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isPausing ? Theme.Colors.warning : Theme.Colors.brand)
                .frame(height: 22)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(isPausing ? Theme.Colors.warning : Theme.Colors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm + 2)
        .background(
            (isPausing ? Theme.Colors.warning.opacity(0.12) : Theme.Colors.surfaceRaised),
            in: RoundedRectangle(cornerRadius: Theme.CornerRadius.sm, style: .continuous)
        )
        .animation(.easeInOut(duration: 0.2), value: isPausing)
    }
}

private struct LiveBadge: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Theme.Colors.alert)
                .frame(width: 6, height: 6)
                .opacity(pulse ? 0.3 : 1)
            Text("LIVE")
                .font(Theme.Typography.overline)
                .tracking(0.8)
        }
        .foregroundStyle(Theme.Colors.alert)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever()) { pulse = true }
        }
    }
}

struct NoticeCard: View {
    let icon: String
    let tint: Color
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            IconBadge(systemName: icon, tint: tint)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .tint(tint)
            }
        }
        .cardStyle()
    }
}
