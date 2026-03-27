import Foundation
import Combine
import UIKit

@MainActor
final class PostureViewModel: ObservableObject {
    @Published var metrics = PostureMetrics()
    @Published var configuration = PostureConfiguration()
    @Published var isMonitoring = false
    @Published var statusMessage = "Sit upright and tap 'Start Monitoring' to begin"
    @Published var notificationsEnabled = false
    @Published var isUserActive = false
    @Published var isHumanHolding = true
    @Published var isScreenLocked = false
    @Published var isInPocket = false
    @Published var deviceOrientation: DeviceOrientation = .portrait
    @Published var onlyAlertWhenActive = false  // DEFAULT OFF - allow alerts even when "inactive" (watching videos counts as inactive)
    @Published var detectDeviceOnTable = true
    @Published var onlyAlertInPortrait = false  // DEFAULT OFF - allow alerts in any orientation
    
    private let motionService: MotionServiceProtocol
    private let hapticService: HapticServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private let activityService: UserActivityServiceProtocol
    private let movementService: DeviceMovementServiceProtocol
    private let deviceStateService: DeviceStateServiceProtocol
    private let orientationService: OrientationServiceProtocol
    
    private var forwardLeanStartDate: Date?
    private var notificationCooldownUntil: Date = .distantPast
    private var cancellables = Set<AnyCancellable>()
    
    init(
        motionService: MotionServiceProtocol = MotionService(),
        hapticService: HapticServiceProtocol = HapticService(),
        notificationService: NotificationServiceProtocol = NotificationService(),
        activityService: UserActivityServiceProtocol = UserActivityService(),
        movementService: DeviceMovementServiceProtocol = DeviceMovementService(),
        deviceStateService: DeviceStateServiceProtocol = DeviceStateService(),
        orientationService: OrientationServiceProtocol = OrientationService()
    ) {
        self.motionService = motionService
        self.hapticService = hapticService
        self.notificationService = notificationService
        self.activityService = activityService
        self.movementService = movementService
        self.deviceStateService = deviceStateService
        self.orientationService = orientationService
        
        setupActivityObserver()
        setupMovementObserver()
        setupDeviceStateObserver()
        setupOrientationObserver()
        setupAppStateObservers()
    }
    
