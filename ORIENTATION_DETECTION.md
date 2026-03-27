# Orientation Detection - Smart Portrait Mode Alerts

## The Problem

Users watch TikTok/Reels/Shorts in **portrait mode** (vertical) and tend to slouch. But when using the phone in other orientations (landscape for videos, flat on desk), posture alerts aren't relevant.

## The Solution

**Only send alerts when phone is held vertically in portrait mode** - the exact position where people watch social media and slouch!

## How It Works

### Gravity-Based Detection

Uses device motion gravity vector to determine orientation:

```swift
Gravity Vector Analysis:
- Y-axis (up/down) dominant → Portrait/Upside-down
- X-axis (left/right) dominant → Landscape
- Z-axis (forward/back) dominant → Face up/down (flat)

Portrait Mode (ALERT ✅):
- Gravity Y < 0 (pointing down)
- Phone vertical, upright
- Perfect for TikTok/Reels/Shorts

Other Modes (SKIP ❌):
- Landscape: Watching YouTube horizontally
- Face up: On desk
- Face down: On table
```

### Detected Orientations

| Orientation | Gravity | Alert? | Use Case |
|-------------|---------|--------|----------|
| **Portrait** | Y < 0 | **YES ✅** | **TikTok, Reels, Shorts** |
| Portrait Upside Down | Y > 0 | NO ❌ | Rare usage |
| Landscape Left | X < 0 | NO ❌ | YouTube, videos |
| Landscape Right | X > 0 | NO ❌ | YouTube, videos |
| Face Up | Z < 0 | NO ❌ | On desk/table |
| Face Down | Z > 0 | NO ❌ | On table |

## Real-World Usage

### Scenario 1: Watching TikTok (Portrait)
```
Holding phone vertically 📱
    ↓
Scrolling TikTok/Reels
    ↓
Slouching forward
    ↓
Orientation: Portrait ✅
    ↓
After 8 seconds:
🔔 ALERT SENT!
```

### Scenario 2: Watching YouTube (Landscape)
```
Rotate phone horizontally 📺
    ↓
Watching YouTube video
    ↓
Slouching forward
    ↓
Orientation: Landscape ❌
    ↓
NO ALERT (orientation not portrait)
```

### Scenario 3: Phone on Desk (Face Up)
```
Place phone flat on desk
    ↓
Bad angle (tilted)
    ↓
Orientation: Face Up ❌
    ↓
NO ALERT (not portrait)
```

## Settings Toggle

**"Only Alert in Portrait Mode"** (ON by default)

```
ON (Recommended):
- Only alerts when vertical
- Perfect for TikTok/Reels/Shorts
- Skips landscape/flat orientations

OFF:
- Alerts in ALL orientations
- For users who want constant monitoring
```

## The Complete Alert Logic (5 Layers)

```
Poor Posture Detected
    ↓
1. Is orientation portrait?
    ├─ NO → ❌ Skip (landscape/flat)
    └─ YES → Continue
    ↓
2. Is device in pocket?
    ├─ YES → ❌ Skip (proximity)
    └─ NO → Continue
    ↓
3. Is device on table?
    ├─ YES → ❌ Skip (no vibrations)
    └─ NO → Continue
    ↓
4. Is user walking?
    ├─ YES → ❌ Skip (activity)
    └─ NO → Continue
    ↓
✅ SEND ALERT!
```

## Debug Console

```
Portrait mode + slouching:
📱 Orientation changed: Portrait (vertical) - Should alert: true
🔔 Alert sent - Portrait orientation + poor posture

Landscape mode + slouching:
📱 Orientation changed: Landscape right - Should alert: false
📱 Alert skipped - wrong orientation (Landscape right)

Face up + slouching:
📱 Orientation changed: Face up (flat) - Should alert: false
📱 Alert skipped - wrong orientation (Face up (flat))
```

## Why This Matters

