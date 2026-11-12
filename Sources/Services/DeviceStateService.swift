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
        UIDevice.current.isProximityMonitoringEnabled = false
    }
    
    private func setupScreenLockMonitoring() {
        // protectedData notifications fire only when the device is actually locked/unlocked,
        // unlike app foreground/background which also fires when switching to another app
        // (e.g. Safari) while the screen stays on and unlocked. That distinction matters here:
        // a backgrounded-but-unlocked phone should still alert, a locked one shouldn't.
        NotificationCenter.default.publisher(for: UIApplication.protectedDataWillBecomeUnavailableNotification)
            .sink { [weak self] _ in
                self?.isScreenLocked = true
                self?.updateState()
                
                #if DEBUG
                print("🔒 Device locked")
                #endif
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification)
            .sink { [weak self] _ in
                self?.isScreenLocked = false
                self?.updateState()
                
                #if DEBUG
                print("🔓 Device unlocked")
                #endif
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
        isScreenLocked = !UIApplication.shared.isProtectedDataAvailable
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
