import Foundation

struct SharedPostureSnapshot: Codable {
    var isMonitoring: Bool = false
    var postureStateRaw: String = "unknown"
    var statusMessage: String = "Sit upright and tap Start Monitoring to begin"
    var isBaselineSet: Bool = false
    var leanDegrees: Double = 0
    var onlyAlertWhenActive: Bool = false
    var detectDeviceOnTable: Bool = true
    /// Whether the phone is actually detected as resting on a surface right now (not just
    /// whether the setting is enabled). Lets widgets show a distinct "On Table" state instead
    /// of a possibly-stale good/lean/alert icon while no real alert can fire.
    var isDeviceOnTable: Bool = false
    var onlyAlertInPortrait: Bool = false
    var pendingCalibrate: Bool = false
    /// Today's share of tracked time spent upright (0-100), nil until enough data exists.
    /// Optional so snapshots saved by older builds still decode.
    var todayScore: Int? = nil
    var todayMinutes: Int? = nil
    /// The user's forward-lean threshold in degrees, for drawing the widget gauge.
    var leanThreshold: Double? = nil
    var updatedAt: Date = .distantPast
}

enum SharedPostureStore {
    static let suiteName = "group.com.ryankaya.ioscoremotiondemo"
    private static let snapshotKey = "posture.snapshot"
    /// Darwin notification posted whenever a widget/Control Center intent changes the snapshot,
    /// so the main app (if alive in the background) can react immediately instead of waiting for
    /// the next foreground event or background task wake - both too slow to stop live sensing.
    static let didChangeNotificationName = "com.ryankaya.ioscoremotiondemo.posture.didChange" as CFString

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func postChangeNotification() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(didChangeNotificationName),
            nil, nil, true
        )
    }

    static func load() -> SharedPostureSnapshot {
        guard let data = defaults?.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(SharedPostureSnapshot.self, from: data) else {
            return SharedPostureSnapshot()
        }
        return snapshot
    }

    static func save(_ snapshot: SharedPostureSnapshot) {
        var snapshot = snapshot
        snapshot.updatedAt = Date()
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: snapshotKey)
    }

    @discardableResult
    static func update(_ mutate: (inout SharedPostureSnapshot) -> Void) -> SharedPostureSnapshot {
        var snapshot = load()
        mutate(&snapshot)
        save(snapshot)
        postChangeNotification()
        return snapshot
    }
}
