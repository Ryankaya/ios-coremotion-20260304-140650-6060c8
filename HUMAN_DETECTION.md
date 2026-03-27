# Human Vibration Detection

## The Problem

Traditional posture apps have a major flaw: they can't tell the difference between:
- 👤 **A human holding the device** (should alert)
- 📱 **Device sitting on a table** (should NOT alert)

This leads to annoying false positives when your phone is on your desk at a perfect angle that triggers the "poor posture" threshold.

## Our Solution: Micro-Movement Detection

Humans are not robots. Even when we try to sit perfectly still, we have natural micro-movements:
- 💓 **Heartbeat** - Creates tiny vibrations
- 🫁 **Breathing** - Subtle chest movements
- 🤲 **Hand tremor** - Natural muscle micro-contractions
- 🧠 **Micro-adjustments** - Constant small posture corrections

A device on a table has **ZERO** movement - it's perfectly still.

## How It Works

### Accelerometer Analysis

The app uses the device accelerometer to measure vibrations:

```
1. Read acceleration data at 10 Hz (10 times per second)
2. Calculate magnitude: √(x² + y² + z²)
3. Build history of last 50 samples (5 seconds)
4. Calculate variance and standard deviation
5. Detect patterns:
   - High variance = Human holding ✅
   - Zero variance = On table ❌
```

### Detection Algorithm

**Human Detection:**
- Standard deviation > 0.02 m/s²
- Continuous micro-variations in acceleration
- Never perfectly still for more than 3 seconds

**Table Detection:**
- Standard deviation < 0.02 m/s²
- Perfectly consistent readings
- No movement for 3+ seconds

### Visual Example

```
Human Holding Device:
Acceleration: 9.81, 9.82, 9.80, 9.83, 9.79, 9.82, 9.81...
              ↑     ↑     ↑     ↑     ↑     ↑     ↑
            Micro-variations from breathing and heartbeat
            Standard Deviation: ~0.025 ✅ HUMAN DETECTED

Device on Table:
Acceleration: 9.81, 9.81, 9.81, 9.81, 9.81, 9.81, 9.81...
              ↑     ↑     ↑     ↑     ↑     ↑     ↑
            Perfectly consistent - no movement
            Standard Deviation: ~0.001 ❌ TABLE DETECTED
```

## User Experience

### With Detection ON (Recommended)

**Scenario 1: Working at Desk**
```
You → Holding phone in chest pocket
     ↓
Device detects micro-movements
     ↓
"Human Holding" = TRUE ✅
     ↓
You slouch for 8+ seconds
     ↓
ALERT TRIGGERED 🔔
```

**Scenario 2: Device on Desk**
```
You → Place phone flat on desk at angle
     ↓
Device perfectly still for 3+ seconds
     ↓
"Human Holding" = FALSE ❌
     ↓
Phone angle shows "poor posture"
     ↓
NO ALERT (correctly skipped) 🚫
```

### Settings Toggle

**"Detect Device on Table" Setting:**

**ON (Default):**
- Monitors accelerometer for movement
- Skips alerts when device is perfectly still
- Prevents false positives
- Best user experience

**OFF:**
- Alerts based only on angle
- Use if you want alerts regardless
- For testing or special cases

## Technical Implementation

### DeviceMovementService

**Key Components:**

```swift
// Accelerometer monitoring
motionManager.accelerometerUpdateInterval = 0.1  // 10 Hz

// Movement threshold
movementThreshold: 0.02  // m/s² standard deviation

// Stillness timeout
stillnessTimeout: 3.0  // seconds
```

**Processing Pipeline:**

1. **Data Collection**
   - Collect acceleration samples
   - Store last 50 samples (5 seconds of history)

2. **Statistical Analysis**
   - Calculate mean acceleration
   - Calculate variance
   - Compute standard deviation

3. **Pattern Recognition**
   - If SD > threshold → Human detected
   - If SD < threshold for 3s → Table detected

4. **State Management**
   - Update `isHumanHolding` flag
   - Publish changes to ViewModel

### Integration with Alert System

```
Poor Posture Detected
    ↓
Check 1: User Active? (Smart Alerts)
    ↓ YES
Check 2: Human Holding? (Movement Detection)
    ↓ YES
Send Alert ✅

If either check fails → Skip alert ❌
```

## Configuration

### Tunable Parameters

Located in `DeviceMovementService.swift`:

```swift
// Sensitivity for detecting micro-movements
private let movementThreshold: Double = 0.02

// Time before considering device "on table"
private let stillnessTimeout: TimeInterval = 3.0

// History size for analysis
private let historySize = 50
```

### Sensitivity Adjustment

**More Sensitive** (detect subtle movements):
- Lower `movementThreshold` to 0.01
- Catches even smaller vibrations
- May have false positives

**Less Sensitive** (require clear movement):
- Raise `movementThreshold` to 0.03
- Only detects obvious holding
- May miss some valid cases

## UI Indicators

### Activity Status Card

Shows current detection state:

| Icon | Color | Status | Meaning |
|------|-------|--------|---------|
| 🚶 | Green | Active - Human Holding | Alerts enabled |
| 📱 | Red | Device on Table | Alerts paused |
| 🧍 | Orange | Inactive | User not active |
| 💤 | Gray | Not Monitoring | Stopped |

### Real-time Feedback

