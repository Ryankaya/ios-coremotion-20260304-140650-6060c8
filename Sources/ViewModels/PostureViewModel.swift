import Foundation
import Combine
import UIKit
import WidgetKit
import UserNotifications

@MainActor
final class PostureViewModel: ObservableObject {
    @Published var metrics = PostureMetrics()
    @Published var configuration = PostureConfiguration() {
        didSet { saveConfiguration() }
    }
    @Published var isMonitoring = false
    @Published var statusMessage = "Sit upright and tap 'Start Monitoring' to begin"
    @Published var notificationsEnabled = false
    @Published var isUserActive = false
    @Published var isHumanHolding = true
    @Published var isScreenLocked = false
    @Published var isInPocket = false
    @Published var deviceOrientation: DeviceOrientation = .portrait
    @Published var onlyAlertWhenActive = false {  // DEFAULT OFF - allow alerts even when "inactive" (watching videos counts as inactive)
        didSet { publishWidgetSnapshot() }
    }
    @Published var detectDeviceOnTable = true {
        didSet { publishWidgetSnapshot() }
    }
    @Published var onlyAlertInPortrait = false {  // DEFAULT OFF - allow alerts in any orientation
        didSet { publishWidgetSnapshot() }
    }

    // MARK: Session & history
    @Published private(set) var sessionStartDate: Date?
    @Published private(set) var sessionMonitoredSeconds: Double = 0
    @Published private(set) var sessionGoodSeconds: Double = 0
    @Published private(set) var sessionAlerts = 0
    @Published private(set) var today: DailyPostureRecord
    @Published private(set) var recentDays: [DailyPostureRecord] = []
    @Published private(set) var streak = 0

    var isMotionAvailable: Bool { motionService.isAvailable }

    /// 0...100 share of tracked time spent in good posture this session.
    var sessionScore: Int? {
        guard sessionMonitoredSeconds >= 5 else { return nil }
        return Int((sessionGoodSeconds / sessionMonitoredSeconds * 100).rounded())
    }

    /// Why alerts are currently suppressed, if they are.
    var pauseReason: String? {
        guard isMonitoring else { return nil }
        if isInPocket { return "In pocket" }
        if isScreenLocked { return "Screen locked" }
        if detectDeviceOnTable && !isHumanHolding { return "Resting on a surface" }
        return nil
    }

    private let motionService: MotionServiceProtocol
    private let hapticService: HapticServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private let activityService: UserActivityServiceProtocol
    private let movementService: DeviceMovementServiceProtocol
    private let deviceStateService: DeviceStateServiceProtocol
    private let orientationService: OrientationServiceProtocol
    private let historyStore: PostureHistoryStore
    private let settingsDefaults: UserDefaults
    private static let configurationKey = "posture.configuration.v1"

    private var lastTickDate: Date?
    private var unflushedMonitored: Double = 0
    private var unflushedGood: Double = 0
    private var unflushedAlerts = 0
    private var lastFlushDate = Date()

    private var forwardLeanStartDate: Date?
    private var notificationCooldownUntil: Date = .distantPast
    private var alertRepeatCount = 0
    private var cancellables = Set<AnyCancellable>()
    private var lastPublishedCriticalFingerprint = ""
    private var lastPublishedWidgetFingerprint = ""
    private var pendingWidgetReloadWorkItem: DispatchWorkItem?
    private var lastWidgetReloadDate: Date = .distantPast
    /// Minimum spacing between posture-driven widget reloads. WidgetKit only grants a widget
    /// ~40-70 reloads per day when the app isn't foregrounded - sensor noise right at the lean
    /// threshold can flip `postureState` many times a minute, which would burn through that
    /// budget in minutes and leave the widget frozen on a stale state for the rest of the day.
    /// User-initiated changes (start/stop/calibrate/settings) bypass this and reload immediately.
    private let widgetReloadThrottleInterval: TimeInterval = 2.0

