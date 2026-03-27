# Background Monitoring & Smart Alerts

## Overview

Posture Help now includes advanced background monitoring and intelligent user activity detection. The app continues to track your posture even when the screen is off or you're using other apps, and only alerts you when you're actually using your device.

## Key Features

### 1. Background Monitoring

**How It Works:**
- Motion sensors continue tracking when the app is backgrounded
- Monitoring persists even when your screen is locked
- No need to keep the app open on screen

**Technical Implementation:**
- Uses iOS Background Tasks framework
- Leverages CoreMotion's efficient background operation
- Minimal battery impact

**What This Means:**
- Set it once in the morning, forget about it
- Get posture alerts throughout your workday
- No need to actively manage the app

### 2. Smart Activity Detection

**The Problem We Solved:**
Traditional posture apps alert you even when you're:
- Walking to get coffee
- Standing in a meeting
- Not using your device at all

**Our Solution - Smart Alerts:**
The app now detects when you're actually using your device and only alerts during those times.

**Activity Detection Methods:**

1. **Motion Activity Tracking**
   - Uses CMMotionActivityManager to detect:
     - Stationary (sitting at desk) ✅ Alerts enabled
     - Walking 🚶 Alerts paused
     - Running 🏃 Alerts paused
   
2. **App State Detection**
   - Monitors when app comes to foreground
   - Assumes active use when you interact with your device
   
3. **Time-Based Heuristics**
   - Considers you active for 30 seconds after last interaction
   - Automatically pauses alerts when inactive

### 3. Configurable Smart Alerts

**Toggle Options:**

**Smart Alerts ON (Recommended)**
- Only receive notifications when actively using your device
- Prevents annoying alerts when walking or away from desk
- More natural user experience
- Better battery life

**Smart Alerts OFF**
- Continuous monitoring regardless of activity
- Alerts even when walking or standing
- Use if you want constant posture awareness

## How to Use

### Setup for Background Monitoring

1. **Start Monitoring**
   ```
   Open app → Sit upright → Tap "Start Monitoring"
   ```

2. **Lock Screen or Switch Apps**
   - The app continues monitoring in background
   - You'll receive notifications for poor posture
   - Motion tracking continues seamlessly

3. **Smart Alerts (Default: ON)**
   - Go to Settings card
   - Toggle "Smart Alerts"
   - When ON: Only alerts when device is in active use
   - When OFF: Alerts regardless of activity

### Understanding Activity Status

The Activity Status card shows your current state:

| Icon | Status | Color | Meaning |
|------|--------|-------|---------|
| 🚶 | Active | Green | Using device, alerts enabled |
| 🧍 | Inactive | Orange | Not using device, alerts paused |
| 💤 | Not Monitoring | Gray | Monitoring stopped |

**Active State Indicators:**
- App is in foreground
- Recently interacted with device
- Device is stationary (sitting at desk)

**Inactive State Indicators:**
- Walking or moving
- Haven't interacted recently (30+ seconds)
- Device motion suggests not at desk

## Permissions Required

### Motion & Fitness Access
**Why:** Detect user activity patterns
**Privacy:** All processing happens locally on device
**When Asked:** First time you start monitoring

### Notifications
**Why:** Alert you about poor posture
**Privacy:** No data leaves your device
**When Asked:** When you tap "Enable Notifications"

## Battery Impact

### Optimized for All-Day Use

**Power Consumption:**
- CoreMotion: ~1-2% per hour (very efficient)
- Background processing: Minimal CPU usage
- Smart alerts reduce unnecessary wake-ups

**Battery Saving Tips:**
1. Enable "Smart Alerts" to reduce processing
2. Increase "Alert Interval" (cooldown time)
3. Increase "Sustain Duration" (less frequent checks)

**Expected Battery Life:**
- Full day monitoring: ~5-10% total battery use
- Comparable to fitness tracking apps
- Much less than music or video streaming

## Privacy & Data

