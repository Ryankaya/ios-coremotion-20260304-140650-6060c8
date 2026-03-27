import CoreHaptics
import UIKit
import AudioToolbox

protocol HapticServiceProtocol {
    func playPostureAlert()
}

final class HapticService: HapticServiceProtocol {
    private var hapticEngine: CHHapticEngine?
    
    init() {
        prepareHaptics()
    }
    
    func playPostureAlert() {
        guard UIApplication.shared.applicationState == .active else { return }
        
        if playCustomPattern() {
            return
        }
        
        playFallbackPattern()
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            hapticEngine = nil
        }
    }
    
    private func playCustomPattern() -> Bool {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let hapticEngine = hapticEngine else {
            return false
        }
        
        do {
            try hapticEngine.start()
            
            let events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.45)
                ], relativeTime: 0.00),
                CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35)
                ], relativeTime: 0.05, duration: 0.25),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ], relativeTime: 0.38),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ], relativeTime: 0.62)
            ]
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            return true
        } catch {
            return false
        }
    }
    
    private func playFallbackPattern() {
        let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
        heavyImpact.prepare()
        
        for index in 0..<3 {
            let delay = Double(index) * 0.25
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                heavyImpact.impactOccurred(intensity: 1.0)
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }
    }
}
