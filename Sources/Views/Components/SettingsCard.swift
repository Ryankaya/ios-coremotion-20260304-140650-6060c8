import SwiftUI

struct SettingsCard: View {
    @Binding var configuration: PostureConfiguration
    @Binding var onlyAlertWhenActive: Bool
    @Binding var detectDeviceOnTable: Bool
    @Binding var onlyAlertInPortrait: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Detection Settings")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Text("Customize when and how you receive posture alerts")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            
            // Toggle Settings
            VStack(spacing: Theme.Spacing.sm) {
                ModernToggle(
                    icon: "brain.head.profile",
                    title: "Smart Alerts",
                    description: "Only alert when actively using device",
                    isOn: $onlyAlertWhenActive,
                    color: .blue
                )
                
                ModernToggle(
                    icon: "waveform",
                    title: "Detect Device on Table",
                    description: "Skip alerts when device is perfectly still",
                    isOn: $detectDeviceOnTable,
                    color: .purple
                )
                
                ModernToggle(
                    icon: "iphone.gen3",
                    title: "Portrait Mode Only",
                    description: "Only when vertical (TikTok/Reels/Shorts)",
                    isOn: $onlyAlertInPortrait,
                    color: .indigo
                )
            }
            
            Divider()
                .padding(.vertical, Theme.Spacing.xs)
            
            // Sliders
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Sensitivity")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Adjust thresholds for posture detection")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            
            VStack(spacing: Theme.Spacing.lg) {
                ModernSettingSlider(
                    label: "Lean Threshold",
                    value: $configuration.forwardLeanThresholdDegrees,
                    range: 6...24,
                    step: 1,
                    unit: "°",
                    icon: "angle",
                    color: .blue
                )
                
                ModernSettingSlider(
                    label: "Sustain Duration",
                    value: $configuration.sustainedSeconds,
                    range: 3...20,
                    step: 1,
                    unit: "sec",
                    icon: "timer",
                    color: .orange
                )
                
                ModernSettingSlider(
                    label: "Alert Interval",
                    value: $configuration.reminderIntervalSeconds,
                    range: 8...120,
                    step: 1,
                    unit: "sec",
                    icon: "bell.badge",
                    color: .purple
                )
            }
            
            // Tip
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                
                Text("Calibrate while sitting straight for best results")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        }
        .padding(Theme.Spacing.lg)
        .glassCardStyle()
    }
}

// MARK: - Modern Toggle Component
struct ModernToggle: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.text)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(Theme.Spacing.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }
}

// MARK: - Modern Setting Slider
struct ModernSettingSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(color)
                    
                    Text(label)
                        .font(Theme.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.Colors.text)
                }
                
                Spacer()
                
                Text("\(Int(value)) \(unit)")
                    .font(.system(.callout, design: .rounded).monospacedDigit())
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            
            Slider(value: $value, in: range, step: step)
                .tint(color)
        }
        .padding(Theme.Spacing.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }
}