### What We Track
- Device orientation (pitch angle)
- Motion activity (stationary/walking/running)
- App state (foreground/background)

### What We DON'T Track
- Location
- Personal information
- Usage patterns of other apps
- Any data sent to servers

### Data Storage
- All data stays on your device
- No cloud sync
- No analytics or tracking
- Completely private

## Troubleshooting

### Background Monitoring Not Working

**Check Permissions:**
1. Settings → Posture Help → Motion & Fitness
2. Ensure "Motion & Fitness" is enabled
3. Restart the app

**Verify Background Refresh:**
1. Settings → General → Background App Refresh
2. Ensure it's ON for Posture Help
3. Enable "Background App Refresh" globally

**Force Restart:**
1. Force quit the app
2. Restart your device
3. Launch app and start monitoring

### Smart Alerts Too Aggressive

**You're getting alerts when walking:**
- This is a bug - check Activity Status card
- Should show "Inactive" when walking
- Try toggling Smart Alerts OFF then ON

**Increase Detection Threshold:**
- Smart Alerts uses motion patterns
- May need 10-15 seconds to detect walking
- Brief walks might still trigger alerts

### Smart Alerts Too Passive

**Not getting alerts when working:**
- Check Activity Status shows "Active"
- Verify you're stationary (not moving around)
- Try toggling Smart Alerts OFF temporarily

**Manual Override:**
- Turn OFF "Smart Alerts" in settings
- You'll get alerts regardless of activity
- Useful for testing or different workflows

## Best Practices

### For Office Work
1. **Enable Smart Alerts** ✅
2. **Start monitoring** when you sit down
3. **Leave app running** in background
4. **Let it work** - no need to check constantly

### For Meetings
1. **Keep monitoring ON** - it auto-pauses when walking
2. **Alerts pause** when you stand up
3. **Resume automatically** when you sit back down

### For Focused Work
1. **Increase Alert Interval** (60-120 seconds)
2. **Keep Smart Alerts ON**
3. **Reduce Lean Threshold** for better posture

### For Testing/Calibration
1. **Turn OFF Smart Alerts** temporarily
2. **Lower Alert Interval** (8-10 seconds)
3. **Test by leaning** forward deliberately
4. **Re-enable** Smart Alerts when done

## Technical Details

### Background Task Lifecycle

```
App Enters Background
    ↓
Begin Background Task
    ↓
Motion Updates Continue
    ↓
Smart Activity Detection Active
    ↓
Poor Posture Detected
    ↓
Check User Activity
    ↓
User Active? → Send Notification
User Inactive? → Skip Notification
    ↓
Continue Monitoring
```

### Activity Detection Algorithm

1. **Motion Activity (Primary)**
   - CMMotionActivityManager provides real-time activity
   - Stationary = Active
   - Walking/Running = Inactive

2. **App State (Secondary)**
   - Foreground = Active
   - Background but recently active = Active
   - Background > 30s = Inactive

3. **Combined Logic**
   ```
   isActive = (isStationary && withinTimeout) || isForeground
   ```

### Performance Characteristics

- **Motion Update Rate:** 10 Hz (every 0.1 seconds)
- **Activity Check Rate:** Every 5 seconds
- **Inactivity Timeout:** 30 seconds
- **Background Task Duration:** Indefinite (motion-based)

## Future Enhancements

Potential features being considered:

- [ ] ML-based posture pattern learning
- [ ] Time-of-day based sensitivity
- [ ] Calendar integration (pause during meetings)
- [ ] Health app integration
- [ ] Weekly posture reports
- [ ] Custom alert sounds

## Support

### Getting Help
- Check TESTING.md for device setup
- Review ARCHITECTURE.md for technical details
- Ensure running on real device (not simulator)

### Known Limitations
- Simulator doesn't support motion sensors
- Background refresh limited by iOS to ~15 min intervals
- Activity detection requires Motion & Fitness permission
- May not work while driving (detected as movement)
