import SwiftUI
import UserNotifications

@main
struct PostureHelpApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = PostureViewModel.makeForLaunch()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        BackgroundTaskService.shared.registerBackgroundTasks()
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

extension PostureViewModel {
    /// Debug builds accept `-demoMode YES` (optionally `-demoLean <degrees>`, `-demoIdle YES`) to drive the UI with
    /// simulated motion and sample history, for App Store screenshots. Release builds always
    /// use the real sensors.
    static func makeForLaunch() -> PostureViewModel {
        #if DEBUG
        let defaults = UserDefaults.standard
        if ProcessInfo.processInfo.arguments.contains("-demoMode") {
            let lean = defaults.object(forKey: "demoLean") != nil ? defaults.double(forKey: "demoLean") : 6
            PostureHistoryStore.shared.seedDemoData()
            let viewModel = PostureViewModel(motionService: DemoMotionService(leanDegrees: lean))
            viewModel.isDemo = true
            viewModel.notificationsEnabled = true
            if !defaults.bool(forKey: "demoIdle") {
                viewModel.startDemoSession()
            }
            return viewModel
        }
        #endif
        return PostureViewModel()
    }
}
