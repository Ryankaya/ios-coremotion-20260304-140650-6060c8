import SwiftUI
import WidgetKit

enum WidgetPostureState: Equatable {
    case stopped
    case unknown
    case good
    case warning
    case alert
    case onTable

    static func decode(_ stored: String) -> WidgetPostureState {
        switch stored {
        case "good": return .good
        case "warning": return .warning
        case "alert": return .alert
        default: return .unknown
        }
    }

    /// Headline copy, matching the app's Today screen.
    var displayText: String {
        switch self {
        case .stopped: return "Ready when you are"
        case .unknown: return "Getting a reading"
        case .good: return "Looking good"
        case .warning: return "Leaning forward"
        case .alert: return "Sit up straight"
        case .onTable: return "Alerts paused"
        }
    }

    /// Very short label for tight spaces (inline lock screen, small widget).
    var shortText: String {
        switch self {
        case .stopped: return "Not tracking"
        case .unknown: return "Starting"
        case .good: return "Upright"
        case .warning: return "Leaning"
        case .alert: return "Sit up"
        case .onTable: return "Paused"
        }
    }

    var subtitleText: String {
        switch self {
        case .stopped: return "Start a session to get nudges"
        case .unknown: return "Hold your phone as usual"
        case .good: return "Keep it up"
        case .warning: return "Lift your phone a little"
        case .alert: return "Raise your screen to eye level"
        case .onTable: return "Phone is resting on a surface"
        }
    }

    var symbolName: String {
        switch self {
        case .stopped: return "figure.stand"
        case .unknown: return "waveform"
        case .good: return "checkmark"
        case .warning: return "exclamationmark"
        case .alert: return "arrow.up"
        case .onTable: return "pause.fill"
        }
    }

    var tint: Color {
        switch self {
        case .stopped: return WidgetTheme.brand
        case .unknown, .onTable: return WidgetTheme.neutral
        case .good: return WidgetTheme.good
        case .warning: return WidgetTheme.warning
        case .alert: return WidgetTheme.alert
        }
    }
}

struct PostureWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedPostureSnapshot

    /// The device being flat and still on a table means no alert can actually fire, so that
    /// takes priority over whatever good/lean/alert angle was last measured - otherwise the
    /// widget can be left showing a stale alert icon from right before the phone was set down.
    var postureState: WidgetPostureState {
        guard snapshot.isMonitoring else {
            return .stopped
        }
        if snapshot.isDeviceOnTable {
            return .onTable
        }
        return WidgetPostureState.decode(snapshot.postureStateRaw)
    }

    /// Forward lean in degrees (the snapshot stores a signed delta; negative = forward).
    var forwardLean: Double { max(0, -snapshot.leanDegrees) }
    var threshold: Double { snapshot.leanThreshold ?? 12 }

    var todaySummary: String {
        guard let minutes = snapshot.todayMinutes, minutes > 0 else { return "No time tracked yet" }
        let time = minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
        return "\(time) tracked today"
    }
}

extension PostureWidgetEntry {
    static func sample(_ state: String = "good", monitoring: Bool = true, lean: Double = -7, onTable: Bool = false) -> PostureWidgetEntry {
        var snapshot = SharedPostureSnapshot()
        snapshot.isMonitoring = monitoring
        snapshot.postureStateRaw = state
        snapshot.leanDegrees = lean
        snapshot.isBaselineSet = true
        snapshot.isDeviceOnTable = onTable
        snapshot.todayScore = 86
        snapshot.todayMinutes = 74
        snapshot.leanThreshold = 12
        return PostureWidgetEntry(date: .now, snapshot: snapshot)
    }
}

struct PostureTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PostureWidgetEntry {
        .sample()
    }

    func getSnapshot(in context: Context, completion: @escaping (PostureWidgetEntry) -> Void) {
        // The widget gallery shows a representative live state instead of an empty one.
        completion(context.isPreview ? .sample() : PostureWidgetEntry(date: Date(), snapshot: SharedPostureStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PostureWidgetEntry>) -> Void) {
        let entry = PostureWidgetEntry(date: Date(), snapshot: SharedPostureStore.load())
        completion(Timeline(entries: [entry], policy: .never))
    }
}
