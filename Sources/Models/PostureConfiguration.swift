import Foundation

struct PostureConfiguration: Codable, Equatable {
    var forwardLeanThresholdDegrees: Double = 12
    var sustainedSeconds: Double = 8
    var reminderIntervalSeconds: Double = 20

    var isValid: Bool {
        forwardLeanThresholdDegrees >= 6 && forwardLeanThresholdDegrees <= 24 &&
        sustainedSeconds >= 3 && sustainedSeconds <= 20 &&
        reminderIntervalSeconds >= 8 && reminderIntervalSeconds <= 120
    }

    /// The preset these values match exactly, or `nil` when the user has tuned them by hand.
    var preset: SensitivityPreset? {
        SensitivityPreset.allCases.first { $0.matches(self) }
    }

    mutating func apply(_ preset: SensitivityPreset) {
        forwardLeanThresholdDegrees = preset.threshold
        sustainedSeconds = preset.sustain
    }
}

enum SensitivityPreset: String, CaseIterable, Identifiable {
    case relaxed, balanced, strict

    var id: String { rawValue }

    var title: String {
        switch self {
        case .relaxed: return "Relaxed"
        case .balanced: return "Balanced"
        case .strict: return "Strict"
        }
    }

    var summary: String {
        switch self {
        case .relaxed: return "Nudges after a long, deep slouch. Fewer interruptions."
        case .balanced: return "Recommended for most people."
        case .strict: return "Catches small leans quickly. Best for building the habit."
        }
    }

    var threshold: Double {
        switch self {
        case .relaxed: return 18
        case .balanced: return 12
        case .strict: return 8
        }
    }

    var sustain: Double {
        switch self {
        case .relaxed: return 14
        case .balanced: return 8
        case .strict: return 4
        }
    }

    func matches(_ configuration: PostureConfiguration) -> Bool {
        configuration.forwardLeanThresholdDegrees == threshold && configuration.sustainedSeconds == sustain
    }
}
