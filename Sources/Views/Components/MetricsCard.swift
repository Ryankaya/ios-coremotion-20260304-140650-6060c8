import SwiftUI

struct MetricsCard: View {
    let metrics: PostureMetrics
    
    var body: some View {
        ZStack {
            // Animated tech background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.05),
                    Color.cyan.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                HStack(spacing: Theme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.3), .blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LIVE METRICS")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(.cyan.opacity(0.8))
                            .tracking(1.5)
                        
                        Text("Realtime Data")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.Colors.text)
                    }
                    
                    Spacer()
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Theme.Spacing.md) {
                    EnhancedMetricItem(
                        label: "CURRENT",
                        value: metrics.currentPitch.toDegreesString(),
                        icon: "arrow.up.and.down.circle.fill",
                        color: .blue
                    )
                    
                    EnhancedMetricItem(
                        label: "BASELINE",
                        value: metrics.baselinePitch.toDegreesString(),
                        icon: "scope",
                        color: .green
                    )
                    
                    EnhancedMetricItem(
                        label: "LEAN ANGLE",
                        value: "\(metrics.leanDeltaDegrees.toSignedString())°",
                        icon: "angle",
                        color: metrics.leanDeltaDegrees < -6 ? .orange : .purple
                    )
                    
                    if let lastAlert = metrics.lastAlertDate {
                        EnhancedMetricItem(
                            label: "LAST ALERT",
                            value: lastAlert.timeAgoString(),
                            icon: "bell.badge.fill",
                            color: .red
                        )
                    }
                }
            }
            .padding(Theme.Spacing.xl)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xl * 1.5, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl * 1.5, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.cyan.opacity(0.3), .purple.opacity(0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        }
        .shadow(color: .cyan.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Enhanced Metric Item with Neon Effect
struct EnhancedMetricItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Neon glow effect
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(color.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.4), color.opacity(0.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(color)
                    
                    Text(label)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(color.opacity(0.7))
                        .tracking(0.5)
                }
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(Theme.Spacing.md)
        }
        .frame(height: 85)
        .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}
