import Testing
import Foundation
@testable import PostureHelp

@MainActor
struct PostureViewModelTests {

    private func makeViewModel(
        motion: FakeMotionService = FakeMotionService(),
        haptic: FakeHapticService = FakeHapticService(),
        notification: FakeNotificationService = FakeNotificationService(),
        activity: FakeUserActivityService = FakeUserActivityService(),
        movement: FakeDeviceMovementService = FakeDeviceMovementService(),
        deviceState: FakeDeviceStateService = FakeDeviceStateService(),
        orientation: FakeOrientationService = FakeOrientationService()
    ) -> PostureViewModel {
        PostureViewModel(
            motionService: motion,
            hapticService: haptic,
            notificationService: notification,
            activityService: activity,
            movementService: movement,
            deviceStateService: deviceState,
            orientationService: orientation
        )
    }

    /// pitch that produces a lean of `degrees` past the given baseline.
    private func leanPitch(baseline: Double, degrees: Double) -> Double {
        baseline - degrees * .pi / 180
    }

    // MARK: - Regression: first-ever Start Monitoring must still start pocket/lock/orientation detection

    @Test
    func startMonitoring_onFreshSessionBeforeBaselineIsCalibrated_stillStartsDeviceStateAndOrientationMonitoring() {
        let deviceState = FakeDeviceStateService()
        let orientation = FakeOrientationService()
        let viewModel = makeViewModel(deviceState: deviceState, orientation: orientation)

        // A brand-new session has no calibrated baseline yet. This used to be exactly
        // the condition that skipped starting deviceState/orientation monitoring,
        // leaving isInPocket/isScreenLocked stuck at false for the whole session.
        #expect(viewModel.metrics.isBaselineSet == false)

        viewModel.startMonitoring()

        #expect(deviceState.startMonitoringCallCount == 1)
        #expect(orientation.startMonitoringCallCount == 1)
    }

    @Test
    func startMonitoring_whenBaselineAlreadyCalibrated_startsDeviceStateAndOrientationMonitoring() {
        let deviceState = FakeDeviceStateService()
        let orientation = FakeOrientationService()
        let viewModel = makeViewModel(deviceState: deviceState, orientation: orientation)
        viewModel.metrics.baselinePitch = 0.4

        viewModel.startMonitoring()

        #expect(deviceState.startMonitoringCallCount == 1)
        #expect(orientation.startMonitoringCallCount == 1)
    }

    // MARK: - Lock/pocket notification gating

    @Test
    func triggerAlert_sendsNotification_whenUnlockedAndNotInPocket() async throws {
        let motion = FakeMotionService()
        let haptic = FakeHapticService()
        let notification = FakeNotificationService()
        let deviceState = FakeDeviceStateService()
        let viewModel = makeViewModel(motion: motion, haptic: haptic, notification: notification, deviceState: deviceState)
        viewModel.metrics.baselinePitch = 0.5
        viewModel.configuration.sustainedSeconds = 0.05
        viewModel.startMonitoring()

        deviceState.emit(DeviceState(isScreenLocked: false, isInPocket: false, canShowAlerts: true))
        try await Task.sleep(nanoseconds: 50_000_000)

        motion.emit(pitch: leanPitch(baseline: 0.5, degrees: 20))
        try await Task.sleep(nanoseconds: 100_000_000)
        motion.emit(pitch: leanPitch(baseline: 0.5, degrees: 20))

        #expect(notification.sentLeanDegrees.count == 1)
        #expect(haptic.alertCount == 1)
    }

    @Test
    func triggerAlert_skipsNotification_whenDeviceIsLocked() async throws {
        let motion = FakeMotionService()
        let haptic = FakeHapticService()
        let notification = FakeNotificationService()
        let deviceState = FakeDeviceStateService()
        let viewModel = makeViewModel(motion: motion, haptic: haptic, notification: notification, deviceState: deviceState)
        viewModel.metrics.baselinePitch = 0.5
        viewModel.configuration.sustainedSeconds = 0.05
        viewModel.startMonitoring()

        // Loose pocket/bag: proximity sensor never covers, but the screen does lock.
        deviceState.emit(DeviceState(isScreenLocked: true, isInPocket: false, canShowAlerts: false))
        try await Task.sleep(nanoseconds: 50_000_000)

        motion.emit(pitch: leanPitch(baseline: 0.5, degrees: 20))
        try await Task.sleep(nanoseconds: 100_000_000)
        motion.emit(pitch: leanPitch(baseline: 0.5, degrees: 20))

        #expect(notification.sentLeanDegrees.isEmpty)
        #expect(haptic.alertCount == 0)
    }

    @Test
    func triggerAlert_skipsNotification_whenDeviceIsInPocket() async throws {
        let motion = FakeMotionService()
        let haptic = FakeHapticService()
        let notification = FakeNotificationService()
        let deviceState = FakeDeviceStateService()
        let viewModel = makeViewModel(motion: motion, haptic: haptic, notification: notification, deviceState: deviceState)
        viewModel.metrics.baselinePitch = 0.5
        viewModel.configuration.sustainedSeconds = 0.05
        viewModel.startMonitoring()

        deviceState.emit(DeviceState(isScreenLocked: false, isInPocket: true, canShowAlerts: false))
        try await Task.sleep(nanoseconds: 50_000_000)

        motion.emit(pitch: leanPitch(baseline: 0.5, degrees: 20))
        try await Task.sleep(nanoseconds: 100_000_000)
        motion.emit(pitch: leanPitch(baseline: 0.5, degrees: 20))

        #expect(notification.sentLeanDegrees.isEmpty)
        #expect(haptic.alertCount == 0)
    }

    @Test
    func deviceStateUpdate_setsLockedStatusMessage() async throws {
        let deviceState = FakeDeviceStateService()
        let viewModel = makeViewModel(deviceState: deviceState)
        viewModel.metrics.baselinePitch = 0.5
        viewModel.startMonitoring()

        deviceState.emit(DeviceState(isScreenLocked: true, isInPocket: false, canShowAlerts: false))
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(viewModel.statusMessage == "Device locked - alerts paused")
    }

    @Test
    func deviceStateUpdate_setsInPocketStatusMessage() async throws {
        let deviceState = FakeDeviceStateService()
        let viewModel = makeViewModel(deviceState: deviceState)
        viewModel.metrics.baselinePitch = 0.5
        viewModel.startMonitoring()

        deviceState.emit(DeviceState(isScreenLocked: false, isInPocket: true, canShowAlerts: false))
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(viewModel.statusMessage == "Device in pocket - alerts paused")
    }
}
