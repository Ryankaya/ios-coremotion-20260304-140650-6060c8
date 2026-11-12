import Foundation

struct PostureMetrics {
    var currentPitch: Double = 0
    var baselinePitch: Double = 0
    var leanDeltaDegrees: Double = 0
    var lastAlertDate: Date?
    var postureState: PostureState = .unknown
    
    var isBaselineSet: Bool {
        baselinePitch != 0
    }
    
    /// Which haptic pattern, if any, corresponds to the current posture state.
    var hapticPattern: HapticPattern {
        switch postureState {
        case .unknown, .good:
            return .none
        case .warning:
            return .warning
        case .alert:
            return .alert
        }
    }
}

enum HapticPattern {
    case none
    case warning
    case alert
}
