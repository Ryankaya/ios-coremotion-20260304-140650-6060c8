import CoreMotion
import Foundation
import Combine

protocol DeviceMovementServiceProtocol: AnyObject {
    var isHumanHolding: Bool { get }
    var movementPublisher: AnyPublisher<Bool, Never> { get }
    func startMonitoring()
    func stopMonitoring()
}

final class DeviceMovementService: DeviceMovementServiceProtocol, ObservableObject {
    @Published private(set) var isHumanHolding: Bool = false
    
    var movementPublisher: AnyPublisher<Bool, Never> {
        $isHumanHolding.eraseToAnyPublisher()
    }
    
    private let motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()
    
    private var accelerationHistory: [Double] = []
    private let historySize = 30 // 3 seconds of data at 10Hz
    private var lastSignificantMovement: Date = Date()
    private var consecutiveStableSamples = 0 // Count of consecutive stable samples
    
    // Threshold for detecting change between consecutive samples
    private let stabilityThreshold: Double = 0.005 // If consecutive samples differ by more than this, it's movement
    private let minChangesForHuman: Int = 3 // Need at least 3 changes in last 30 samples to be "human"
    private let maxStableSamplesForTable: Int = 15 // 15 consecutive stable samples (~1.5 sec) = table
    
    private var checkTimer: Timer?
    
    func startMonitoring() {
        guard motionManager.isAccelerometerAvailable else {
            isHumanHolding = true // Assume human if no accelerometer
            return
        }
        
        motionManager.accelerometerUpdateInterval = 0.1 // 10 Hz
        
        motionManager.startAccelerometerUpdates(to: operationQueue) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            self.processAccelerometerData(data)
        }
        
        startPeriodicCheck()
    }
    
    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
        checkTimer?.invalidate()
        checkTimer = nil
        accelerationHistory.removeAll()
    }
    
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        let acceleration = data.acceleration
        
        // Calculate total acceleration magnitude (Euclidean norm)
        let magnitude = sqrt(
            acceleration.x * acceleration.x +
            acceleration.y * acceleration.y +
            acceleration.z * acceleration.z
        )
        
        // Add to history
        DispatchQueue.main.async {
            self.accelerationHistory.append(magnitude)
            
            // Keep only recent history
            if self.accelerationHistory.count > self.historySize {
                self.accelerationHistory.removeFirst()
            }
            
            self.analyzeMovementPattern()
        }
    }
    
    private func analyzeMovementPattern() {
        guard accelerationHistory.count >= 10 else {
            // Not enough data yet, assume human
            isHumanHolding = true
            consecutiveStableSamples = 0
            return
        }
        
        // Check if last sample is stable compared to previous
        if accelerationHistory.count >= 2 {
            let lastChange = abs(accelerationHistory[accelerationHistory.count - 1] - accelerationHistory[accelerationHistory.count - 2])
            
            if lastChange <= stabilityThreshold {
                consecutiveStableSamples += 1
            } else {
                consecutiveStableSamples = 0 // Reset on any movement
            }
        }
        
        // FAST table detection: If 15 consecutive samples are stable (~1.5 seconds)
        if consecutiveStableSamples >= maxStableSamplesForTable {
            if isHumanHolding {
                #if DEBUG
                print("📱 FAST Table detected - \(consecutiveStableSamples) consecutive stable samples")
                #endif
            }
            isHumanHolding = false
            return
        }
        
        // Count how many times consecutive samples differ (micro-movements)
        var changeCount = 0
        var totalChange = 0.0
        
        for i in 1..<accelerationHistory.count {
            let change = abs(accelerationHistory[i] - accelerationHistory[i-1])
            totalChange += change
            
            if change > stabilityThreshold {
                changeCount += 1
            }
        }
        
        let averageChange = totalChange / Double(accelerationHistory.count - 1)
        
        // If samples are changing (not stable), it's a human
        // If samples are identical or nearly identical, it's on table
        let hasHumanMovement = changeCount >= minChangesForHuman
        
        #if DEBUG
        print("📊 Movement Detection - Changes: \(changeCount)/\(accelerationHistory.count), Consecutive Stable: \(consecutiveStableSamples), AvgChange: \(String(format: "%.5f", averageChange)), IsHuman: \(hasHumanMovement)")
        #endif
        
        if hasHumanMovement {
            lastSignificantMovement = Date()
            consecutiveStableSamples = 0 // Reset
            
            if !isHumanHolding {
                #if DEBUG
                print("✅ Human detected - \(changeCount) micro-movements in last \(accelerationHistory.count) samples")
                #endif
            }
            isHumanHolding = true
        } else {
            // Check if device has been completely still
            let timeSinceMovement = Date().timeIntervalSince(lastSignificantMovement)
            
            if timeSinceMovement > 1.0 {
                // Device is perfectly stable - likely on table
                if isHumanHolding {
                    #if DEBUG
                    print("📱 Table detected - only \(changeCount) changes in \(accelerationHistory.count) samples, stable for \(Int(timeSinceMovement))s")
                    #endif
                }
                isHumanHolding = false
            }
        }
    }
    
    private func startPeriodicCheck() {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkStillness()
        }
    }
    
    private func checkStillness() {
        let timeSinceMovement = Date().timeIntervalSince(lastSignificantMovement)
        
        if timeSinceMovement > 2.0 {
            DispatchQueue.main.async {
                if self.isHumanHolding {
                    #if DEBUG
                    print("⏱️ Periodic check: Still no movement for \(Int(timeSinceMovement))s - marking as table")
                    #endif
                    self.isHumanHolding = false
                }
            }
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
