import CoreMotion
import CoreHaptics
import SwiftUI
import UIKit
import UserNotifications
import AudioToolbox

final class MotionViewModel: ObservableObject {
    @Published var status: String = "Tap Start to begin posture monitoring."
    @Published var isMonitoring: Bool = false
    @Published var notificationsEnabled: Bool = false
    @Published var pitch: Double = 0
    @Published var baselinePitch: Double = 0
    @Published var forwardLeanThresholdDegrees: Double = 12
    @Published var sustainedSeconds: Double = 8
    @Published var reminderIntervalSeconds: Double = 20
    @Published var lastNotificationAt: Date?

    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    private var forwardLeanStartDate: Date?
    private var notificationCooldownUntil: Date = .distantPast
    private var hapticEngine: CHHapticEngine?

    init() {
        prepareHaptics()
    }

    var currentLeanDeltaDegrees: Double {
        (pitch - baselinePitch) * 180 / .pi
    }

    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.notificationsEnabled = granted
                if granted {
                    self?.status = "Notifications enabled. Start monitoring when ready."
                } else {
                    self?.status = "Notifications denied. Monitoring still works without alerts."
                }
            }
        }
    }

    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else {
            status = "Device motion is unavailable on this device/simulator."
            isMonitoring = false
            return
        }

        motionManager.deviceMotionUpdateInterval = 0.1
        status = "Monitoring posture..."
        forwardLeanStartDate = nil
        prepareHaptics()

        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let self else { return }

            if let error {
                DispatchQueue.main.async {
                    self.status = "Error: \(error.localizedDescription)"
                    self.isMonitoring = false
                }
                return
            }

            guard let motion else { return }
            let currentPitch = motion.attitude.pitch

            DispatchQueue.main.async {
                self.pitch = currentPitch
                self.isMonitoring = true
                self.evaluatePosture()
            }
        }
    }

    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        isMonitoring = false
        forwardLeanStartDate = nil
        status = "Monitoring stopped."
    }

    func calibrateBaseline() {
        baselinePitch = pitch
        forwardLeanStartDate = nil
        status = "Baseline calibrated. Keep your neutral posture and start monitoring."
    }

    private func evaluatePosture() {
        let leanDeltaDegrees = currentLeanDeltaDegrees
        let threshold = forwardLeanThresholdDegrees

        // Forward lean is represented by a negative delta from baseline in this setup.
        if leanDeltaDegrees > -threshold {
            forwardLeanStartDate = nil
            if isMonitoring {
                status = "Good posture."
            }
            return
        }

        if forwardLeanStartDate == nil {
            forwardLeanStartDate = Date()
            status = "Leaning forward. Straighten up."
            return
        }

        guard let start = forwardLeanStartDate else { return }
        let elapsed = Date().timeIntervalSince(start)
        if elapsed >= sustainedSeconds {
            status = "Posture alert: sustained forward lean detected."
            emitPostureAlert(leanDeltaDegrees: leanDeltaDegrees)
            forwardLeanStartDate = Date()
        }
    }

    private func emitPostureAlert(leanDeltaDegrees: Double) {
        guard Date() >= notificationCooldownUntil else { return }

        triggerDistinctivePostureHaptics()
        sendLocalPostureNotificationIfAllowed(leanDeltaDegrees: leanDeltaDegrees)
        lastNotificationAt = Date()
        notificationCooldownUntil = Date().addingTimeInterval(reminderIntervalSeconds)
    }

    private func sendLocalPostureNotificationIfAllowed(leanDeltaDegrees: Double) {
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Posture Check"
        content.body = "Forward lean is \(Int(leanDeltaDegrees))°. Sit upright and relax your shoulders."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
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

    private func triggerDistinctivePostureHaptics() {
        guard UIApplication.shared.applicationState == .active else { return }
        if playCustomHapticPattern() {
            return
        }

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

    private func playCustomHapticPattern() -> Bool {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return false }
        guard let hapticEngine else { return false }

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
}

struct ContentView: View {
    @StateObject private var vm = MotionViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Smart Posture Coach")
                    .font(.title2.weight(.semibold))

                Text(vm.status)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                postureCard
                settingsCard

                HStack(spacing: 12) {
                    Button(vm.isMonitoring ? "Restart" : "Start") {
                        vm.startMonitoring()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Stop") {
                        vm.stopMonitoring()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!vm.isMonitoring)
                }

                Button("Calibrate Baseline (Sit Straight)") {
                    vm.calibrateBaseline()
                }
                .buttonStyle(.bordered)

                Button(vm.notificationsEnabled ? "Notifications Enabled" : "Enable Notifications") {
                    vm.requestNotificationPermission()
                }
                .buttonStyle(.bordered)
                .disabled(vm.notificationsEnabled)
            }
            .padding()
            .navigationTitle("Posture Coach")
        }
    }

    private var postureCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            rowText("Current pitch", formatAngle(vm.pitch))
            rowText("Baseline pitch", formatAngle(vm.baselinePitch))
            rowText("Forward lean delta", "\(formatSigned(vm.currentLeanDeltaDegrees))°")

            if let lastNotificationAt = vm.lastNotificationAt {
                rowText("Last alert", lastNotificationAt.formatted(date: .omitted, time: .standard))
            } else {
                rowText("Last alert", "None")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sensitivity")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                rowText("Lean threshold", "\(Int(vm.forwardLeanThresholdDegrees))°")
                Slider(value: $vm.forwardLeanThresholdDegrees, in: 6...24, step: 1)
            }

            VStack(alignment: .leading, spacing: 8) {
                rowText("Sustain duration", "\(Int(vm.sustainedSeconds)) sec")
                Slider(value: $vm.sustainedSeconds, in: 3...20, step: 1)
            }

            VStack(alignment: .leading, spacing: 8) {
                rowText("Reminder interval", "\(Int(vm.reminderIntervalSeconds)) sec")
                Slider(value: $vm.reminderIntervalSeconds, in: 8...120, step: 1)
            }

            Text("Tip: Place the phone on your chest pocket or desk stand, calibrate while upright, then start monitoring.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func rowText(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
    }

    private func formatAngle(_ radians: Double) -> String {
        String(format: "%.1f°", radians * 180 / .pi)
    }

    private func formatSigned(_ value: Double) -> String {
        String(format: value >= 0 ? "+%.1f" : "%.1f", value)
    }
}