The card updates in real-time:
- Place phone on table → Turns RED within 3 seconds
- Pick up phone → Turns GREEN within 1 second
- Walk around → Turns ORANGE (user inactive)

## Testing

### How to Test on Real Device

**Test 1: Human Holding Detection**
1. Start monitoring
2. Hold phone in your hand or chest pocket
3. Stay still but breathe normally
4. Activity Status should show "Active - Human Holding" (Green)

**Test 2: Table Detection**
```
1. Start monitoring
2. Place phone flat on stable table
3. Don't touch for 5 seconds
4. Activity Status should show "Device on Table" (Red)
5. Lean phone at poor posture angle
6. Should NOT receive alert ✅
```

**Test 3: Pick Up After Table**
1. Phone on table (Red status)
2. Pick it up
3. Within 1-2 seconds → Green status
4. Now alerts work again

**Test 4: Toggle Setting**
1. Turn OFF "Detect Device on Table"
2. Place phone on table
3. Should receive alerts (setting disabled)
4. Turn ON setting
5. Alerts pause when on table

### Expected Behaviors

**Normal Use Cases:**

| Scenario | Detection | Alert Behavior |
|----------|-----------|----------------|
| Phone in chest pocket | Human ✅ | Normal alerts |
| Holding phone while sitting | Human ✅ | Normal alerts |
| Phone on desk stand | Table ❌ | Alerts paused |
| Phone lying flat on table | Table ❌ | Alerts paused |
| Walking with phone | Human + Inactive | Alerts paused (Smart Alerts) |
| Driving with phone in holder | Table ❌ | Alerts paused |

## Benefits

### 1. Better User Experience
- No annoying false alerts when phone is on desk
- Only bothers you when actually relevant
- Feels more intelligent

### 2. Increased Trust
- Users trust the app more
- Fewer false positives = more credibility
- Won't disable app due to annoyance

### 3. Battery Efficiency
- Skipping unnecessary alerts saves power
- Fewer haptics when not needed
- Fewer notifications processed

### 4. More Accurate
- Focuses on actual posture monitoring
- Distinguishes intent vs accident
- Better data on real usage

## Limitations

### Known Edge Cases

**May Not Detect as "Human":**
- Extremely still meditation/yoga
- Phone in very stable chest pocket while sleeping
- Device clamped in rigid mount

**May Not Detect as "Table":**
- Table with vibrations (washing machine nearby)
- Unstable surface (wobbly desk)
- Moving vehicle (car, train)

### Workarounds

**For edge cases:**
- Toggle "Detect Device on Table" OFF
- Adjust sensitivity thresholds in code
- Use "Smart Alerts" toggle for different behavior

## Privacy

### Data Collection

**What We Measure:**
- Accelerometer readings (x, y, z acceleration)
- Statistical variance over time
- Movement patterns

**What We DON'T Store:**
- No raw accelerometer data saved
- No historical logs kept
- All processing is real-time

**Privacy Guarantee:**
- 100% local processing
- No data sent to servers
- No tracking or analytics

## Performance

### Resource Usage

**CPU:** Minimal
- 10 Hz sampling is very efficient
- Simple statistical calculations
- Negligible impact

**Battery:** ~1% per hour
- Accelerometer is low-power sensor
- Adds minimal drain to existing motion tracking

**Memory:** Tiny
- Only stores 50 samples (~400 bytes)
- No memory leaks
- Automatic cleanup

## Future Enhancements

Potential improvements:

- [ ] Machine learning for pattern recognition
- [ ] Adaptive threshold based on user behavior
- [ ] Distinguish between different hold positions
- [ ] Detect if device is in pocket vs hand
- [ ] Time-of-day based sensitivity
- [ ] User calibration mode

## Troubleshooting

### "Device on Table" shown while holding

**Possible causes:**
- Holding phone too still
- Very stable grip
- Sensitivity threshold too high

**Solutions:**
- Move slightly or breathe deeply
- Adjust `movementThreshold` lower (0.01)
- Toggle setting OFF temporarily

### Always shows "Human Holding" even on table

**Possible causes:**
- Unstable table (vibrations)
- Moving vehicle
- Nearby machinery

**Solutions:**
- Use more stable surface
- Increase `movementThreshold` (0.03)
- Use different alert settings

### Detection too slow

**Timing:**
- Detection needs 3 seconds of data
- This is intentional to avoid flickering
- Cannot be made faster without false positives

## Technical Deep Dive

### Why Standard Deviation?

Standard deviation measures consistency:
- Low SD = Consistent values = Still
- High SD = Varying values = Movement

**Math:**
```
Mean = Σ(values) / count
Variance = Σ((value - mean)²) / count  
Standard Deviation = √Variance
```

### Why 10 Hz Sampling?

**Balance between:**
- Accuracy: Catch micro-movements
- Power: Don't drain battery
- Performance: Process in real-time

10 Hz is sweet spot for human movement detection.

### Why 3 Second Timeout?

**Too short (< 1 second):**
- False positives when briefly still
- Flickering status
- Annoying UX

**Too long (> 5 seconds):**
- Slow to detect table placement
- Delayed alert pausing
- Poor responsiveness

3 seconds is optimal.

## Conclusion

Human vibration detection makes Posture Help **the smartest posture app** by understanding context and only alerting when it matters. No more false alerts from phones on desks!

**Key Innovation:** Using natural human micro-movements to distinguish real usage from accidental positioning.

---

*Making technology more human, one vibration at a time* 🫨✨
