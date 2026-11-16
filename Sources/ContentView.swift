import SwiftUI

/// App root: shows onboarding once, then the main tab experience.
struct ContentView: View {
    @EnvironmentObject private var viewModel: PostureViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: AppTab = .today
    @State private var isCalibrating = false

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                mainTabs
                    .transition(.opacity)
            } else {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
        .tint(Theme.Colors.brand)
        .task {
            #if DEBUG
            applyDemoNavigation()
            #endif
            await viewModel.refreshNotificationStatus()
        }
        .onOpenURL(perform: handleDeepLink)
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            TodayView(onCalibrate: { isCalibrating = true }, onOpenInsights: { selectedTab = .insights })
                .tabItem { Label("Today", systemImage: "figure.stand") }
                .tag(AppTab.today)

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
                .tag(AppTab.insights)

            SettingsView(onCalibrate: { isCalibrating = true })
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .sheet(isPresented: $isCalibrating) {
            CalibrationView(mode: .sheet) { isCalibrating = false }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    #if DEBUG
    /// `-demoTab insights|settings` and `-demoCalibrate YES` open a screen directly at launch,
    /// avoiding the system "Open in…" prompt that deep links trigger during screenshot runs.
    private func applyDemoNavigation() {
        let defaults = UserDefaults.standard
        switch defaults.string(forKey: "demoTab") {
        case "insights": selectedTab = .insights
        case "settings": selectedTab = .settings
        default: break
        }
        if defaults.bool(forKey: "demoCalibrate") { isCalibrating = true }
    }
    #endif

    private func handleDeepLink(_ url: URL) {
        guard hasCompletedOnboarding else { return }
        switch url.host {
        case "settings":
            selectedTab = .settings
        case "insights":
            selectedTab = .insights
        case "calibrate":
            selectedTab = .today
            if !viewModel.isMonitoring { isCalibrating = true }
        default:
            selectedTab = .today
        }
    }
}

enum AppTab: Hashable {
    case today, insights, settings
}
