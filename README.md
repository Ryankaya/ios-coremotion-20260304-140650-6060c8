# Posture Help

A production-level iOS app that monitors your posture using device motion sensors and provides intelligent, context-aware feedback to help maintain healthy sitting habits.

## Features

### Core Functionality
✅ **Real-time Posture Monitoring** - Tracks device orientation to detect forward lean  
✅ **Smart Calibration** - Auto-calibrates to your ideal posture  
✅ **Haptic Feedback** - Distinctive vibration patterns for alerts  
✅ **Local Notifications** - Gentle reminders to correct posture  
✅ **Background Monitoring** - Continues tracking even when app is closed  
✅ **Activity Detection** - Only alerts when you're actively using your device  

### Intelligent Features
🧠 **Smart Alerts** - Detects when you're walking, standing, or away from device  
🫨 **Human Vibration Detection** - Distinguishes human holding device vs device on table  
⚙️ **Customizable Sensitivity** - Adjust thresholds to your comfort  
📊 **Real-time Metrics** - View current pitch, lean delta, and alert history  
🎯 **Production-Ready UI** - Modern, polished interface with design system  

## Quick Start

### Requirements
- iOS 14.0+
- Physical iPhone/iPad (motion sensors required)
- Motion & Fitness permission
- Notifications permission (optional)

### Basic Usage
1. Open app on your iPhone
2. Sit upright with good posture
3. Tap **"Start Monitoring"**
4. App auto-calibrates and begins tracking
5. Receive alerts when slouching

## How It Works

### Posture Detection
- Uses **CoreMotion** to read device pitch (tilt angle)
- Calculates deviation from your calibrated baseline
- Default threshold: **12° forward lean**
- Alerts after **8 seconds** of sustained poor posture

### Smart Activity System
The app knows when you're actually using your device:

**Alerts Enabled:**
- Sitting at desk (stationary)
- Actively using your phone
- Within 30 seconds of last interaction

**Alerts Paused:**
- Walking or moving around
- Standing in meetings
- Device hasn't been used recently

### Background Monitoring
- Continues tracking when screen is off
- Works while using other apps
- Minimal battery impact (~5-10% per day)
- No cloud sync or data transmission

## Architecture

Built with modern iOS best practices:

```
PostureHelp/
├── Models/              # Data structures
├── ViewModels/          # Business logic (MVVM)
├── Views/               # SwiftUI components
│   └── Components/      # Reusable UI elements
├── Services/            # Platform services
│   ├── MotionService
│   ├── HapticService
│   ├── NotificationService
│   ├── UserActivityService
│   └── BackgroundTaskService
└── Utilities/           # Theme & extensions
```

**Key Principles:**
- Protocol-oriented design for testability
- Dependency injection
- Separation of concerns
- Type safety
- Reactive programming with Combine

## Configuration

### Sensitivity Settings

**Lean Threshold** (6-24°)
- How much you can lean before alerting
- Lower = more sensitive
- Default: 12°

**Sustain Duration** (3-20 sec)
- How long you must maintain poor posture
- Prevents false positives from brief movements
- Default: 8 seconds

**Alert Interval** (8-120 sec)
- Cooldown between repeated alerts
- Prevents notification spam
- Default: 20 seconds

### Smart Alerts Toggle

**ON (Recommended):**
- Only alert when actively using device
- Better user experience
- Fewer interruptions

**OFF:**
- Continuous monitoring
- Alerts regardless of activity
- For testing or specific workflows

## Privacy

### Data Collection
- ✅ All processing happens **locally** on your device
- ✅ No data sent to servers or cloud
- ✅ No analytics or tracking
- ✅ No location services used

### Permissions
- **Motion & Fitness**: Required for posture tracking and activity detection
- **Notifications**: Optional, for posture alerts

## Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Technical architecture and design patterns
- **[TESTING.md](TESTING.md)** - Complete testing guide with troubleshooting
- **[BACKGROUND_MONITORING.md](BACKGROUND_MONITORING.md)** - Background features and smart alerts
- **[HUMAN_DETECTION.md](HUMAN_DETECTION.md)** - Vibration detection to distinguish human vs table

## Build & Deploy

### Requirements
- Xcode 14.0+
- Swift 5.7+
- iOS 14.0+ deployment target

### Building
```bash
# Clone or open project
open PostureHelp.xcodeproj

# Select your device (not simulator)
# Product → Run (⌘R)
```

### Testing
- **Must use real device** - Simulator lacks motion sensors
- Enable Motion & Fitness permission when prompted
- See TESTING.md for detailed guide

## Technical Highlights

### Services Layer
- **MotionService**: CoreMotion abstraction with protocol
- **HapticService**: Custom haptic pattern engine
- **NotificationService**: Local notification management
- **UserActivityService**: Intelligent activity detection with CMMotionActivityManager
- **DeviceMovementService**: Accelerometer-based human vibration detection
- **BackgroundTaskService**: iOS background task management

### UI Components
- **PostureStatusCard**: Visual posture state indicator
- **MetricsCard**: Real-time measurement display
- **SettingsCard**: Interactive configuration controls
- **ActivityStatusCard**: User activity visualization
- **InstructionsCard**: Onboarding guide

### Design System
- Centralized Theme with colors, spacing, typography
- Consistent corner radius and padding
- Reusable view modifiers
- Production-ready polish

## Known Limitations

- iOS Simulator not supported (no motion sensors)
- Background refresh subject to iOS power management
- Activity detection requires ~10-15 seconds to stabilize
- May trigger false alerts when driving (detected as movement)

## Roadmap

Future enhancements under consideration:

- [ ] Machine learning for personalized posture patterns
- [ ] Health app integration for long-term tracking
- [ ] Apple Watch companion app
- [ ] Time-of-day based sensitivity
- [ ] Weekly posture reports and insights
- [ ] Calendar integration (auto-pause during meetings)

## Support

### Common Issues

**"Device motion unavailable"**
→ Running in simulator. Deploy to real device.

**No alerts when slouching**
→ Check Activity Status shows "Active"  
→ Verify you've been leaning for full Sustain Duration  
→ Try disabling Smart Alerts temporarily

**Too many false alerts**
→ Increase Lean Threshold  
→ Increase Sustain Duration  
→ Recalibrate baseline

### Getting Help
1. Review TESTING.md for troubleshooting
2. Check BACKGROUND_MONITORING.md for smart alerts
3. Verify all permissions are granted
4. Ensure running on physical device

## License

This is a demonstration project showcasing production-level iOS development practices.

## Credits

Built with:
- SwiftUI for declarative UI
- CoreMotion for sensor access
- CoreHaptics for tactile feedback
- Combine for reactive programming
- BackgroundTasks for background operation

---

**Made with care for your posture** 🪑✨
