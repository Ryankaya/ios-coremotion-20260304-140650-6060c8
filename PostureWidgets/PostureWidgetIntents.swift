import AppIntents
import WidgetKit

private func reloadWidgets() {
    WidgetCenter.shared.reloadAllTimelines()
    if #available(iOS 18.0, *) {
        ControlCenter.shared.reloadAllControls()
    }
}

struct SetMonitoringIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Posture Session"

    @Parameter(title: "Session Active")
    var value: Bool

    init() {}

    init(value: Bool) {
        self.value = value
    }

    func perform() async throws -> some IntentResult {
        SharedPostureStore.update { $0.isMonitoring = value }
        reloadWidgets()
        return .result()
    }
}

/// Used by the Control Center / Lock Screen control only. AppIntents run in the widget
/// extension process - which can't be foregrounded via `openAppWhenRun` (Apple docs: that
/// generates a runtime error for intents running in an app extension) - so this stays
/// background-only. The Home Screen widget's Calibrate button instead uses a `Link` deep link
/// (posturehelp://calibrate) to actually open the app and run calibration live.
struct CalibratePostureIntent: AppIntent {
    static let title: LocalizedStringResource = "Calibrate Posture"

    func perform() async throws -> some IntentResult {
        SharedPostureStore.update {
            $0.pendingCalibrate = true
            $0.isBaselineSet = true
        }
        reloadWidgets()
        return .result()
    }
}

struct SetSmartAlertsIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Only While Interacting"

    @Parameter(title: "Only While Interacting")
    var value: Bool

    init() {}

    init(value: Bool) {
        self.value = value
    }

    func perform() async throws -> some IntentResult {
        SharedPostureStore.update { $0.onlyAlertWhenActive = value }
        reloadWidgets()
        return .result()
    }
}

struct SetDetectTableIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Pause on a Table"

    @Parameter(title: "Pause on a Table")
    var value: Bool

    init() {}

    init(value: Bool) {
        self.value = value
    }

    func perform() async throws -> some IntentResult {
        SharedPostureStore.update { $0.detectDeviceOnTable = value }
        reloadWidgets()
        return .result()
    }
}

struct SetPortraitOnlyIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Portrait Only"

    @Parameter(title: "Portrait Only")
    var value: Bool

    init() {}

    init(value: Bool) {
        self.value = value
    }

    func perform() async throws -> some IntentResult {
        SharedPostureStore.update { $0.onlyAlertInPortrait = value }
        reloadWidgets()
        return .result()
    }
}