    init(
        motionService: MotionServiceProtocol = MotionService(),
        hapticService: HapticServiceProtocol = HapticService(),
        notificationService: NotificationServiceProtocol = NotificationService(),
        activityService: UserActivityServiceProtocol = UserActivityService(),
        movementService: DeviceMovementServiceProtocol = DeviceMovementService(),
        deviceStateService: DeviceStateServiceProtocol = DeviceStateService(),
        orientationService: OrientationServiceProtocol = OrientationService(),
        historyStore: PostureHistoryStore = .shared,
        settingsDefaults: UserDefaults = .standard
    ) {
        self.historyStore = historyStore
        self.settingsDefaults = settingsDefaults
        self.today = historyStore.record()
        self.motionService = motionService
        self.hapticService = hapticService
        self.notificationService = notificationService
        self.activityService = activityService
        self.movementService = movementService
        self.deviceStateService = deviceStateService
        self.orientationService = orientationService

        if let data = settingsDefaults.data(forKey: Self.configurationKey),
           let saved = try? JSONDecoder().decode(PostureConfiguration.self, from: data),
           saved.isValid {
            configuration = saved
        }
        // Don't publish yet: a widget may have queued a start/calibrate request in the
        // shared snapshot, and `applyPendingWidgetAction()` below must read it first.
        refreshHistory(publish: false)

        setupActivityObserver()
        setupMovementObserver()
        setupDeviceStateObserver()
        setupOrientationObserver()
        setupAppStateObservers()
        setupWidgetChangeObserver()
        BackgroundTaskService.shared.onBackgroundWake = { [weak self] in
            self?.applyPendingWidgetAction()
        }
        applyPendingWidgetAction()
        publishWidgetSnapshot()
    }