    private func setupOrientationObserver() {
        orientationService.orientationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orientation in
                self?.deviceOrientation = orientation
            }
            .store(in: &cancellables)
    }
    
    private func setupDeviceStateObserver() {
        deviceStateService.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.isScreenLocked = state.isScreenLocked
                self?.isInPocket = state.isInPocket
                
                // Update status message when pocket state changes
                if state.isInPocket {
                    self?.statusMessage = "Device in pocket - alerts paused"
                } else if !state.isInPocket && self?.isMonitoring == true {
                    self?.statusMessage = "Monitoring (alerts work in background)"
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupMovementObserver() {
        movementService.movementPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isHolding in
                guard let self = self else { return }
                
                let wasHolding = self.isHumanHolding
                self.isHumanHolding = isHolding
                
                // If device just went from human to table, cancel pending alerts
                if wasHolding && !isHolding && self.detectDeviceOnTable {
                    self.handleDevicePlacedOnTable()
                }
                
                // If device just picked up from table, resume monitoring
                if !wasHolding && isHolding && self.detectDeviceOnTable {
                    self.handleDevicePickedUp()
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleDevicePlacedOnTable() {
        // Cancel any pending alert countdown
        forwardLeanStartDate = nil
        
        // Update status immediately
        statusMessage = "Device placed on table - alerts paused"
        
        // Reset posture state if was in warning/alert
        if metrics.postureState == .warning || metrics.postureState == .alert {
            metrics.postureState = .unknown
        }
        
        #if DEBUG
        print("📱 Device placed on table - cancelled pending alerts")
        #endif
    }
    
    private func handleDevicePickedUp() {
        // Reset lean detection when picking up
        forwardLeanStartDate = nil
        
        // Update status
        if isMonitoring {
            statusMessage = "Device picked up - monitoring resumed"
        }
        
        #if DEBUG
        print("✋ Device picked up - alerts resumed")
        #endif
    }
    
    private func setupActivityObserver() {
        activityService.activityPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                self?.isUserActive = isActive
            }
            .store(in: &cancellables)
    }
    
    private func setupAppStateObservers() {
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppForeground()
            }
            .store(in: &cancellables)
    }
    
    private func handleAppBackground() {
        if isMonitoring {
            BackgroundTaskService.shared.beginBackgroundTask()
        }
    }
    
    private func handleAppForeground() {
        BackgroundTaskService.shared.endBackgroundTask()
    }
    
    func startMonitoring() {
        guard motionService.isAvailable else {
            statusMessage = "Device motion is unavailable on this device"
            isMonitoring = false
            return
        }
        
        if !metrics.isBaselineSet {
            statusMessage = "Auto-calibrating baseline..."
            startMotionUpdates()
            activityService.startMonitoring()
            movementService.startMonitoring()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.calibrateBaseline()
                self?.isMonitoring = true
                self?.statusMessage = "Monitoring posture in background..."
            }
            return
        }
        
        isMonitoring = true
        statusMessage = "Monitoring posture in background..."
        forwardLeanStartDate = nil
        
        startMotionUpdates()
        activityService.startMonitoring()
        movementService.startMonitoring()
        deviceStateService.startMonitoring()
        orientationService.startMonitoring()
    }
    
    private func startMotionUpdates() {
        motionService.startUpdates { [weak self] pitch in
            self?.handleMotionUpdate(pitch: pitch)
        }
    }
    
    func stopMonitoring() {
        motionService.stopUpdates()
        activityService.stopMonitoring()
        movementService.stopMonitoring()
        deviceStateService.stopMonitoring()
        orientationService.stopMonitoring()
        isMonitoring = false
        forwardLeanStartDate = nil
        statusMessage = "Monitoring stopped"
        metrics.postureState = .unknown
        BackgroundTaskService.shared.endBackgroundTask()
    }
    
    func calibrateBaseline() {
        if metrics.currentPitch == 0 {
            statusMessage = "Getting motion data..."
            startMotionUpdates()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                self.metrics.baselinePitch = self.metrics.currentPitch
                self.forwardLeanStartDate = nil
                self.statusMessage = "Baseline calibrated! Start monitoring when ready"
                self.metrics.postureState = .good
                if !self.isMonitoring {
                    self.motionService.stopUpdates()
                }
            }
        } else {
            metrics.baselinePitch = metrics.currentPitch
            forwardLeanStartDate = nil
            statusMessage = "Baseline calibrated! Start monitoring when ready"
            metrics.postureState = .good
        }
    }
    
    func requestNotifications() async {
        let granted = await notificationService.requestAuthorization()
        notificationsEnabled = granted
        
        if granted {
            statusMessage = "Notifications enabled"
        } else {
            statusMessage = "Notifications denied. Haptics will still work"
        }
    }
    
    private func handleMotionUpdate(pitch: Double) {
        metrics.currentPitch = pitch
        metrics.leanDeltaDegrees = (pitch - metrics.baselinePitch) * 180 / .pi
        evaluatePosture()
    }
    
    private func evaluatePosture() {
        let leanDelta = metrics.leanDeltaDegrees
        let threshold = configuration.forwardLeanThresholdDegrees
        
        #if DEBUG
        print("📊 Evaluating posture - Lean: \(String(format: "%.1f", leanDelta))° | Threshold: -\(threshold)°")
        #endif
        
        if leanDelta > -threshold {
            // Good posture - reset alert timer
            if forwardLeanStartDate != nil {
                #if DEBUG
                print("✅ Posture improved - resetting alert timer")
                #endif
            }
            forwardLeanStartDate = nil
            metrics.postureState = .good
            if isMonitoring {
                if detectDeviceOnTable && !isHumanHolding {
                    statusMessage = "Good posture (device on table - alerts paused)"
                } else {
                    statusMessage = "Good posture"
                }
            }
            return
        }
        
        if forwardLeanStartDate == nil {
            forwardLeanStartDate = Date()
            metrics.postureState = .warning
            
            #if DEBUG
            print("⚠️ Started leaning forward - timer started")
            #endif
            
            if detectDeviceOnTable && !isHumanHolding {
                statusMessage = "Lean detected but device on table - alerts paused"
            } else {
                statusMessage = "Leaning forward detected"
            }
            return
        }
        
        guard let startDate = forwardLeanStartDate else { return }
        let elapsed = Date().timeIntervalSince(startDate)
        
        #if DEBUG
        print("⏱️ Lean duration: \(String(format: "%.1f", elapsed))s / \(configuration.sustainedSeconds)s")
        #endif
        
        if elapsed >= configuration.sustainedSeconds {
            metrics.postureState = .alert
            
            if detectDeviceOnTable && !isHumanHolding {
                statusMessage = "Poor posture detected but device on table - no alert"
                #if DEBUG
                print("📱 Device on table - skipping alert")
                #endif
            } else {
                statusMessage = "Poor posture - please sit upright"
                #if DEBUG
                print("🚨 Poor posture threshold reached - triggering alert")
                #endif
            }
            
            triggerAlert(leanDelta: leanDelta)
            
            // Reset timer to allow repeated alerts based on interval
            forwardLeanStartDate = Date()
        } else {
            metrics.postureState = .warning
        }
    }
    
    private func triggerAlert(leanDelta: Double) {
        #if DEBUG
        print("🔍 === ALERT TRIGGER CHECK ===")
        print("   Lean Delta: \(leanDelta)°")
        print("   Cooldown until: \(notificationCooldownUntil)")
        print("   Current time: \(Date())")
        print("   Can alert: \(Date() >= notificationCooldownUntil)")
        #endif
        
        guard Date() >= notificationCooldownUntil else {
            #if DEBUG
            print("⏰ Alert skipped - in cooldown period")
            #endif
            return
        }
        
        // Don't alert if not in portrait orientation (watching TikTok/Reels/Shorts)
        if onlyAlertInPortrait && !deviceOrientation.shouldAlertForPosture {
            #if DEBUG
            print("📱 Alert skipped - wrong orientation (\(deviceOrientation.description))")
            print("   shouldAlertForPosture: \(deviceOrientation.shouldAlertForPosture)")
            #endif
            return
        }
        
        // Don't alert if device is in pocket (proximity sensor covered)
        // This also covers screen lock - if locked and in pocket, proximity will detect it
        if isInPocket {
            #if DEBUG
            print("👖 Alert skipped - device in pocket (proximity sensor covered)")
            #endif
            return
        }
        
        // Don't alert if user is not active (walking, etc.)
        if onlyAlertWhenActive && !isUserActive {
            #if DEBUG
            print("🚶 Alert skipped - user not active (walking/running)")
            print("   isUserActive: \(isUserActive)")
            print("   onlyAlertWhenActive: \(onlyAlertWhenActive)")
            #endif
            return
        }
        
        // Don't alert if device is on table
        if detectDeviceOnTable && !isHumanHolding {
            #if DEBUG
            print("📱 Alert skipped - device on table (no human vibrations)")
            print("   isHumanHolding: \(isHumanHolding)")
            print("   detectDeviceOnTable: \(detectDeviceOnTable)")
            #endif
            statusMessage = "Device appears to be on table - alerts paused"
            return
        }
        
        // All checks passed - send alert!
        // NOTE: This works even if app is in background or user is using other apps
        #if DEBUG
        let appState = UIApplication.shared.applicationState
        print("✅ All checks passed!")
        print("🔔 SENDING ALERT - Portrait orientation + poor posture")
        print("   App state: \(appState == .active ? "active" : "background")")
        print("   Lean: \(leanDelta)°")
        print("   Next alert after: \(Date().addingTimeInterval(configuration.reminderIntervalSeconds))")
        #endif
        
        hapticService.playPostureAlert()
        notificationService.sendPostureAlert(leanDegrees: leanDelta)
        
        metrics.lastAlertDate = Date()
        notificationCooldownUntil = Date().addingTimeInterval(configuration.reminderIntervalSeconds)
        
        #if DEBUG
        print("=== ALERT SENT SUCCESSFULLY ===")
        #endif
    }
}
