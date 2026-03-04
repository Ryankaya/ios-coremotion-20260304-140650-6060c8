import CoreMotion
import SwiftUI

final class MotionViewModel: ObservableObject {
    @Published var status: String = "Ready"
    @Published var isRunning: Bool = false
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    @Published var yaw: Double = 0
    @Published var x: Double = 0
    @Published var y: Double = 0
    @Published var z: Double = 0

    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    func start() {
        guard motionManager.isDeviceMotionAvailable else {
            status = "Device motion is unavailable on this device/simulator."
            isRunning = false
            return
        }

        motionManager.deviceMotionUpdateInterval = 0.1
        status = "Streaming device motion..."

        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let self else { return }

            if let error {
                DispatchQueue.main.async {
                    self.status = "Error: \(error.localizedDescription)"
                    self.isRunning = false
                }
                return
            }

            guard let motion else { return }

            DispatchQueue.main.async {
                self.pitch = motion.attitude.pitch
                self.roll = motion.attitude.roll
                self.yaw = motion.attitude.yaw
                self.x = motion.userAcceleration.x
                self.y = motion.userAcceleration.y
                self.z = motion.userAcceleration.z
                self.isRunning = true
            }
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        isRunning = false
        status = "Motion updates stopped."
    }
}

struct ContentView: View {
    @StateObject private var vm = MotionViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("CoreMotion Live Demo")
                    .font(.title2.weight(.semibold))

                Text(vm.status)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                metricGrid

                HStack(spacing: 12) {
                    Button(vm.isRunning ? "Restart" : "Start") {
                        vm.start()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Stop") {
                        vm.stop()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!vm.isRunning)
                }
            }
            .padding()
            .navigationTitle("CoreMotion")
        }
    }

    private var metricGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
            row("Pitch", vm.pitch)
            row("Roll", vm.roll)
            row("Yaw", vm.yaw)
            row("Accel X", vm.x)
            row("Accel Y", vm.y)
            row("Accel Z", vm.z)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func row(_ name: String, _ value: Double) -> some View {
        GridRow {
            Text(name)
                .fontWeight(.medium)
            Text(String(format: "%.3f", value))
                .monospacedDigit()
        }
    }
}

