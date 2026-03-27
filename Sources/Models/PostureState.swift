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
}
