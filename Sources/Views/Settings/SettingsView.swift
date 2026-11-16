import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var viewModel: PostureViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showAdvanced = false
    @State private var confirmReset = false
    let onCalibrate: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                sensitivitySection
                smartPauseSection
                notificationsSection
                calibrationSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .onAppear { showAdvanced = viewModel.configuration.preset == nil }
            .confirmationDialog("Reset all posture history?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset History", role: .destructive) { viewModel.resetHistory() }
            } message: {
                Text("Your daily scores and streak will be permanently deleted.")
            }
        }
    }

    // MARK: Sensitivity

    private var presetBinding: Binding<SensitivityPreset?> {
        Binding(
            get: { viewModel.configuration.preset },
            set: { preset in
                guard let preset else { return }
                withAnimation { viewModel.configuration.apply(preset) }
            }
        )
    }

    private var sensitivitySection: some View {
        Section {
            Picker("Sensitivity", selection: presetBinding) {
                ForEach(SensitivityPreset.allCases) { preset in
                    Text(preset.title).tag(Optional(preset))
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: Theme.Spacing.sm, trailing: 0))
            .listRowSeparator(.hidden)

            DisclosureGroup("Fine-tune", isExpanded: $showAdvanced) {
                SliderRow(
                    title: "Lean threshold",
                    value: $viewModel.configuration.forwardLeanThresholdDegrees,
                    range: 6...24, unit: "°"
                )
                SliderRow(
                    title: "Hold before nudge",
                    value: $viewModel.configuration.sustainedSeconds,
                    range: 3...20, unit: "s"
                )
                SliderRow(
                    title: "Repeat reminders every",
                    value: $viewModel.configuration.reminderIntervalSeconds,
                    range: 8...120, unit: "s"
                )
            }
        } header: {
            Text("Sensitivity")
        } footer: {
            Text(viewModel.configuration.preset?.summary ?? "Custom settings.")
        }
    }

    // MARK: Smart pause

    private var smartPauseSection: some View {
        Section {
            ToggleRow(
                icon: "iphone.gen3", tint: .purple,
                title: "Pause on a table",
                subtitle: "Skip alerts while the phone is resting still.",
                isOn: $viewModel.detectDeviceOnTable
            )
            ToggleRow(
                icon: "hand.tap.fill", tint: .blue,
                title: "Only while interacting",
                subtitle: "Skip alerts when you aren't touching the screen.",
                isOn: $viewModel.onlyAlertWhenActive
            )
            ToggleRow(
                icon: "rectangle.portrait.rotate", tint: .indigo,
                title: "Portrait only",
                subtitle: "Skip alerts in landscape, e.g. while watching video.",
                isOn: $viewModel.onlyAlertInPortrait
            )
        } header: {
            Text("Smart pause")
        } footer: {
            Text("Alerts always pause while the phone is locked or in a pocket.")
        }
    }

    // MARK: Notifications

    private var notificationsSection: some View {
        Section("Notifications") {
            HStack {
                Label {
                    Text("Posture reminders")
                } icon: {
                    IconBadge(systemName: "bell.badge.fill", tint: .red, size: 28)
                }
                Spacer()
                Text(viewModel.notificationsEnabled ? "On" : "Off")
                    .foregroundStyle(.secondary)
            }
            if !viewModel.notificationsEnabled {
                Button("Turn On Notifications") {
                    Task {
                        await viewModel.requestNotifications()
                        if !viewModel.notificationsEnabled { openSystemSettings() }
                    }
                }
            }
        }
    }

    // MARK: Calibration

    private var calibrationSection: some View {
        Section {
            Button(action: onCalibrate) {
                Label {
                    Text("Recalibrate upright posture")
                        .foregroundStyle(viewModel.isMonitoring ? .secondary : Theme.Colors.text)
                } icon: {
                    IconBadge(systemName: "scope", tint: Theme.Colors.brand, size: 28)
                }
            }
            .disabled(viewModel.isMonitoring)
        } header: {
            Text("Calibration")
        } footer: {
            Text(viewModel.isMonitoring
                 ? "End your session to recalibrate."
                 : "Recalibrate if you change how you usually hold your phone.")
        }
    }

    // MARK: Data & About

    private var dataSection: some View {
        Section {
            Button("Reset History", role: .destructive) { confirmReset = true }
        } header: {
            Text("Data")
        } footer: {
            Text("All posture data stays on this device.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: appVersion)
            Button("Show Welcome Tour") {
                withAnimation { hasCompletedOnboarding = false }
            }
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct ToggleRow: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: Theme.Spacing.md) {
                IconBadge(systemName: icon, tint: tint, size: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(Theme.Colors.brand)
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value))\(unit)")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: 1)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}
