import Testing
@testable import PostureHelp

struct PostureMetricsTests {

    @Test
    func isBaselineSet_isFalse_onAFreshSession() {
        let metrics = PostureMetrics()
        #expect(metrics.isBaselineSet == false)
    }

    @Test
    func isBaselineSet_isTrue_onceCalibrated() {
        var metrics = PostureMetrics()
        metrics.baselinePitch = 0.42
        #expect(metrics.isBaselineSet == true)
    }
}

struct DeviceStateTests {

    @Test
    func stateDescription_prioritizesScreenLocked_overInPocket() {
        let state = DeviceState(isScreenLocked: true, isInPocket: true, canShowAlerts: false)
        #expect(state.stateDescription == "Screen locked")
    }

    @Test
    func stateDescription_reportsInPocket_whenUnlockedButCovered() {
        let state = DeviceState(isScreenLocked: false, isInPocket: true, canShowAlerts: false)
        #expect(state.stateDescription == "In pocket")
    }

    @Test
    func stateDescription_reportsActive_whenUnlockedAndNotInPocket() {
        let state = DeviceState(isScreenLocked: false, isInPocket: false, canShowAlerts: true)
        #expect(state.stateDescription == "Active")
    }
}
