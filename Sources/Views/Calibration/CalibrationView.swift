import SwiftUI

/// Guided calibration: instructions → 3‑2‑1 countdown → capture → confirmation.
struct CalibrationView: View {
    enum Mode { case sheet, onboarding }

    @EnvironmentObject private var viewModel: PostureViewModel
    let mode: Mode
    let onFinish: () -> Void

    @State private var phase: Phase = .instructions
    @State private var countdown = 3
    @State private var task: Task<Void, Never>?

    private enum Phase { case instructions, countdown, capturing, done }

    var body: some View {
        VStack(spacing: 0) {
            if mode == .sheet {
                HStack {
                    Spacer()
                    Button("Cancel") { task?.cancel(); onFinish() }
                        .opacity(phase == .done ? 0 : 1)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
            }

            Spacer(minLength: Theme.Spacing.lg)

            visual
                .frame(width: 220, height: 220)

            VStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(Theme.Typography.largeTitle)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.xl)

            if phase == .instructions {
                checklist
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .transition(.opacity)
            }

            Spacer(minLength: Theme.Spacing.lg)

            footer
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.lg)
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.3), value: phase)
        .sensoryFeedback(.impact(weight: .light), trigger: countdown)
        .sensoryFeedback(.success, trigger: phase == .done)
        .onDisappear { task?.cancel() }
    }

    // MARK: Content

    private var title: String {
        switch phase {
        case .instructions: return "Find your upright"
        case .countdown: return "Hold still"
        case .capturing: return "Measuring…"
        case .done: return "You're calibrated"
        }
    }

    private var message: String {
        switch phase {
        case .instructions:
            return "We'll remember the angle you hold your phone at when you're sitting well."
        case .countdown, .capturing:
            return "Keep your back straight and your phone where you normally read it."
        case .done:
            return "We'll compare every lean against this posture. Recalibrate anytime in Settings."
        }
    }

    @ViewBuilder
    private var visual: some View {
        ZStack {
            Circle()
                .fill(Theme.Colors.brandSoft)
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(Theme.Colors.brand, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(4)
                .animation(.linear(duration: 1), value: ringProgress)

            switch phase {
            case .instructions:
                Image(systemName: "figure.stand")
                    .font(.system(size: 88, weight: .regular))
                    .foregroundStyle(Theme.Colors.brand)
            case .countdown:
                Text("\(countdown)")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.brand)
                    .contentTransition(.numericText(countsDown: true))
            case .capturing:
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.Colors.brand)
            case .done:
                Image(systemName: "checkmark")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundStyle(Theme.Colors.brand)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var ringProgress: CGFloat {
        switch phase {
        case .instructions: return 0
        case .countdown: return CGFloat(3 - countdown) / 3
        case .capturing, .done: return 1
        }
    }

    private var checklist: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            ChecklistRow(icon: "chair.fill", text: "Sit back with your shoulders relaxed")
            ChecklistRow(icon: "iphone.gen3", text: "Hold your phone at a comfortable reading height")
            ChecklistRow(icon: "hand.raised.fill", text: "Stay still for about 4 seconds")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    @ViewBuilder
    private var footer: some View {
        switch phase {
        case .instructions:
            Button("Start Calibration", action: begin)
                .buttonStyle(.primary)
            if mode == .onboarding {
                Button("Skip for now", action: onFinish)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, Theme.Spacing.sm)
            }
        case .countdown, .capturing:
            Button("Calibrating…") {}
                .buttonStyle(.primary)
                .disabled(true)
        case .done:
            Button(mode == .onboarding ? "Get Started" : "Done", action: onFinish)
                .buttonStyle(.primary)
        }
    }

    // MARK: Flow

    private func begin() {
        countdown = 3
        phase = .countdown
        task = Task { @MainActor in
            for value in stride(from: 2, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                if value == 0 { break }
                withAnimation { countdown = value }
            }
            phase = .capturing
            viewModel.calibrateBaseline()
            try? await Task.sleep(for: .seconds(1.3))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { phase = .done }
        }
    }
}

private struct ChecklistRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.brand)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}
