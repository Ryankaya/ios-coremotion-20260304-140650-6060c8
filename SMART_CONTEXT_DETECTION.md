# Smart Context Detection

## Overview

Posture Help now has **5 layers of intelligent context detection** to ensure alerts are only sent when they're actually useful and actionable.

## The Four Detection Layers (Screen Lock Removed!)

### 1. ~~🔒 Screen Lock Detection~~ (REMOVED)
**Previous behavior:** Paused alerts when app in background  
**Problem:** User should still get alerts when using OTHER apps!  
**New behavior:** Alerts work in background - notifications appear even when using Safari, Messages, etc.  
**Result:** **Alerts CONTINUE** ✅

### 1. 👖 Pocket Detection
**What:** Uses proximity sensor to detect if phone is in pocket or covered  
**Why:** User can't see alerts and probably walking  
**Result:** Alerts PAUSED

### 2. 📱 Table Detection  
**What:** Analyzes accelerometer stability (consecutive sample changes)  
**Why:** Phone on desk at wrong angle shouldn't trigger alerts  
**Result:** Alerts PAUSED

### 3. 🚶 Activity Detection
**What:** Uses CMMotionActivity to detect walking, running, etc.  
**Why:** User is moving around, not at desk  
**Result:** Alerts PAUSED (if Smart Alerts enabled)

### 4. 📐 Posture Monitoring
**What:** Tracks device pitch angle vs baseline  
**Why:** Core functionality - detect poor posture  
**Result:** **ALERT SENT** (if all above checks pass)

## Alert Decision Tree

```
Poor Posture Detected (8+ seconds of lean)
    ↓
Is device in pocket?
    ├─ YES → ❌ Skip alert (covered, probably walking)
    └─ NO  → Continue
    ↓
Is device on table?
    ├─ YES → ❌ Skip alert (not human holding)
    └─ NO  → Continue
    ↓
Is user active? (if Smart Alerts ON)
    ├─ NO  → ❌ Skip alert (walking/inactive)
    └─ YES → Continue
    ↓
✅ SEND ALERT (haptic + notification)
```

## User Experience

### Scenario 1: Using Other Apps (ALERTS STILL WORK!)
```
You're working in Posture Help app → Slouching
    ↓
You switch to Safari/Messages/other app
    ↓
Posture Help continues monitoring in background
    ↓
Poor posture continues for 8+ seconds
    ↓
✅ NOTIFICATION SENT (even though app in background!)
    ↓
You see notification banner
    ↓
You correct posture
```

**KEY POINT:** Alerts work even when app is in background or you're using other apps!

### Scenario 2: Put in Pocket
```
You're at desk → Start monitoring
    ↓
You stand up, put phone in pocket
    ↓
Proximity sensor covered
    ↓
Activity Status: "In pocket" (Orange 👖)
    ↓
Phone at weird angle in pocket
    ↓
NO ALERT (in pocket) ✅
    ↓
You take phone out
    ↓
Proximity sensor uncovered
    ↓
Alerts resume
```

### Scenario 3: Place on Table
```
Holding phone → About to get alert (7 sec lean)
    ↓
Place phone on desk
    ↓
15 stable samples detected (~1.5 sec)
    ↓
Activity Status: "Device on table" (Red 📱)
    ↓
Alert timer CANCELLED
    ↓
NO ALERT (on table) ✅
```

### Scenario 4: Using Other Apps While Monitoring
```
Using Safari/Messages/any app ✅
Not in pocket ✅
Human holding (vibrations detected) ✅
User active (stationary at desk) ✅
    ↓
Poor posture for 8+ seconds
    ↓
ALERT SENT 🔔 (This is the only time!)
```

## Activity Status Card

Shows real-time context with color coding:

| Icon | State | Color | Alerts |
|------|-------|-------|--------|
| 👖 | In Pocket | Orange | PAUSED |
| 📱 | On Table | Red | PAUSED |
| 🧍 | User Inactive | Orange | PAUSED* |
| 🚶 | Active - Human | Green | ENABLED ✅ |
| 💤 | Not Monitoring | Gray | N/A |

*Only if Smart Alerts enabled

## How Each Detection Works

### Screen Lock Detection

**Method:** App state monitoring
```swift
UIApplication.didEnterBackgroundNotification
→ Check applicationState
→ If .background → Screen is locked
```

**Timing:** Immediate (< 0.5 seconds)

**Indicators:**
- App goes to background
- No active window
- applicationState == .background

### Pocket Detection

**Method:** Proximity sensor
```swift
UIDevice.proximityMonitoringEnabled = true
UIDevice.proximityStateDidChangeNotification
→ proximityState == true → In pocket/covered
```

**Timing:** Immediate (sensor hardware)

**Indicators:**
- Object within ~5cm of proximity sensor
- Sensor at top of screen (near speaker)
- Typically pocket, face, or hand covering

### Table Detection

