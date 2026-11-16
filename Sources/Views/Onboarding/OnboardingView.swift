import SwiftUI

/// First-run flow: welcome → how it works → notifications → calibration.
struct OnboardingView: View {
    @EnvironmentObject private var viewModel: PostureViewModel
    let onComplete: () -> Void

    @State private var step: Step = .welcome

    private enum Step: Int, CaseIterable {
        case welcome, howItWorks, notifications, calibrate
    }

    var body: some View {
        VStack(spacing: 0) {
            if step != .welcome {
                progressBar
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.sm)
                    .transition(.opacity)
            }

            Group {
                switch step {
                case .welcome: welcome
                case .howItWorks: howItWorks
                case .notifications: notifications
                case .calibrate:
                    CalibrationView(mode: .onboarding, onFinish: onComplete)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .background(Theme.Colors.background.ignoresSafeArea())
    }

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return onComplete() }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) { step = next }
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(Step.allCases.dropFirst(), id: \.self) { item in
                Capsule()
                    .fill(item.rawValue <= step.rawValue ? Theme.Colors.brand : Theme.Colors.neutral.opacity(0.25))
                    .frame(height: 4)
            }
        }
        .frame(maxWidth: 520)
        .animation(.easeInOut, value: step)
    }

    // MARK: Welcome

    private var welcome: some View {
        OnboardingPage {
            ZStack {
                Circle()
                    .fill(Theme.Colors.brandSoft)
                    .frame(width: 200, height: 200)
                Circle()
                    .stroke(Theme.Colors.brand.opacity(0.25), lineWidth: 1)
                    .frame(width: 250, height: 250)
                Image(systemName: "figure.stand")
                    .font(.system(size: 96))
                    .foregroundStyle(Theme.Colors.brand)
            }
        } text: {
            Text("Posture Help")
                .font(Theme.Typography.overline)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Colors.brand)
            Text("Stand taller,\nwithout thinking about it")
                .font(Theme.Typography.largeTitle)
                .multilineTextAlignment(.center)
            Text("A gentle nudge whenever you start hunching over your phone.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        } footer: {
            Button("Get Started", action: advance)
                .buttonStyle(.primary)
        }
    }

    // MARK: How it works

    private var howItWorks: some View {
        OnboardingPage {
            EmptyView()
        } text: {
            Text("How it works")
                .font(Theme.Typography.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                FeatureRow(icon: "scope", title: "Calibrate once", detail: "Show us your upright posture so we know your baseline.")
                FeatureRow(icon: "waveform.path.ecg", title: "Monitors quietly", detail: "Motion sensors track the tilt of your phone while you use it.")
                FeatureRow(icon: "bell.badge.fill", title: "Nudges when it matters", detail: "A haptic and notification after you lean too far for too long.")
                FeatureRow(icon: "lock.shield.fill", title: "Private by design", detail: "Everything is processed and stored on your device.")
            }
            .padding(.top, Theme.Spacing.md)
        } footer: {
            Button("Continue", action: advance)
                .buttonStyle(.primary)
        }
    }

    // MARK: Notifications

    private var notifications: some View {
        OnboardingPage {
            NotificationPreview()
                .padding(.horizontal, Theme.Spacing.md)
        } text: {
            Text("Stay on track in any app")
                .font(Theme.Typography.largeTitle)
                .multilineTextAlignment(.center)
            Text("Allow notifications so reminders reach you while you're scrolling, reading, or watching.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        } footer: {
            Button("Allow Notifications") {
                Task {
                    await viewModel.requestNotifications()
                    advance()
                }
            }
            .buttonStyle(.primary)
            Button("Not now", action: advance)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.top, Theme.Spacing.sm)
        }
    }
}

// MARK: - Building blocks

private struct OnboardingPage<Visual: View, TextContent: View, Footer: View>: View {
    @ViewBuilder let visual: Visual
    @ViewBuilder let text: TextContent
    @ViewBuilder let footer: Footer

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Theme.Spacing.lg)
            visual
            VStack(spacing: Theme.Spacing.md) { text }
                .padding(.top, Theme.Spacing.xl)
            Spacer(minLength: Theme.Spacing.lg)
            VStack(spacing: 0) { footer }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.lg)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            IconBadge(systemName: icon, size: 44)
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Mock of a lock-screen notification so people know what they're agreeing to.
private struct NotificationPreview: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            row(title: "Time to straighten up", body: "You've been leaning forward for a bit. Lift your screen to eye level.", time: "now")
            row(title: "Nice reset", body: "Shoulders back, chin up. Keep it going!", time: "12m ago")
                .scaleEffect(0.94)
                .opacity(0.6)
        }
    }

    private func row(title: String, body: String, time: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm + 2) {
            Image(systemName: "figure.stand")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Theme.Colors.brand, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title).font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(time).font(.caption).foregroundStyle(.secondary)
                }
                Text(body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(Theme.Spacing.md - 2)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}
