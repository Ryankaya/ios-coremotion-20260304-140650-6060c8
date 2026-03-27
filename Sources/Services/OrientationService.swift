import UIKit
import CoreMotion
import Combine

enum DeviceOrientation {
    case portrait          // Vertical, upright (TikTok/Reels mode) - SHOULD alert
    case portraitUpsideDown // Upside down vertical
    case landscapeLeft     // Horizontal left - Don't alert
    case landscapeRight    // Horizontal right - Don't alert
    case faceUp            // Flat on back - Don't alert
    case faceDown          // Flat on front - Don't alert
    case unknown
    
    var shouldAlertForPosture: Bool {
        // Alert when in portrait mode OR upside down (typical TikTok/Reels/Shorts usage)
        // People hold phones in all orientations while watching vertical videos
        switch self {
        case .portrait, .portraitUpsideDown:
            return true  // Both vertical orientations are OK
        default:
            return false  // Only skip landscape and face up/down
        }
    }
    
    var description: String {
        switch self {
        case .portrait:
            return "Portrait (vertical)"
        case .portraitUpsideDown:
            return "Portrait upside down"
        case .landscapeLeft:
            return "Landscape left"
        case .landscapeRight:
            return "Landscape right"
        case .faceUp:
            return "Face up (flat)"
        case .faceDown:
            return "Face down (flat)"
        case .unknown:
            return "Unknown"
        }
    }
}

protocol OrientationServiceProtocol: AnyObject {
    var currentOrientation: DeviceOrientation { get }
    var orientationPublisher: AnyPublisher<DeviceOrientation, Never> { get }
    func startMonitoring()
    func stopMonitoring()
}

final class OrientationService: OrientationServiceProtocol, ObservableObject {
    @Published private(set) var currentOrientation: DeviceOrientation = .unknown
    
    var orientationPublisher: AnyPublisher<DeviceOrientation, Never> {
        $currentOrientation.eraseToAnyPublisher()
    }
    
    private let motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()
    
    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else {
            currentOrientation = .portrait // Default to portrait if no sensors
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.2 // Check 5 times per second
        
        motionManager.startDeviceMotionUpdates(to: operationQueue) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            
            let gravity = motion.gravity
            let orientation = self.detectOrientation(from: gravity)
            
            DispatchQueue.main.async {
                if self.currentOrientation != orientation {
                    self.currentOrientation = orientation
                    
                    #if DEBUG
                    print("📱 Orientation changed: \(orientation.description) - Should alert: \(orientation.shouldAlertForPosture)")
                    #endif
                }
            }
        }
    }
    
    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func detectOrientation(from gravity: CMAcceleration) -> DeviceOrientation {
        let x = gravity.x
        let y = gravity.y
        let z = gravity.z
        
        // Determine orientation based on gravity direction
        // y-axis: pointing up/down (portrait)
        // x-axis: pointing left/right (landscape)
        // z-axis: pointing forward/back (face up/down)
        
        let absX = abs(x)
        let absY = abs(y)
        let absZ = abs(z)
        
        // Find which axis has strongest gravity (pointing down)
        if absZ > 0.8 {
            // Device is flat
            if z > 0 {
                return .faceDown
            } else {
                return .faceUp
            }
        } else if absY > absX * 0.4 {
            // Portrait orientation (vertical) - VERY RELAXED threshold
            // absY > absX * 0.4 means Y only needs to be 40% as strong as X to count as portrait
            // This allows ~50-60 degree tilts from perfect vertical - people tilt phones A LOT
            if y < 0 {
                // Normal portrait (home button at bottom / notch at top)
                return .portrait
            } else {
                // Upside down
                return .portraitUpsideDown
            }
        } else {
            // Landscape orientation (horizontal)
            if x > 0 {
                return .landscapeRight
            } else {
                return .landscapeLeft
            }
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
