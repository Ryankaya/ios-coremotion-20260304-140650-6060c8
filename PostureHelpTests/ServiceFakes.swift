import Foundation
import Combine
@testable import PostureHelp

final class FakeMotionService: MotionServiceProtocol {
    var isAvailable: Bool = true
    private(set) var startUpdatesCallCount = 0
    private(set) var stopUpdatesCallCount = 0
    private var handler: ((Double) -> Void)?

    func startUpdates(handler: @escaping (Double) -> Void) {
        startUpdatesCallCount += 1
        self.handler = handler
    }

    func stopUpdates() {
        stopUpdatesCallCount += 1
        handler = nil
    }

    func emit(pitch: Double) {
        handler?(pitch)
    }
}

final class FakeHapticService: HapticServiceProtocol {
    private(set) var warningCount = 0
    private(set) var alertCount = 0

    func play(_ pattern: HapticPattern) {
        switch pattern {
        case .none:
            break
        case .warning:
            warningCount += 1
        case .alert:
            alertCount += 1
        }
    }
}

final class FakeNotificationService: NotificationServiceProtocol {
    var isAuthorized: Bool = true
    private(set) var sentLeanDegrees: [Double] = []

    func requestAuthorization() async -> Bool {
        isAuthorized
    }

    func sendPostureAlert(leanDegrees: Double, sustainedSeconds: Double, repeatCount: Int) {
        sentLeanDegrees.append(leanDegrees)
    }
}

final class FakeUserActivityService: UserActivityServiceProtocol {
    var isUserActive: Bool = true
    private(set) var startMonitoringCallCount = 0
    private(set) var stopMonitoringCallCount = 0
    private let subject = PassthroughSubject<Bool, Never>()

    var activityPublisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    func startMonitoring() { startMonitoringCallCount += 1 }
    func stopMonitoring() { stopMonitoringCallCount += 1 }
    func emit(isActive: Bool) { subject.send(isActive) }
}

final class FakeDeviceMovementService: DeviceMovementServiceProtocol {
    var isHumanHolding: Bool = true
    private(set) var startMonitoringCallCount = 0
    private(set) var stopMonitoringCallCount = 0
    private let subject = PassthroughSubject<Bool, Never>()

    var movementPublisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    func startMonitoring() { startMonitoringCallCount += 1 }
    func stopMonitoring() { stopMonitoringCallCount += 1 }
    func emit(isHolding: Bool) { subject.send(isHolding) }
}

final class FakeDeviceStateService: DeviceStateServiceProtocol {
    var isScreenLocked: Bool = false
    var isInPocket: Bool = false
    var canShowAlerts: Bool = true
    private(set) var startMonitoringCallCount = 0
    private(set) var stopMonitoringCallCount = 0
    private let subject = PassthroughSubject<DeviceState, Never>()

    var statePublisher: AnyPublisher<DeviceState, Never> {
        subject.eraseToAnyPublisher()
    }

    func startMonitoring() { startMonitoringCallCount += 1 }
    func stopMonitoring() { stopMonitoringCallCount += 1 }

    func emit(_ state: DeviceState) {
        isScreenLocked = state.isScreenLocked
        isInPocket = state.isInPocket
        canShowAlerts = state.canShowAlerts
        subject.send(state)
    }
}

final class FakeOrientationService: OrientationServiceProtocol {
    var currentOrientation: DeviceOrientation = .portrait
    private(set) var startMonitoringCallCount = 0
    private(set) var stopMonitoringCallCount = 0
    private let subject = PassthroughSubject<DeviceOrientation, Never>()

    var orientationPublisher: AnyPublisher<DeviceOrientation, Never> {
        subject.eraseToAnyPublisher()
    }

    func startMonitoring() { startMonitoringCallCount += 1 }
    func stopMonitoring() { stopMonitoringCallCount += 1 }
    func emit(_ orientation: DeviceOrientation) { subject.send(orientation) }
}
