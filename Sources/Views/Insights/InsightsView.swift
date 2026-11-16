import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject private var viewModel: PostureViewModel

    private var days: [DailyPostureRecord] { viewModel.recentDays }
    private var trackedDays: [DailyPostureRecord] { days.filter { $0.score != nil } }

    private var weeklyScore: Int? {
        let monitored = days.reduce(0) { $0 + $1.monitoredSeconds }
        guard monitored >= 30 else { return nil }
        let good = days.reduce(0) { $0 + $1.goodSeconds }
        return Int((good / monitored * 100).rounded())
    }

    private var weeklyMinutes: Int { Int(days.reduce(0) { $0 + $1.monitoredSeconds } / 60) }
    private var weeklyNudges: Int { days.reduce(0) { $0 + $1.alerts } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    summaryCard
                    chartCard
                    statsGrid
                    tipsSection
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.lg)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Insights")
            .onAppear { viewModel.refreshHistory() }
        }
    }

    // MARK: Summary

    private var summaryCard: some View {
        HStack(spacing: Theme.Spacing.lg) {
            ScoreRing(score: weeklyScore, size: 92, lineWidth: 9)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("PAST 7 DAYS")
                    .font(Theme.Typography.overline)
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
                Text(summaryHeadline)
                    .font(Theme.Typography.title3)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Share of tracked time spent upright.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle(padding: Theme.Spacing.lg)
    }

    private var summaryHeadline: String {
        guard let score = weeklyScore else { return "Start a session to see your trends" }
        switch score {
        case 85...: return "Excellent posture week"
        case 70..<85: return "Solid, keep it up"
        case 50..<70: return "Room to improve"
        default: return "Let's build the habit"
        }
    }

    // MARK: Chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Daily upright score")
                    .font(Theme.Typography.headline)
                Spacer()
                Text("Goal 70%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Chart {
                ForEach(days) { day in
                    BarMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value("Score", day.score ?? 0),
                        width: .ratio(0.55)
                    )
                    .foregroundStyle(day.score.map(scoreTint) ?? Theme.Colors.neutral.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                RuleMark(y: .value("Goal", 70))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Theme.Colors.neutral.opacity(0.6))
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { value in
                    AxisGridLine().foregroundStyle(Theme.Colors.separator.opacity(0.5))
                    AxisValueLabel { Text("\(value.as(Int.self) ?? 0)") }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                }
            }
            .frame(height: 180)
            .overlay {
                if trackedDays.isEmpty {
                    Text("No data yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .cardStyle()
    }

    // MARK: Stats

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.md), GridItem(.flexible())], spacing: Theme.Spacing.md) {
            InsightTile(icon: "flame.fill", tint: Theme.Colors.warning, value: "\(viewModel.streak)", label: "day streak")
            InsightTile(icon: "clock.fill", tint: Theme.Colors.brand, value: formatMinutes(weeklyMinutes), label: "tracked this week")
            InsightTile(icon: "bell.fill", tint: Theme.Colors.alert, value: "\(weeklyNudges)", label: "nudges this week")
            InsightTile(icon: "calendar", tint: Theme.Colors.good, value: "\(trackedDays.count)/7", label: "active days")
        }
    }

    // MARK: Tips

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Habits that help")
                .padding(.top, Theme.Spacing.sm)
            VStack(spacing: 0) {
                TipRow(icon: "iphone.gen3", title: "Raise the screen", detail: "Bring your phone up toward eye level instead of dropping your head.")
                Divider().padding(.leading, 60)
                TipRow(icon: "figure.cooldown", title: "Reset every 30 minutes", detail: "Roll your shoulders back and stretch your neck gently.")
                Divider().padding(.leading, 60)
                TipRow(icon: "eye", title: "20-20-20", detail: "Every 20 minutes, look at something 20 feet away for 20 seconds.")
            }
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.lg, style: .continuous))
        }
    }
}

private struct InsightTile: View {
    let icon: String
    let tint: Color
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(Theme.Typography.metric)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }
}

private struct TipRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            IconBadge(systemName: icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
    }
}
