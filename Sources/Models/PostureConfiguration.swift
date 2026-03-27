import Foundation

struct PostureConfiguration {
    var forwardLeanThresholdDegrees: Double = 12
    var sustainedSeconds: Double = 8
    var reminderIntervalSeconds: Double = 20
    
    var isValid: Bool {
        forwardLeanThresholdDegrees >= 6 && forwardLeanThresholdDegrees <= 24 &&
        sustainedSeconds >= 3 && sustainedSeconds <= 20 &&
        reminderIntervalSeconds >= 8 && reminderIntervalSeconds <= 120
    }
}
