import UserNotifications
import Foundation

protocol NotificationServiceProtocol {
    var isAuthorized: Bool { get }
    func requestAuthorization() async -> Bool
    func sendPostureAlert(leanDegrees: Double)
}

final class NotificationService: NotificationServiceProtocol {
    @Published private(set) var isAuthorized: Bool = false
    
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
    
    func sendPostureAlert(leanDegrees: Double) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Posture Check"
        content.body = "Forward lean is \(Int(abs(leanDegrees)))°. Sit upright and relax your shoulders."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
