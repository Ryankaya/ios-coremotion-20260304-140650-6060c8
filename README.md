# ios-coremotion-20260304-140650-6060c8

Smart Posture Coach built with SwiftUI + CoreMotion.

## What it does
- Monitors device `pitch` in real time using `CMMotionManager`.
- Lets the user calibrate a neutral baseline while sitting straight.
- Detects sustained forward lean (angle threshold + duration threshold).
- Sends a local notification when forward lean persists too long.

## How to use
1. Open `ios-coremotion-20260304-140650-6060c8.xcodeproj` in Xcode.
2. Run on a real iPhone/iPad (simulator motion support is limited).
3. Tap **Enable Notifications** once.
4. Sit upright and tap **Calibrate Baseline**.
5. Tap **Start** to begin monitoring.
6. If lean is above threshold for the configured duration, the app sends a posture reminder.

## Notes
- Works best when device orientation is stable (for example chest pocket, shirt clip, or desk stand).
- Foreground notifications are shown as banners.

## Apple documentation used
- https://developer.apple.com/documentation/coremotion
- https://developer.apple.com/documentation/coremotion/cmmotionmanager
- https://developer.apple.com/documentation/coremotion/getting-processed-device-motion-data
- https://developer.apple.com/documentation/usernotifications/unusernotificationcenter
