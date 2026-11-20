#!/bin/zsh
# Captures raw App Store screenshots from a booted simulator using the app's Debug demo mode.
# usage: AppStore/capture.sh <device-udid> <path/to/PostureHelp.app (Debug, simulator)> <prefix>
# Writes AppStore/raw/<prefix>_<scene>.png
set -e
D=$1; APP=$2; P=$3
OUT="$(cd "$(dirname "$0")" && pwd)/raw"; mkdir -p "$OUT"
BID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$APP/Info.plist")
xcrun simctl status_bar $D override --time "9:41" --batteryState charged --batteryLevel 100 --cellularMode active --cellularBars 4 --wifiBars 3 --dataNetwork wifi
xcrun simctl install $D "$APP"
shot() { sleep $1; xcrun simctl io $D screenshot --type=png "$OUT/${P}_$2.png" >/dev/null 2>&1; echo "captured ${P}_$2"; }
run()  { xcrun simctl terminate $D $BID 2>/dev/null || true; sleep 1; xcrun simctl launch $D $BID -hasCompletedOnboarding YES -demoMode YES "$@" >/dev/null; }
onb()  { xcrun simctl terminate $D $BID 2>/dev/null || true; sleep 1; xcrun simctl launch $D $BID -hasCompletedOnboarding NO -demoMode YES -demoIdle YES -demoOnboardingStep $1 >/dev/null; }

xcrun simctl ui $D appearance light
run -demoLean 6;                      shot 7  1_today_good
run -demoLean 19;                     shot 11 2_today_alert
run -demoLean 6 -demoTab insights;    shot 5  3_insights
run -demoIdle YES -demoCalibrate YES; shot 5  4_calibrate
run -demoLean 6 -demoTab settings;    shot 5  5_settings
onb 0;                                shot 5  6_welcome
onb 1;                                shot 5  7_how_it_works
onb 2;                                shot 5  8_reminders
xcrun simctl ui $D appearance dark
run -demoLean 6;                      shot 7  9_today_dark
xcrun simctl ui $D appearance light
xcrun simctl terminate $D $BID 2>/dev/null || true
