import WidgetKit
import SwiftUI

@main
struct PostureWidgetsBundle: WidgetBundle {
    var body: some Widget {
        MonitoringToggleWidget()
        PostureControlsWidget()
        PostureDashboardWidget()
        LockScreenToggleWidget()
        LockScreenStatusWidget()
        if #available(iOS 18.0, *) {
            MonitoringControl()
            CalibrateControl()
        }
    }
}
