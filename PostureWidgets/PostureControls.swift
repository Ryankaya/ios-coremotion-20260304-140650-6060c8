import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct MonitoringValueProvider: ControlValueProvider {
    var previewValue: Bool { false }

    func currentValue() async -> Bool {
        SharedPostureStore.load().isMonitoring
    }
}

@available(iOS 18.0, *)
struct MonitoringControl: ControlWidget {
    static let kind = "com.ryankaya.ioscoremotiondemo.MonitoringControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind, provider: MonitoringValueProvider()) { isOn in
            ControlWidgetToggle(
                "Posture Session",
                isOn: isOn,
                action: SetMonitoringIntent(value: !isOn)
            ) { value in
                Label(value ? "Tracking" : "Off", systemImage: "figure.stand")
            }
            .tint(WidgetTheme.brand)
        }
        .displayName("Posture Session")
        .description("Start or end a posture session.")
    }
}

@available(iOS 18.0, *)
struct CalibrateControl: ControlWidget {
    static let kind = "com.ryankaya.ioscoremotiondemo.CalibrateControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: CalibratePostureIntent()) {
                Label("Calibrate", systemImage: "scope")
            }
            .tint(WidgetTheme.brand)
        }
        .displayName("Calibrate Posture")
        .description("Set your upright posture as the new baseline.")
    }
}
