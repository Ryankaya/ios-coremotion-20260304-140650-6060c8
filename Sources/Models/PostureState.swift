import Foundation

enum PostureState: Equatable {
    case unknown
    case good
    case warning
    case alert
    
    var displayText: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .good:
            return "Good Posture"
        case .warning:
            return "Lean Detected"
        case .alert:
            return "Poor Posture"
        }
    }
    
    var statusEmoji: String {
        switch self {
        case .unknown:
            return "⚪️"
        case .good:
            return "✅"
        case .warning:
            return "⚠️"
        case .alert:
            return "🔴"
        }
    }

    /// Stable string form stored in the App Group snapshot read by widgets.
    var widgetRawValue: String {
        switch self {
        case .unknown: return "unknown"
        case .good: return "good"
        case .warning: return "warning"
        case .alert: return "alert"
        }
    }
}
