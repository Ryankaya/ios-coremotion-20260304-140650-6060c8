import SwiftUI

struct ActivityStatusCard: View {
    let isUserActive: Bool
    let isHumanHolding: Bool
    let isScreenLocked: Bool
    let isInPocket: Bool
    let isMonitoring: Bool
    let onlyAlertWhenActive: Bool
    let detectDeviceOnTable: Bool
    
    var body: some View {
        ZStack {
            // Gradient background based on activity state
            LinearGradient(
                colors: [activityColor.opacity(0.15), activityColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: Theme.Spacing.md) {
                // Icon with modern design
                ZStack {
                    Circle()
                        .fill(activityColor.opacity(0.2))
                        .frame(width: 64, height: 64)
                    
                    Circle()
                        .stroke(activityColor.opacity(0.4), lineWidth: 2)
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: activityIcon)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [activityColor, activityColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("SYSTEM")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(activityColor.opacity(0.7))
                            .tracking(1)
                        
                        if isMonitoring {
                            Circle()
                                .fill(activityColor)
                                .frame(width: 6, height: 6)
                        }
                    }
                    
                    Text(activityStatus)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.text)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 0)
            }
            .padding(Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 90)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xl, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [activityColor.opacity(0.3), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
        .shadow(color: activityColor.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var activityIcon: String {
        if !isMonitoring {
            return "moon.zzz.fill"
        }
        
        if isInPocket {
            return "figure.stand.line.dotted.figure.stand"
        }
        
        if detectDeviceOnTable && !isHumanHolding {
            return "iphone"
        }
        
        return isUserActive ? "figure.walk" : "figure.stand"
    }
    
    private var activityColor: Color {
        if !isMonitoring {
            return Color.gray
        }
        
        if isInPocket {
            return Color.orange
        }
        
        if detectDeviceOnTable && !isHumanHolding {
            return Color.red
        }
        
        return isUserActive ? Theme.Colors.success : Theme.Colors.warning
    }
    
    private var activityStatus: String {
        if !isMonitoring {
            return "Not monitoring"
        }
        
        if isInPocket {
            return "In pocket - alerts paused"
        }
        
        if detectDeviceOnTable && !isHumanHolding {
            return "Device on table - alerts paused"
        }
        
        if onlyAlertWhenActive {
            return isUserActive ? "Active - alerts enabled (works in background)" : "Inactive - alerts paused"
        } else {
            return "Monitoring continuously (works in background)"
        }
    }
}
