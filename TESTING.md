# Testing Guide - Posture Help

## Requirements for Testing

### Device Requirements
- **Real iOS Device Required**: Motion sensors are not available in the iOS Simulator
- iPhone or iPad with gyroscope and accelerometer
- iOS 14.0 or later

### Privacy Permissions
The app will request:
1. **Motion & Fitness Access**: Required to read device orientation
2. **Notifications**: Optional, for posture alerts

## How to Test the App

### 1. Initial Setup
1. Deploy the app to a real iPhone/iPad
2. Launch the app
3. You'll see the instructions card on first launch

### 2. Grant Permissions
- Tap "Enable Notifications" to allow alerts
- Motion permission is requested automatically when you start monitoring

### 3. Start Monitoring

#### Quick Start (Auto-Calibration)
1. Sit upright with good posture
2. Position your device in a chest pocket or on a stand
3. Tap "Start Monitoring"
4. The app will auto-calibrate using your current position
5. You're now being monitored!

#### Manual Calibration
1. Position your device
2. Sit in your ideal posture
3. Tap "Calibrate Baseline"
4. Wait 1 second for calibration
5. Tap "Start Monitoring"

### 4. Testing Posture Detection

#### Test Good Posture
- Sit upright with shoulders back
- Status should show: "Good Posture" (Green)
- No alerts should trigger

#### Test Forward Lean (Warning)
- Lean forward slightly (6-12 degrees)
- Status should show: "Leaning forward detected" (Orange)
- After 8 seconds of sustained lean, you'll get an alert

#### Test Poor Posture (Alert)
- Lean forward more than 12 degrees
- Keep leaning for 8+ seconds
- You should feel haptic feedback (vibration pattern)
- If notifications enabled, you'll see a notification
- Alert won't repeat for 20 seconds (cooldown)

### 5. Adjusting Sensitivity

You can customize the detection:

**Lean Threshold (6-24°)**
- Lower = More sensitive (alerts on slight lean)
- Higher = Less sensitive (only alerts on major slouch)
- Default: 12°

**Sustain Duration (3-20 sec)**
- How long you must lean before alerting
- Default: 8 seconds

**Alert Interval (8-120 sec)**
- Cooldown between repeated alerts
- Default: 20 seconds

### 6. Stopping/Restarting

- **Stop**: Stops monitoring, keeps baseline
- **Restart**: Restarts monitoring with same baseline
- **Recalibrate**: Sets new baseline (only when stopped)

## Expected Behavior

### Status States

| State | Color | Icon | Meaning |
|-------|-------|------|---------|
| Unknown | Gray | ? | Not monitoring or no data |
| Good Posture | Green | ✓ | Posture is within threshold |
| Lean Detected | Orange | ! | Leaning but not sustained |
| Poor Posture | Red | ⚠ | Sustained poor posture, alert triggered |

### Metrics Display

When monitoring, you'll see:
- **Current Pitch**: Real-time device angle
- **Baseline Pitch**: Your calibrated good posture
- **Lean Delta**: Difference from baseline (negative = forward lean)
- **Last Alert**: Time of last posture alert

### Haptic Feedback

The app uses a distinctive 3-part haptic pattern:
1. Sharp initial tap
2. Medium continuous vibration (0.25s)
3. Two final taps with varying intensity

## Troubleshooting

### "Device motion is unavailable"
- You're running in the iOS Simulator
- Solution: Deploy to a real device

### Motion not responding
- Check that motion permission is granted
- Try force-quitting and relaunching the app
- Recalibrate baseline

### No notifications appearing
- Check notification permission in Settings > Posture Help
- Ensure you tapped "Enable Notifications" in the app
- Notifications won't show if app is in foreground (by design)

### False alerts
- Your baseline might be off - recalibrate
- Increase "Lean Threshold" for less sensitivity
- Increase "Sustain Duration" to require longer slouch

### No alerts when slouching
- Ensure you're monitoring (not just calibrated)
- Check that you've leaned for the full "Sustain Duration"
- Wait for cooldown period to expire
- Lower "Lean Threshold" for more sensitivity

## Best Practices for Real-World Use

1. **Device Placement**: 
   - Chest pocket works best
   - Or use a phone stand on your desk
   - Keep device vertical and facing you

2. **Calibration**:
   - Calibrate while sitting at your desk
   - Use your best posture (not slouching)
   - Recalibrate if you move your device

3. **Settings**:
   - Start with defaults
   - Adjust based on your comfort
   - Higher threshold = fewer false positives

4. **Daily Use**:
   - Start monitoring at beginning of work
   - Keep device charged
   - Background monitoring works when screen is off

## Performance Notes

- Battery impact: Minimal (CoreMotion is very efficient)
- Updates: 10 times per second (0.1s interval)
- Memory: Low footprint
- Background: Continues when app is backgrounded
