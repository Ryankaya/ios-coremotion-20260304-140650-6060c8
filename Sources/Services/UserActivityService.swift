import UIKit
import CoreMotion
import Combine

protocol UserActivityServiceProtocol {
    var isUserActive: Bool { get }
    var activityPublisher: AnyPublisher<Bool, Never> { get }
    func startMonitoring()
    func stopMonitoring()
}

final class UserActivityService: UserActivityServiceProtocol {
    @Published private(set) var isUserActive: Bool = false
    
    var activityPublisher: AnyPublisher<Bool, Never> {
        $isUserActive.eraseToAnyPublisher()
    }
    
    private let motionActivityManager = CMMotionActivityManager()
    private let operationQueue = OperationQueue()
    private var lastActivityTime: Date = Date()
    private var checkTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private let activityTimeout: TimeInterval = 30 // Consider inactive after 30 seconds
    
    init() {
        setupAppStateObservers()
    }
    
    func startMonitoring() {
        startActivityMonitoring()
        startPeriodicCheck()
        checkCurrentState()
    }
    
    func stopMonitoring() {
        motionActivityManager.stopActivityUpdates()
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    private func setupAppStateObservers() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppForeground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.markUserActive()
            }
            .store(in: &cancellables)
    }
    
    private func startActivityMonitoring() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            return
        }
        
        motionActivityManager.startActivityUpdates(to: operationQueue) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            self.processActivity(activity)
        }
    }
    
    private func processActivity(_ activity: CMMotionActivity) {
        let isStationary = activity.stationary
        let isWalking = activity.walking
        let isRunning = activity.running
        
        // IMPORTANT: Stationary = sitting and watching videos = ACTIVE for posture monitoring
        // Walking/Running = not sitting at desk = INACTIVE for posture monitoring
        if isStationary {
            DispatchQueue.main.async {
                self.lastActivityTime = Date()
                self.isUserActive = true  // Stationary = Active for posture!
                
                #if DEBUG
                print("✅ User is stationary (sitting) - marked as ACTIVE for posture monitoring")
                #endif
            }
        } else if isWalking || isRunning {
            DispatchQueue.main.async {
                self.isUserActive = false
                
                #if DEBUG
                print("🚶 User is walking/running - marked as INACTIVE for posture monitoring")
                #endif
            }
        }
    }
    
    private func startPeriodicCheck() {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkCurrentState()
        }
    }
    
    private func checkCurrentState() {
        updateActiveState()
        
        if UIApplication.shared.applicationState == .active {
            markUserActive()
        }
    }
    
    private func updateActiveState() {
        let timeSinceLastActivity = Date().timeIntervalSince(lastActivityTime)
        let shouldBeActive = timeSinceLastActivity < activityTimeout
        
        DispatchQueue.main.async {
            self.isUserActive = shouldBeActive
        }
    }
    
    private func handleAppForeground() {
        markUserActive()
        checkCurrentState()
    }
    
    private func handleAppBackground() {
        checkCurrentState()
    }
    
    private func markUserActive() {
        lastActivityTime = Date()
        isUserActive = true
    }
    
    deinit {
        stopMonitoring()
    }
}
