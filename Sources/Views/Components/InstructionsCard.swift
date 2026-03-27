import SwiftUI

struct InstructionsCard: View {
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                colors: [
                    Color.indigo.opacity(0.12),
                    Color.purple.opacity(0.08),
                    Color.blue.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                HStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.3), .pink.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("QUICK START")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(.orange.opacity(0.8))
                            .tracking(1.5)
                        
                        Text("Setup Guide")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.Colors.text)
                    }
                }
                
                VStack(spacing: Theme.Spacing.md) {
                    PremiumInstructionStep(
                        number: 1,
                        title: "Position Device",
                        description: "Chest pocket or stand facing you",
                        color: .blue
                    )
                    
                    PremiumInstructionStep(
                        number: 2,
                        title: "Sit Upright",
                        description: "Shoulders relaxed, back straight",
                        color: .green
                    )
                    
                    PremiumInstructionStep(
                        number: 3,
                        title: "Calibrate Baseline",
                        description: "Tap calibrate while sitting properly",
                        color: .purple
                    )
                    
                    PremiumInstructionStep(
                        number: 4,
                        title: "Start Monitoring",
                        description: "Get alerts when slouching detected",
                        color: .orange
                    )
                }
            }
            .padding(Theme.Spacing.xl)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xl * 1.5, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl * 1.5, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.indigo.opacity(0.3), .purple.opacity(0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        }
        .shadow(color: .indigo.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

struct PremiumInstructionStep: View {
    let number: Int
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Number badge with neon effect
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.6), color.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 48, height: 48)
                
                Text("\(number)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.text)
                
                Text(description)
                    .font(.system(size: 13, design: .default))
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        }
    }
}
