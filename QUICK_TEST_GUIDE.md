# Quick Testing Guide - Human Detection

## Expected Behavior Summary

**CORRECT BEHAVIOR:**
- 👤 **Human holding + poor posture** → ✅ SEND ALERT
- 📱 **Device on table + poor posture** → ❌ SKIP ALERT

## Step-by-Step Tests

### Test 1: Human Holding (Should Alert)

**Setup:**
1. Enable "Detect Device on Table" in settings
2. Start monitoring
3. Hold phone in your hand or chest pocket

**Test:**
1. Slouch forward at poor posture angle
2. Wait 8+ seconds (sustain duration)

**Expected Result:**
- Activity Status: "Active - Human Holding" (Green 🚶)
- Status Message: "Poor posture - please sit upright"
- **Alert SENT** ✅ (haptic + notification)

**Debug Console Should Show:**
```
📊 Movement Detection - SD: 0.0250, Threshold: 0.02, HasMovement: true
✅ Human detected - vibrations present
```

---

### Test 2: Device on Table (Should NOT Alert)

**Setup:**
1. Enable "Detect Device on Table" in settings
2. Start monitoring
3. Place phone flat on stable table

**Test:**
1. Wait 5 seconds for detection
2. Tilt table or prop phone at poor posture angle
3. Wait 8+ seconds

**Expected Result:**
- Activity Status: "Device on Table" (Red 📱)
- Status Message: "Poor posture detected but device on table - no alert"
- **Alert SKIPPED** ❌ (no haptic, no notification)

**Debug Console Should Show:**
```
📊 Movement Detection - SD: 0.0005, Threshold: 0.02, HasMovement: false
📱 Table detected - device perfectly still for 3s
```

---

### Test 3: Pick Up After Table

**Setup:**
1. Phone on table (Test 2 state)
2. Activity Status shows "Device on Table" (Red)

**Test:**
1. Pick up phone
2. Hold in hand for 2 seconds
3. Slouch at poor posture

**Expected Result:**
- Status changes to "Active - Human Holding" (Green) within 1-2 seconds
- **Alert SENT** ✅ when poor posture detected

---

## Verification Checklist

### ✅ Correct Behaviors:
- [ ] Human holding + slouching → Alert sent
- [ ] Device on table + angle wrong → No alert
- [ ] Pick up from table → Alerts resume
- [ ] Status card shows correct state
- [ ] Status messages are clear

### ❌ Incorrect Behaviors (Report if occurs):
- [ ] Human holding but no alert (check debug logs)
- [ ] Device on table but alert sent
- [ ] Status stuck on wrong state
- [ ] Takes too long to detect (>5 seconds)

## Understanding the Status Messages

**When monitoring:**

| Status Message | Meaning | Alerts? |
|---------------|---------|---------|
| "Good posture" | Sitting upright, human holding | Would alert if slouch |
| "Good posture (device on table - alerts paused)" | Upright angle but on table | Would NOT alert |
| "Leaning forward detected" | Human holding, slight lean | Will alert if sustained |
| "Lean detected but device on table - alerts paused" | Table, wrong angle | Will NOT alert |
| "Poor posture - please sit upright" | Human holding, sustained bad posture | Alert SENT ✅ |
| "Poor posture detected but device on table - no alert" | Table, sustained bad angle | Alert SKIPPED ❌ |

## Debug Console Interpretation

### Human Detected (Unstable Readings):
```
Changes: 8/30 samples differ from previous
AvgChange: 0.00234, Threshold: 0.005
IsHuman: true (≥3 changes detected)
→ isHumanHolding = true
→ Alerts ENABLED ✅
```

**What this means:** Every second, the acceleration reading changes slightly due to breathing, heartbeat, micro-movements. This is NORMAL for humans.

### Table Detected (Perfectly Stable):
```
Changes: 0/30 samples differ from previous  
AvgChange: 0.00001, Threshold: 0.005
IsHuman: false (<3 changes)
Still for: 2+ seconds
→ isHumanHolding = false  
→ Alerts PAUSED ❌
```

**What this means:** Acceleration readings are IDENTICAL or nearly identical every sample. This only happens when device is on a stable surface.

## Troubleshooting

### Issue: Always shows "Human Holding" even on table

**Possible causes:**
- Table is vibrating (check if stable)
- Threshold too low
- Near machinery or speakers

**Fix:**
- Use more stable surface
- Temporarily disable "Detect Device on Table"
- Check debug logs for SD values

### Issue: Shows "Device on Table" while holding

**Possible causes:**
- Holding extremely still
- Threshold too high
- Not breathing deeply enough (yes, really!)

**Fix:**
- Move slightly
- Breathe normally
- Check debug logs for SD values
- Lower threshold in code if needed

### Issue: Detection is slow

**This is normal:**
- Needs 3 seconds of data for table detection
- Prevents flickering between states
- Cannot be made faster without false positives

## Advanced: Adjusting Sensitivity

If detection isn't working well, you can adjust in `DeviceMovementService.swift`:

```swift
// Current values:
private let movementThreshold: Double = 0.02  // Standard deviation threshold
private let stillnessTimeout: TimeInterval = 3.0  // Seconds before "table"
private let historySize = 50  // Samples to analyze

// More sensitive (detect subtler movements):
private let movementThreshold: Double = 0.01

// Less sensitive (require more obvious movement):
private let movementThreshold: Double = 0.03

// Faster table detection (more false positives):
private let stillnessTimeout: TimeInterval = 2.0

// Slower table detection (more stable):
private let stillnessTimeout: TimeInterval = 5.0
```

## Summary

The logic is:
```
Poor Posture Detected
    ↓
Is Human Holding?
    ├─ YES → SEND ALERT ✅
    └─ NO  → SKIP ALERT ❌
```

**Key Point:** The app should annoy you when YOU are slouching, but not when your PHONE is at a wrong angle on the desk!
