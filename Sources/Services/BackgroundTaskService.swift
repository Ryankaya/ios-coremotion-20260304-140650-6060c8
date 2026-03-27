import UIKit
import BackgroundTasks

final class BackgroundTaskService {
    static let shared = BackgroundTaskService()
    
    private let taskIdentifier = "com.posturehelp.monitoring"
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    private init() {}
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundTask(task: task as! BGProcessingTask)
        }
    }
    
    func scheduleBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background task: \(error)")
        }
    }
    
    private func handleBackgroundTask(task: BGProcessingTask) {
        scheduleBackgroundTask()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            task.setTaskCompleted(success: true)
        }
    }
    
    func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}
