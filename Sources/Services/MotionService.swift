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