### Before (Annoying):
```
User: Watching YouTube in landscape
      (Comfortable position, not slouching)
App: BZZZZ! Poor posture!
User: But I'm fine in this position... 😤

User: Phone flat on desk
App: BZZZZ! Poor posture!
User: I'm not even holding it! 😤
```

### After (Smart):
```
User: Watching YouTube in landscape
      (Comfortable position)
App: (detects landscape, no alert) ✅

User: Phone flat on desk
App: (detects face up, no alert) ✅

User: Scrolling TikTok vertically, slouching
App: BZZZZ! Poor posture!
User: Oh right, I should sit up! 😊
```

## Technical Implementation

### OrientationService

**Update Frequency:** 5 Hz (every 0.2 seconds)

**Detection Algorithm:**
```swift
if abs(z) > 0.8:
    → Flat (face up/down)
else if abs(y) > abs(x):
    → Portrait (vertical)
else:
    → Landscape (horizontal)
```

**Battery Impact:** ~1% per hour (efficient CoreMotion usage)

## Testing

### Test 1: Portrait Mode (Should Alert)
1. Hold phone vertically (portrait)
2. Start monitoring
3. Slouch for 8+ seconds
4. Alert sent ✅

### Test 2: Landscape Mode (No Alert)
1. Rotate phone horizontal (landscape)
2. Watch video
3. Slouch for 8+ seconds
4. No alert ✅

### Test 3: Face Up (No Alert)
1. Place phone flat on desk
2. Bad angle
3. Wait 8+ seconds
4. No alert ✅

### Test 4: Toggle Setting
1. Turn OFF "Only Alert in Portrait Mode"
2. Use landscape mode
3. Slouch
4. Alert sent (setting disabled) ✅

## Gravity Vector Examples

**Portrait (Vertical):**
```
  📱 Phone
  |
  |
  ↓ Gravity (y = -1.0)
```

**Landscape (Horizontal):**
```
←─ Gravity (x = -1.0)  📱 Phone
```

**Face Up (Flat on Back):**
```
     📱 Phone (face up)
     ↑
     | Gravity (z = -1.0)
```

## Common Orientations in Apps

| App | Typical Orientation | Alerts? |
|-----|-------------------|---------|
| TikTok | Portrait | YES ✅ |
| Instagram Reels | Portrait | YES ✅ |
| YouTube Shorts | Portrait | YES ✅ |
| YouTube Videos | Landscape | NO ❌ |
| Netflix | Landscape | NO ❌ |
| Games | Landscape/Various | NO ❌ |
| Messages | Portrait | YES ✅ |
| Safari | Portrait | YES ✅ |

## Edge Cases

### Quick Rotation
- Orientation updates every 0.2s
- Brief rotations ignored (must stay in orientation)
- Prevents false negatives

### Tilted Portrait
- Phone at angle but still vertical
- Still detected as portrait ✅
- Alerts work correctly

### Diagonal Holding
- Phone between portrait/landscape
- Uses dominant axis
- Generally detected correctly

## Benefits

1. **Relevant Alerts**: Only when posture actually matters
2. **Less Annoying**: No alerts during comfortable landscape viewing
3. **Social Media Focus**: Perfect for TikTok/Reels/Shorts usage
4. **Smart Context**: Understands how phone is being used
5. **Battery Efficient**: Lightweight gravity detection

## Configuration

```
Settings → Posture Help

✅ Only Alert in Portrait Mode (Recommended)
   "Only when vertical (TikTok/Reels/Shorts)"
   
   Toggle ON:  Alerts only in portrait
   Toggle OFF: Alerts in all orientations
```

## Summary

With orientation detection, Posture Help now understands **HOW** you're using your phone and only alerts when it makes sense:

- 📱 **Portrait** (TikTok, scrolling) → Alert for posture ✅
- 📺 **Landscape** (watching videos) → No alert ❌
- 🖥️ **Flat** (on desk) → No alert ❌

**The result:** Alerts that are actually helpful, not annoying! 🎯