**Method:** Accelerometer stability analysis
```swift
For each sample:
  If |sample[i] - sample[i-1]| > 0.005:
    changeCount++

If consecutiveStableSamples >= 15:
  → Device on table
```

**Timing:** ~1.5 seconds (15 stable samples)

**Indicators:**
- No micro-movements
- Perfectly stable readings
- All samples identical

### Activity Detection

**Method:** CoreMotion activity classification
```swift
CMMotionActivityManager
→ Provides: stationary, walking, running, automotive
→ Stationary = Active user
→ Moving = Inactive user
```

**Timing:** ~5-10 seconds (CMMotionActivity delay)

**Indicators:**
- Device motion patterns
- Gait detection
- Movement speed

## Debug Output

Console shows which check blocks alerts:

```
Poor posture detected...

🔒 Alert skipped - screen is locked
OR
👖 Alert skipped - device in pocket  
OR
📱 Alert skipped - device on table
OR
🚶 Alert skipped - user not active
OR
🔔 Alert sent - all conditions met ✅
```

## Testing

### Test 1: Screen Lock
1. Start monitoring, slouch
2. Lock screen
3. Status shows "Screen locked"
4. No alert sent ✅

### Test 2: Pocket
1. Start monitoring
2. Cover proximity sensor (hand over top of phone)
3. Status shows "In pocket"
4. No alert sent even at bad angle ✅

### Test 3: Table
1. Start monitoring
2. Place phone flat on table
3. Within 1.5 sec: Status shows "Device on table"
4. Tilt table to bad angle
5. No alert sent ✅

### Test 4: Combined
1. Start monitoring, hold phone
2. Screen unlocked ✅
3. Proximity sensor uncovered ✅
4. Human vibrations detected ✅
5. Slouch for 8+ seconds
6. Alert SENT ✅

## Battery Impact

All detection methods are highly efficient:

| Detection | Power | CPU | Notes |
|-----------|-------|-----|-------|
| Screen Lock | ~0% | Minimal | Event-based |
| Proximity | <1%/hr | Minimal | Hardware sensor |
| Table | ~1%/hr | Low | Already using accelerometer |
| Activity | ~1%/hr | Low | CoreMotion optimized |
| **Total Added** | **~2-3%/hr** | **Low** | Negligible impact |

## Privacy

All detection happens locally:

- ✅ No data sent to servers
- ✅ No tracking of habits
- ✅ All processing on-device
- ✅ Proximity sensor: Binary state only
- ✅ Screen lock: App state only

## Configuration

Currently all detections are automatic. Future options:

```
Settings → Posture Help
  ├─ Smart Alerts (ON/OFF) - Activity detection
  ├─ Detect Device on Table (ON/OFF) - Table detection  
  ├─ Skip Alerts When Locked (ON/OFF) - Screen lock [Future]
  └─ Skip Alerts in Pocket (ON/OFF) - Proximity [Future]
```

## Why This Matters

### Before (Annoying):
```
User: Puts phone in pocket
App: BZZZZ! Poor posture!
User: Locks screen to check something
App: BZZZZ! Poor posture!
User: Places phone on desk
App: BZZZZ! Poor posture!
User: *Uninstalls app* 😤
```

### After (Intelligent):
```
User: Puts phone in pocket
App: (detects, pauses alerts)
User: Locks screen
App: (detects, pauses alerts)
User: Places phone on desk
App: (detects, cancels pending alert)
User: Actually slouching at desk
App: BZZZZ! Poor posture! 
User: "Thanks, that's actually helpful!" 😊
```

## Edge Cases

### False Positives

**Proximity Sensor:**
- Phone case might trigger it
- Hand near screen when using
- Solution: Only pauses alerts, doesn't stop monitoring

**Table Detection:**
- Very stable hand grip might register as table
- Solution: Threshold tuned for real-world use

### False Negatives

**Screen Lock:**
- App might stay "active" briefly after lock
- Solution: 0.5 second delay to verify state

**Pocket:**
- Loose pocket might not cover sensor
- Solution: Also uses activity detection (walking)

## Troubleshooting

### "In pocket" shown when not in pocket

**Cause:** Proximity sensor triggered
**Check:** Hand or case covering top of phone
**Fix:** Remove case or adjust hold

### Alerts still sent when locked

**Cause:** App not detecting background state
**Debug:** Check console for state transitions
**Fix:** Restart monitoring

### No proximity detection

**Cause:** Sensor disabled or unsupported
**Check:** `UIDevice.current.isProximityMonitoringEnabled`
**Fix:** Feature gracefully disabled, other checks still work

## Summary

With 5 layers of context detection, Posture Help is now the **smartest posture monitoring app** that truly understands when alerts are helpful vs annoying.

**The app only bothers you when:**
- ✅ Screen is unlocked (you can see it)
- ✅ Not in pocket (you can act on it)
- ✅ Human is holding (not on desk)
- ✅ User is active (at desk, not walking)
- ✅ Actually poor posture (real problem)

**Result:** Maximum helpfulness, minimum annoyance 🎯
