import Foundation

/// Aggregated posture totals for a single calendar day.
struct DailyPostureRecord: Codable, Identifiable, Equatable {
    var day: Date                // start of day
    var monitoredSeconds: Double = 0
    var goodSeconds: Double = 0
    var alerts: Int = 0

    var id: Date { day }

    /// 0...100, or nil when nothing was tracked that day.
    var score: Int? {
        guard monitoredSeconds >= 30 else { return nil }
        return Int((goodSeconds / monitoredSeconds * 100).rounded())
    }
}

/// Lightweight on-device history. Kept in UserDefaults because the data set is tiny
/// (one record per day, trimmed to the last ~90 days) and never leaves the device.
final class PostureHistoryStore {
    static let shared = PostureHistoryStore()

    private let defaults: UserDefaults
    private let key = "posture.history.v1"
    private let retentionDays = 90
    private let calendar = Calendar.current

    private(set) var records: [DailyPostureRecord] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func record(for date: Date = Date()) -> DailyPostureRecord {
        let day = calendar.startOfDay(for: date)
        return records.first { $0.day == day } ?? DailyPostureRecord(day: day)
    }

    /// The last `count` days, oldest first, including empty days.
    func lastDays(_ count: Int, endingAt end: Date = Date()) -> [DailyPostureRecord] {
        let endDay = calendar.startOfDay(for: end)
        return (0..<count).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: endDay).map { record(for: $0) }
        }
    }

    /// Consecutive days (ending today or yesterday) with a score of 70 or more.
    var currentStreak: Int {
        var streak = 0
        var date = calendar.startOfDay(for: Date())
        if (record(for: date).score ?? 0) < 70 {
            date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        }
        while let score = record(for: date).score, score >= 70 {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }
        return streak
    }

    func add(monitored: Double, good: Double, alerts: Int, on date: Date = Date()) {
        guard monitored > 0 || alerts > 0 else { return }
        var current = record(for: date)
        current.monitoredSeconds += monitored
        current.goodSeconds += good
        current.alerts += alerts
        records.removeAll { $0.day == current.day }
        records.append(current)
        records.sort { $0.day < $1.day }
        trim()
        save()
    }

    #if DEBUG
    /// Fills the last week with plausible, improving history for screenshots.
    func seedDemoData() {
        let samples: [(minutes: Double, score: Double, alerts: Int)] = [
            (38, 0.66, 9), (52, 0.71, 7), (44, 0.74, 6), (61, 0.79, 5), (57, 0.83, 4), (66, 0.86, 3), (49, 0.88, 2)
        ]
        records = []
        for (offset, sample) in samples.enumerated() {
            guard let day = calendar.date(byAdding: .day, value: offset - (samples.count - 1), to: calendar.startOfDay(for: Date())) else { continue }
            let monitored = sample.minutes * 60
            records.append(DailyPostureRecord(day: day, monitoredSeconds: monitored, goodSeconds: monitored * sample.score, alerts: sample.alerts))
        }
        save()
    }
    #endif

    func reset() {
        records = []
        defaults.removeObject(forKey: key)
    }

    private func trim() {
        guard let cutoff = calendar.date(byAdding: .day, value: -retentionDays, to: Date()) else { return }
        records.removeAll { $0.day < cutoff }
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([DailyPostureRecord].self, from: data) else { return }
        records = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: key)
    }
}
