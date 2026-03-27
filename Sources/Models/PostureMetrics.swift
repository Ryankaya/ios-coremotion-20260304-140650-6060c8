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
}
