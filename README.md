# ios-coremotion-20260304-140650-6060c8

Minimal SwiftUI iOS demo that uses **CoreMotion** to stream live device motion values.

## Feature shown
- Uses `CMMotionManager` to start/stop `deviceMotion` updates.
- Displays attitude values (`pitch`, `roll`, `yaw`) in real time.
- Displays user acceleration (`x`, `y`, `z`) to make physical movement visible.

## Run
1. Open `ios-coremotion-20260304-140650-6060c8.xcodeproj` in Xcode.
2. Run on a real iPhone/iPad for live motion values (simulator may report unavailable).

## Apple documentation used
- https://developer.apple.com/documentation/coremotion
- https://developer.apple.com/documentation/coremotion/cmmotionmanager
- https://developer.apple.com/documentation/coremotion/getting-processed-device-motion-data
