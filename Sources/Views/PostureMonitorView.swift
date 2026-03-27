import SwiftUI

struct PostureMonitorView: View {
    @StateObject private var viewModel = PostureViewModel()
    @State private var selectedView: NavigationItem? = .monitor
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    enum NavigationItem: String, CaseIterable, Identifiable {
        case monitor = "Monitor"
        case settings = "Settings"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .monitor: return "figure.stand"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        if horizontalSizeClass == .regular {
            // iPad: Split view with sidebar
            NavigationSplitView(columnVisibility: $columnVisibility) {
                List(NavigationItem.allCases, selection: $selectedView) { item in
                    NavigationLink(value: item) {
                        Label(item.rawValue, systemImage: item.icon)
                    }
                }
                .navigationTitle("Posture Help")
            } detail: {
                detailView
            }
        } else {
            // iPhone: Tab view
            TabView {
                NavigationStack {
                    mainContentView
                        .navigationTitle("Posture Help")
                        .navigationBarTitleDisplayMode(.large)
                }
                .tabItem {
                    Label("Monitor", systemImage: "figure.stand")
                }
                
                NavigationStack {
                    settingsView
                        .navigationTitle("Settings")
                        .navigationBarTitleDisplayMode(.large)
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch selectedView {
        case .monitor:
            NavigationStack {
                mainContentView
                    .navigationTitle("Monitor")
                    .navigationBarTitleDisplayMode(.large)
            }
        case .settings:
            NavigationStack {
                settingsView
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.large)
            }
        case .none:
            NavigationStack {
                mainContentView
                    .navigationTitle("Monitor")
                    .navigationBarTitleDisplayMode(.large)
            }
        }
    }
    
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if !viewModel.isMonitoring && !viewModel.metrics.isBaselineSet {
                    InstructionsCard()
                }
                
                PostureStatusCard(
                    postureState: viewModel.metrics.postureState,
                    leanDelta: viewModel.metrics.leanDeltaDegrees
                )
                
                ActivityStatusCard(
                    isUserActive: viewModel.isUserActive,
                    isHumanHolding: viewModel.isHumanHolding,
                    isScreenLocked: viewModel.isScreenLocked,
                    isInPocket: viewModel.isInPocket,
                    isMonitoring: viewModel.isMonitoring,
                    onlyAlertWhenActive: viewModel.onlyAlertWhenActive,
                    detectDeviceOnTable: viewModel.detectDeviceOnTable
                )
                
                quickSettingsView
                
                controlButtonsView
                
                if viewModel.isMonitoring || viewModel.metrics.isBaselineSet {
                    MetricsCard(metrics: viewModel.metrics)
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
    }
    
    private var settingsView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                SettingsCard(
                    configuration: $viewModel.configuration,
                    onlyAlertWhenActive: $viewModel.onlyAlertWhenActive,
                    detectDeviceOnTable: $viewModel.detectDeviceOnTable,
                    onlyAlertInPortrait: $viewModel.onlyAlertInPortrait
                )
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
    }
    
    private var quickSettingsView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.Colors.primary)
                Text("Quick Settings")
                    .font(Theme.Typography.headline)
            }
            
            VStack(spacing: Theme.Spacing.sm) {
                QuickSettingToggle(
                    icon: "brain.head.profile",
                    title: "Smart Alerts",
                    isOn: $viewModel.onlyAlertWhenActive,
                    color: .blue
                )
                
                QuickSettingToggle(
                    icon: "waveform",
                    title: "Detect Table",
                    isOn: $viewModel.detectDeviceOnTable,
                    color: .purple
                )
                
                QuickSettingToggle(
                    icon: "iphone.gen3",
                    title: "Portrait Only",
                    isOn: $viewModel.onlyAlertInPortrait,
                    color: .indigo
                )
            }
        }
        .padding(Theme.Spacing.md)
        .glassCardStyle()
    }
    
    private var controlButtonsView: some View {
        VStack(spacing: Theme.Spacing.md) {
            if viewModel.isMonitoring {
                HStack(spacing: Theme.Spacing.md) {
                    ModernActionButton(
                        title: "Stop",
                        icon: "stop.circle.fill",
                        color: .gray,
                        action: viewModel.stopMonitoring
                    )
                    
                    ModernActionButton(
                        title: "Restart",
                        icon: "arrow.clockwise",
                        color: .blue,
                        action: viewModel.startMonitoring
                    )
                }
            } else {
                ModernActionButton(
                    title: "Start Monitoring",
                    icon: "play.circle.fill",
                    color: .green,
                    fullWidth: true,
                    action: viewModel.startMonitoring
                )
            }
            
            ModernActionButton(
                title: viewModel.metrics.isBaselineSet ? "Recalibrate" : "Calibrate",
                icon: "scope",
                color: .purple,
                fullWidth: true,
                action: viewModel.calibrateBaseline,
                isDisabled: viewModel.isMonitoring
            )
            
            if !viewModel.notificationsEnabled {
                ModernActionButton(
                    title: "Enable Notifications",
                    icon: "bell.badge.fill",
                    color: .orange,
                    fullWidth: true,
                    action: {
                        Task {
                            await viewModel.requestNotifications()
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Quick Setting Toggle Component
struct QuickSettingToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isOn ? color : .gray)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isOn ? color.opacity(0.15) : Color.gray.opacity(0.1))
                    )
                
                Text(title)
                    .font(Theme.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.Colors.text)
                
                Spacer()
                
                ZStack {
                    Capsule()
                        .fill(isOn ? color : Color.gray.opacity(0.3))
                        .frame(width: 44, height: 26)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .offset(x: isOn ? 9 : -9)
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Action Button Component
struct ModernActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var fullWidth: Bool = false
    let action: () -> Void
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                
                Text(title)
                    .font(Theme.Typography.callout)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                LinearGradient(
                    colors: isDisabled ? [.gray.opacity(0.5), .gray.opacity(0.3)] : [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: isDisabled ? .clear : color.opacity(0.3), radius: 8, x: 0, y: 4)
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            }
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
    }
}
