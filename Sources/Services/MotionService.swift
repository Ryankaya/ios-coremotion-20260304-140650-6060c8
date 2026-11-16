import CoreMotion
import Foundation

protocol MotionServiceProtocol {
    var isAvailable: Bool { get }
    func startUpdates(handler: @escaping (Double) -> Void)
    func stopUpdates()
}

final class MotionService: MotionServiceProtocol {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    var isAvailable: Bool {
        motionManager.isDeviceMotionAvailable
    }
    
    func startUpdates(handler: @escaping (Double) -> Void) {
        guard isAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: queue) { motion, error in
            guard error == nil, let motion = motion else { return }
            DispatchQueue.main.async {
                handler(motion.attitude.pitch)
            }
        }
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}

#if DEBUG
/// Simulated motion for App Store screenshots and Simulator demos (the Simulator has no
/// motion sensors). Activated only in Debug builds via the `-demoMode` launch argument.
/// Emits an upright baseline first (so auto-calibration captures it), then holds the
/// requested forward lean with a little natural jitter.
final class DemoMotionService: MotionServiceProtocol {
    private let leanDegrees: Double
    private let baselinePitch = 0.62
    private var timer: Timer?
    private var startDate = Date()

    init(leanDegrees: Double) {
        self.leanDegrees = leanDegrees
    }

    var isAvailable: Bool { true }

    func startUpdates(handler: @escaping (Double) -> Void) {
        timer?.invalidate()
        startDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let elapsed = Date().timeIntervalSince(self.startDate)
            // Small enough that the rounded value on screen stays steady for screenshots.
            let jitter = sin(elapsed * 1.7) * 0.25 + sin(elapsed * 4.3) * 0.1
            let lean = elapsed < 1.5 ? 0 : self.leanDegrees + jitter
            handler(self.baselinePitch - lean * .pi / 180)
        }
    }

    func stopUpdates() {
        timer?.invalidate()
        timer = nil
    }
}
#endif
