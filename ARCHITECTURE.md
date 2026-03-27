# Posture Help - Architecture Documentation

## Overview
Posture Help is a production-level iOS application built with SwiftUI following modern MVVM architecture principles. The app monitors user posture using CoreMotion and provides real-time feedback through notifications and haptic alerts.

## Architecture Pattern: MVVM (Model-View-ViewModel)

### Project Structure

```
PostureHelp/
├── Sources/
│   ├── Models/                    # Data models
│   │   ├── PostureState.swift     # Enum for posture states
│   │   ├── PostureConfiguration.swift  # User settings model
│   │   └── PostureMetrics.swift   # Current posture data
│   │
│   ├── ViewModels/                # Business logic layer
│   │   └── PostureViewModel.swift # Main view model coordinating services
│   │
│   ├── Views/                     # UI layer
│   │   ├── PostureMonitorView.swift   # Main view
│   │   └── Components/
│   │       ├── PostureStatusCard.swift    # Visual status indicator
│   │       ├── MetricsCard.swift          # Metrics display
│   │       ├── SettingsCard.swift         # Settings controls
│   │       └── ActionButton.swift         # Reusable button component
│   │
│   ├── Services/                  # Business services layer
│   │   ├── MotionService.swift    # CoreMotion wrapper
│   │   ├── HapticService.swift    # Haptic feedback manager
│   │   └── NotificationService.swift  # Local notification manager
│   │
│   ├── Utilities/                 # Helpers and extensions
│   │   ├── Theme.swift            # Design system (colors, spacing, typography)
│   │   └── Extensions.swift       # Swift extensions
│   │
│   ├── PostureHelpApp.swift      # App entry point
│   ├── ContentView.swift         # Root view wrapper
│   └── Info.plist               # App configuration
```

## Layer Responsibilities

### Models Layer
- **Pure data structures** with no business logic
- Defines the shape of data used throughout the app
- Includes validation logic where appropriate
- `PostureState`: Enum defining posture states (unknown, good, warning, alert)
- `PostureConfiguration`: User-adjustable settings
- `PostureMetrics`: Real-time posture measurements

### Services Layer
- **Protocol-based design** for testability and flexibility
- Each service has a single responsibility
- Services are injected into ViewModels (Dependency Injection)
- **MotionService**: Manages CoreMotion updates and device motion data
- **HapticService**: Handles custom haptic feedback patterns
- **NotificationService**: Manages local notification permissions and delivery

### ViewModels Layer
- **Single source of truth** for view state
- Coordinates multiple services
- Contains all business logic for posture evaluation
- Published properties trigger view updates
- Uses `@MainActor` to ensure UI updates on main thread
- Testable through protocol-based service injection

### Views Layer
- **Declarative UI** using SwiftUI
- Stateless and reactive to ViewModel changes
- Modular, reusable components
- Follows single responsibility principle
- Uses consistent design system (Theme)

### Utilities Layer
- **Theme**: Centralized design system
  - Colors, spacing, typography, corner radius constants
  - View modifiers for consistent styling
- **Extensions**: Helper methods for formatting and display

## Key Design Principles

### 1. Separation of Concerns
Each layer has a distinct responsibility and doesn't leak into other layers.

### 2. Dependency Injection
Services are injected into ViewModels via initializers, enabling:
- Easy testing with mock services
- Flexibility to swap implementations
- Clear dependencies

### 3. Protocol-Oriented Design
Services conform to protocols, allowing:
- Multiple implementations
- Easy mocking for tests
- Loose coupling

### 4. Single Responsibility
Each file/class has one clear purpose:
- `MotionService` only handles motion updates
- `HapticService` only handles haptics
- `NotificationService` only handles notifications

### 5. Composition Over Inheritance
Views are composed of smaller, reusable components rather than complex inheritance hierarchies.

### 6. Reactive Programming
Using Combine's `@Published` properties for automatic UI updates when data changes.

## Data Flow

```
Motion Sensor → MotionService → PostureViewModel → PostureMonitorView
                                      ↓
                                HapticService
                                      ↓
                             NotificationService
```

1. User interacts with View (e.g., taps "Start Monitoring")
2. View calls ViewModel method
3. ViewModel coordinates with Services
4. Services perform their specific tasks
5. Services report back to ViewModel
6. ViewModel updates `@Published` properties
7. SwiftUI automatically re-renders affected Views

## Testing Strategy

### Unit Tests
- **ViewModels**: Test with mock services
- **Services**: Test in isolation
- **Models**: Test validation logic

### UI Tests
- Test user flows end-to-end
- Verify proper state transitions
- Ensure accessibility

## Benefits of This Architecture

1. **Testability**: Protocol-based services can be easily mocked
2. **Maintainability**: Clear separation makes code easy to find and modify
3. **Scalability**: Easy to add new features without affecting existing code
4. **Reusability**: Components and services can be reused across the app
5. **Type Safety**: Strong typing prevents runtime errors
6. **Performance**: Efficient reactivity with minimal re-renders

## Production-Ready Features

- Error handling for device availability
- Permission management for notifications
- Graceful degradation (haptics work without notifications)
- Configurable sensitivity settings
- Cooldown periods to prevent alert spam
- Clean, modern UI with consistent design system
- Accessibility support through semantic views
- Memory-safe with weak references where needed