    deinit {
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            CFNotificationName(SharedPostureStore.didChangeNotificationName),
            nil
        )
    }

    /// Widgets and Control Center tiles run in a separate process and can only reach the app
    /// through the shared App Group store. Without this, a widget-initiated stop/start/calibrate
    /// is invisible to the app until it's foregrounded or a background task happens to wake it -
    /// meanwhile the app keeps sensing and overwrites the widget's change right back. This Darwin
    /// notification lets the app apply the change the instant it's written.
    private func setupWidgetChangeObserver() {
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer else { return }
                let viewModel = Unmanaged<PostureViewModel>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in
                    viewModel.applyPendingWidgetAction()
                }
            },
            SharedPostureStore.didChangeNotificationName,
            nil,
            .deliverImmediately
        )
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

                // Update status message when pocket/lock state changes
                if state.isInPocket {
                    self?.statusMessage = "Device in pocket - alerts paused"
                } else if state.isScreenLocked {
                    self?.statusMessage = "Device locked - alerts paused"
                } else if self?.isMonitoring == true {
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

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.applyPendingWidgetAction()
            }
            .store(in: &cancellables)
    }

    private func handleAppBackground() {
        flushSession()
        if isMonitoring {
            BackgroundTaskService.shared.beginBackgroundTask()
        }
    }

    private func handleAppForeground() {
        BackgroundTaskService.shared.endBackgroundTask()
        refreshHistory()
        Task { await refreshNotificationStatus() }
    }

    /// Applies any Start/Stop/Calibrate/quick-setting request made from a widget or
    /// Control Center tile while the app wasn't active to receive it directly.
    func applyPendingWidgetAction() {
        let snapshot = SharedPostureStore.load()

        if snapshot.pendingCalibrate {
            calibrateBaseline()
            SharedPostureStore.update { $0.pendingCalibrate = false }
        }

        if snapshot.isMonitoring != isMonitoring {
            if snapshot.isMonitoring {
                startMonitoring()
                BackgroundTaskService.shared.beginBackgroundTask()
            } else {
                stopMonitoring()
            }
        }

        if snapshot.onlyAlertWhenActive != onlyAlertWhenActive {
            onlyAlertWhenActive = snapshot.onlyAlertWhenActive
        }
        if snapshot.detectDeviceOnTable != detectDeviceOnTable {
            detectDeviceOnTable = snapshot.detectDeviceOnTable
        }
        if snapshot.onlyAlertInPortrait != onlyAlertInPortrait {
            onlyAlertInPortrait = snapshot.onlyAlertInPortrait
        }
    }

    /// Mirrors the posture state into the App Group so widgets and Control Center
    /// tiles can render it. Skips the save entirely when nothing actually changed,
    /// since posture updates arrive many times per second while monitoring.
    private func publishWidgetSnapshot() {
        let isDeviceOnTable = detectDeviceOnTable && !isHumanHolding
        // Fields a user explicitly changed (start/stop, calibrate, settings) - these should
        // always reach the widget immediately, and reloads while the app is foregrounded for
        // them don't count against WidgetKit's daily budget anyway.
        let criticalFingerprint = "\(isMonitoring)|\(metrics.isBaselineSet)|\(onlyAlertWhenActive)|\(detectDeviceOnTable)|\(onlyAlertInPortrait)|\(configuration.forwardLeanThresholdDegrees)"
        let todayMinutes = Int(today.monitoredSeconds / 60)
        let fingerprint = "\(criticalFingerprint)|\(metrics.postureState)|\(isDeviceOnTable)|\(today.score ?? -1)|\(todayMinutes)"
        guard fingerprint != lastPublishedWidgetFingerprint else { return }
        lastPublishedWidgetFingerprint = fingerprint

        SharedPostureStore.save(SharedPostureSnapshot(
            isMonitoring: isMonitoring,
            postureStateRaw: metrics.postureState.widgetRawValue,
            statusMessage: statusMessage,
            isBaselineSet: metrics.isBaselineSet,
            leanDegrees: metrics.leanDeltaDegrees,
            onlyAlertWhenActive: onlyAlertWhenActive,
            detectDeviceOnTable: detectDeviceOnTable,
            isDeviceOnTable: isDeviceOnTable,
            onlyAlertInPortrait: onlyAlertInPortrait,
            pendingCalibrate: false,
            todayScore: today.score,
            todayMinutes: todayMinutes,
            leanThreshold: configuration.forwardLeanThresholdDegrees
        ))

        if criticalFingerprint != lastPublishedCriticalFingerprint {
            lastPublishedCriticalFingerprint = criticalFingerprint
            reloadWidgetsNow()
        } else {
            scheduleThrottledWidgetReload()
        }
    }

    /// Coalesces rapid posture-driven reload requests (e.g. sensor noise right at the lean
    /// threshold) into at most one reload per `widgetReloadThrottleInterval`, so the budget
    /// isn't exhausted long before the end of the day.
    private func scheduleThrottledWidgetReload() {
        pendingWidgetReloadWorkItem?.cancel()

        let elapsedSinceLastReload = Date().timeIntervalSince(lastWidgetReloadDate)
        if elapsedSinceLastReload >= widgetReloadThrottleInterval {
            reloadWidgetsNow()
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.reloadWidgetsNow()
        }
        pendingWidgetReloadWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + (widgetReloadThrottleInterval - elapsedSinceLastReload),
            execute: workItem
        )
    }

    private func reloadWidgetsNow() {
        pendingWidgetReloadWorkItem?.cancel()
        pendingWidgetReloadWorkItem = nil
        lastWidgetReloadDate = Date()
        WidgetCenter.shared.reloadAllTimelines()
        if #available(iOS 18.0, *) {
            ControlCenter.shared.reloadAllControls()
        }
    }

    func startMonitoring() {
        guard motionService.isAvailable else {
            statusMessage = "Device motion is unavailable on this device"
            isMonitoring = false
            return
        }
        
        startMotionUpdates()
        activityService.startMonitoring()
        movementService.startMonitoring()
        deviceStateService.startMonitoring()
        orientationService.startMonitoring()
        beginSession()

        if !metrics.isBaselineSet {
            statusMessage = "Auto-calibrating baseline..."
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.calibrateBaseline()
                self?.isMonitoring = true
                self?.statusMessage = "Monitoring posture in background..."
                self?.publishWidgetSnapshot()
            }
            return
        }

        isMonitoring = true
        statusMessage = "Monitoring posture in background..."
        forwardLeanStartDate = nil
        publishWidgetSnapshot()
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
        flushSession()
        lastTickDate = nil
        isMonitoring = false
        forwardLeanStartDate = nil
        statusMessage = "Monitoring stopped"
        metrics.postureState = .unknown
        BackgroundTaskService.shared.endBackgroundTask()
        publishWidgetSnapshot()
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
                self.publishWidgetSnapshot()
            }
        } else {
            metrics.baselinePitch = metrics.currentPitch
            forwardLeanStartDate = nil
            statusMessage = "Baseline calibrated! Start monitoring when ready"
            metrics.postureState = .good
            publishWidgetSnapshot()
        }
    }
    
    /// Syncs notification permission on launch. The service only delivers alerts after
    /// `requestAuthorization` has run in this process, so a previously granted permission
    /// must be re-confirmed (this never shows a prompt once the user has decided).
    func refreshNotificationStatus() async {
        #if DEBUG
        if isDemo { return }
        #endif
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            notificationsEnabled = await notificationService.requestAuthorization()
        default:
            notificationsEnabled = false
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
        tickSession()
    }

    // MARK: - Session tracking

    private func beginSession() {
        if sessionStartDate == nil || !isMonitoring {
            sessionStartDate = Date()
            sessionMonitoredSeconds = 0
            sessionGoodSeconds = 0
            sessionAlerts = 0
        }
        lastTickDate = nil
    }

    /// Accumulates time while alerts are actually live (not pocketed, locked, or on a table).
    private func tickSession() {
        guard isMonitoring else { lastTickDate = nil; return }
        let now = Date()
        defer { lastTickDate = now }
        guard let last = lastTickDate, pauseReason == nil else { return }

        let delta = min(max(now.timeIntervalSince(last), 0), 1)
        sessionMonitoredSeconds += delta
        unflushedMonitored += delta
        if metrics.postureState == .good {
            sessionGoodSeconds += delta
            unflushedGood += delta
        }

        if now.timeIntervalSince(lastFlushDate) > 15 {
            flushSession()
        }
    }

    private func flushSession() {
        lastFlushDate = Date()
        guard unflushedMonitored > 0 || unflushedAlerts > 0 else { return }
        historyStore.add(monitored: unflushedMonitored, good: unflushedGood, alerts: unflushedAlerts)
        unflushedMonitored = 0
        unflushedGood = 0
        unflushedAlerts = 0
        refreshHistory()
    }

    func refreshHistory(publish: Bool = true) {
        today = historyStore.record()
        recentDays = historyStore.lastDays(7)
        streak = historyStore.currentStreak
        if publish { publishWidgetSnapshot() }
    }

    func resetHistory() {
        historyStore.reset()
        unflushedMonitored = 0
        unflushedGood = 0
        unflushedAlerts = 0
        refreshHistory()
    }

    #if DEBUG
    /// True when driven by simulated motion for screenshots; keeps permission checks from
    /// overriding the staged state.
    var isDemo = false

    /// Screenshot/demo support: start a believable in-progress session without real sensors.
    func startDemoSession(minutesAgo: Double = 24.6, uprightShare: Double = 0.88, alerts: Int = 2) {
        startMonitoring()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            let seconds = minutesAgo * 60
            self.sessionStartDate = Date().addingTimeInterval(-seconds)
            self.sessionMonitoredSeconds = seconds
            self.sessionGoodSeconds = seconds * uprightShare
            self.sessionAlerts = alerts
        }
    }
    #endif

    private func saveConfiguration() {
        publishWidgetSnapshot()
        guard let data = try? JSONEncoder().encode(configuration) else { return }
        settingsDefaults.set(data, forKey: Self.configurationKey)
    }
    
    private func evaluatePosture() {
        defer { publishWidgetSnapshot() }
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
            alertRepeatCount = 0
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
            hapticService.play(metrics.hapticPattern)

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
            
            triggerAlert(leanDelta: leanDelta, sustainedSeconds: elapsed)

            // Reset timer to allow repeated alerts based on interval
            forwardLeanStartDate = Date()
        } else {
            metrics.postureState = .warning
        }
    }
    
    private func triggerAlert(leanDelta: Double, sustainedSeconds: Double) {
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
        if isInPocket {
            #if DEBUG
            print("👖 Alert skipped - device in pocket (proximity sensor covered)")
            #endif
            return
        }

        // Don't alert if the device is locked. A loose pocket or bag won't always
        // cover the proximity sensor, but it will almost always leave the screen
        // locked - and a posture nudge is only useful while actually looking at the phone.
        if isScreenLocked {
            #if DEBUG
            print("🔒 Alert skipped - device is locked")
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
        
        hapticService.play(metrics.hapticPattern)
        alertRepeatCount += 1
        sessionAlerts += 1
        unflushedAlerts += 1
        notificationService.sendPostureAlert(
            leanDegrees: leanDelta,
            sustainedSeconds: sustainedSeconds,
            repeatCount: alertRepeatCount
        )

        metrics.lastAlertDate = Date()
        notificationCooldownUntil = Date().addingTimeInterval(configuration.reminderIntervalSeconds)
        
        #if DEBUG
        print("=== ALERT SENT SUCCESSFULLY ===")
        #endif
    }
}
