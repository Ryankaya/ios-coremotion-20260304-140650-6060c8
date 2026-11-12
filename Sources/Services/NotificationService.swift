import UserNotifications
import Foundation
import FoundationModels

protocol NotificationServiceProtocol {
    var isAuthorized: Bool { get }
    func requestAuthorization() async -> Bool
    func sendPostureAlert(leanDegrees: Double, sustainedSeconds: Double, repeatCount: Int)
}

final class NotificationService: NotificationServiceProtocol {
    @Published private(set) var isAuthorized: Bool = false

    private static let tones = ["encouraging", "playful", "direct", "caring", "matter-of-fact"]

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            return false
        }
    }

    func sendPostureAlert(leanDegrees: Double, sustainedSeconds: Double, repeatCount: Int) {
        guard isAuthorized else { return }

        Task {
            let message = await Self.generateMessage(
                leanDegrees: leanDegrees,
                sustainedSeconds: sustainedSeconds,
                repeatCount: repeatCount
            )

            let content = UNMutableNotificationContent()
            content.title = message.title
            content.body = message.body
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )

            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    /// Asks the on-device Apple Intelligence model for fresh wording every time, so repeated
    /// reminders during a long slouch session don't all read the same. Falls back to a fixed
    /// string when the model is unavailable (older OS, unsupported device, Apple Intelligence off).
    private static func generateMessage(
        leanDegrees: Double,
        sustainedSeconds: Double,
        repeatCount: Int
    ) async -> (title: String, body: String) {
        let fallback = (
            title: "Posture Check",
            body: "Forward lean is \(Int(abs(leanDegrees)))°. Sit upright and relax your shoulders."
        )

        guard #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable else {
            return fallback
        }

        let tone = tones.randomElement() ?? "encouraging"
        let session = LanguageModelSession(instructions: """
            You write short push notifications for a posture-reminder app. \
            Reply with exactly two lines: line 1 is a notification title (2-5 words), \
            line 2 is the notification body, one sentence under 20 words, no emoji, no quotation marks. \
            Tone: \(tone). Make the wording sound different each time, not like a generic template.
            """)

        let prompt = """
            The person has been leaning forward \(Int(abs(leanDegrees)))° for about \
            \(Int(sustainedSeconds)) seconds. This is reminder #\(repeatCount) during this sitting \
            session. Write the notification now.
            """

        do {
            let response = try await session.respond(to: prompt)
            let lines = response.content
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard let title = lines.first, let body = lines.dropFirst().first,
                  !title.isEmpty, !body.isEmpty else {
                return fallback
            }
            return (title: title, body: body)
        } catch {
            return fallback
        }
    }
}
