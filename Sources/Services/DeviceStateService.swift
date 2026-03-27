import UIKit
import Combine

protocol DeviceStateServiceProtocol: AnyObject {
    var isScreenLocked: Bool { get }
    var isInPocket: Bool { get }
    var canShowAlerts: Bool { get }
    var statePublisher: AnyPublisher<DeviceState, Never> { get }
    func startMonitoring()
    func stopMonitoring()
}

struct DeviceState {
    var isScreenLocked: Bool
    var isInPocket: Bool
    var canShowAlerts: Bool
    
    var stateDescription: String {
        if isScreenLocked {
            return "Screen locked"
        } else if isInPocket {
            return "In pocket"
        } else {
            return "Active"
        }
    }
}

final class DeviceStateService: DeviceStateServiceProtocol, ObservableObject {
    @Published private(set) var isScreenLocked: Bool = false
    @Published private(set) var isInPocket: Bool = false
    @Published private(set) var canShowAlerts: Bool = true
    
    private var currentState = DeviceState(isScreenLocked: false, isInPocket: false, canShowAlerts: true)
    private let stateSubject = PassthroughSubject<DeviceState, Never>()
    
    var statePublisher: AnyPublisher<DeviceState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var proximityCheckTimer: Timer?
    
    func startMonitoring() {
        setupScreenLockMonitoring()
        setupProximityMonitoring()
        checkCurrentState()
    }
    
    func stopMonitoring() {
        cancellables.removeAll()
        proximityCheckTimer?.invalidate()
        proximityCheckTimer = nil
        screenLockCheckTimer?.invalidate()
        screenLockCheckTimer = nil
        UIDevice.current.isProximityMonitoringEnabled = false
    }
    
    private func setupScreenLockMonitoring() {
        // Monitor app state changes
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppWillResignActive()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppDidBecomeActive()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppWillEnterForeground()
            }
            .store(in: &cancellables)
    }
    
    private func setupProximityMonitoring() {
        // Enable proximity sensor
        UIDevice.current.isProximityMonitoringEnabled = true
        
        // Monitor proximity state changes
        NotificationCenter.default.publisher(for: UIDevice.proximityStateDidChangeNotification)
            .sink { [weak self] _ in
                self?.handleProximityChange()
            }
            .store(in: &cancellables)
        
        // Periodic check
        proximityCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkProximityState()
        }
    }
    
    private var screenLockCheckTimer: Timer?
    
    private func handleAppWillResignActive() {
        // App is losing focus - could be switching apps, not screen lock
        // Don't mark as locked - notifications work fine
        #if DEBUG
        print("📱 App will resign active")
        #endif
    }
    
    private func handleAppDidBecomeActive() {
        // App came to foreground
        isScreenLocked = false
        updateState()
        
        #if DEBUG
        print("✅ App became active")
        #endif
    }
    
    private func handleAppDidEnterBackground() {
        // App in background - could be:
        // 1. Using other apps (YouTube, Safari) - SHOULD alert
        // 2. Screen locked - rely on proximity sensor to detect
        
        // Don't mark as locked - let proximity sensor handle it
        isScreenLocked = false
        
        #if DEBUG
        print("📱 App entered background - alerts continue (unless in pocket)")
        #endif
    }
    
    private func handleAppWillEnterForeground() {
        // App coming back to foreground
        isScreenLocked = false
        updateState()
        
        #if DEBUG
        print("📱 App returning to foreground")
        #endif
    }
    
    private func checkIfScreenLocked() {
        // We don't have a reliable way to detect screen lock vs background app usage
        // iOS sends notifications regardless of screen lock state
        // Only use proximity sensor to detect "unusable" state
        isScreenLocked = false
    }
    
    private func handleProximityChange() {
        checkProximityState()
    }
    
    private func checkProximityState() {
        let wasInPocket = isInPocket
        isInPocket = UIDevice.current.proximityState
        
        if wasInPocket != isInPocket {
            updateState()
            
            #if DEBUG
            if isInPocket {
                print("👖 Device in pocket - proximity sensor covered")
            } else {
                print("✋ Device removed from pocket - proximity sensor uncovered")
            }
            #endif
        }
    }
    
    private func checkCurrentState() {
        let appState = UIApplication.shared.applicationState
        isScreenLocked = (appState == .background)
        isInPocket = UIDevice.current.proximityState
        updateState()
    }
    
    private func updateState() {
        canShowAlerts = !isScreenLocked && !isInPocket
        
        currentState = DeviceState(
            isScreenLocked: isScreenLocked,
            isInPocket: isInPocket,
            canShowAlerts: canShowAlerts
        )
        
        stateSubject.send(currentState)
    }
    
    deinit {
        stopMonitoring()
    }
}
