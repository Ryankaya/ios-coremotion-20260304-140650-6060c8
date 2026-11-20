# Posture Help 1.0: App Store Connect fill guide

Work through these sections from top to bottom in App Store Connect. Every value below is ready to paste. Items marked **⚠︎ fix** need changing on your current page.

> Requirements checked against Apple's [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) and [App Store Connect release notes](https://developer.apple.com/help/app-store-connect/release-notes/) (November 2026).

---

## A. Distribution → iOS App Version 1.0

### A1. Header and Search Results
Already uploaded (`header/header-3840x1646.png`). Nothing to do.

### A2. App Previews and Screenshots ⚠︎ fix
Apple's **required** iPhone slot is **"iPhone with Dynamic Island (medium display)"**, which takes **1206 × 2622** (or 1179 × 2556). If you uploaded the 1320 × 2868 set there, remove it and use folder 1.

| Upload to tab | Folder | Size | Count |
|---|---|---|---|
| **iPhone with Dynamic Island (medium display)**: required | `screenshots/1-REQUIRED-iphone-medium-display-1206x2622/` | 1206 × 2622 | 10 |
| **iPad 13" display**: required (the app runs on iPad) | `screenshots/2-REQUIRED-ipad-13in-2064x2752/` | 2064 × 2752 | 9 |
| iPhone large display (6.9"): optional, falls back to medium | `screenshots/3-optional-iphone-large-display-1320x2868/` | 1320 × 2868 | 6 |
| iPhone Duo: optional until April 2027 (iOS 27.1 SDK builds) | not needed now | n/a | n/a |

Drag the files in numbered order (01 → 10):

1. Catch the slouch as it happens (live gauge)
2. A gentle nudge before it hurts (lean alert)
3. Watch your posture improve (Insights)
4. Your posture, at a glance (Home Screen widgets; iPhone only)
5. Calibrated to your body
6. Reminders that reach you in any app
7. Smart enough to pause (Settings)
8. Easy on the eyes, day or night (Dark Mode)
9. Set up in under a minute
10. Private by design

### A3. Promotional Text ⚠︎ fix (it currently holds the subtitle)
```
Catch yourself slouching over your phone. Posture Help notices when you lean forward and gives you a gentle nudge to sit up straight. Private and on-device.
```

### A4. Description / Keywords
Already filled. ✓

### A5. Support URL ⚠︎ recommended fix
The current URL is the GitHub code repo. It loads, but App Review expects a page where users can get help. Publish `support.md` (section D) and use its URL, for example:
`https://ryankaya.github.io/ios-coremotion-20260304-140650-6060c8/AppStore/support`

### A6. Marketing URL
Leave empty (optional).

### A7. Version / Copyright
`1.0` / `2026 Austin Ventures LLC` ✓

### A8. Routing App Coverage File, App Clip, iMessage App
Leave all empty. They're only for navigation apps, App Clips and Messages-framework apps; Posture Help is none of these.

### A9. Build
Build **1** attached ✓

### A10. Game Center
Leave unchecked.

### A11. App Review Information
- **Sign-in required**: unchecked ✓
- **Contact**: filled ✓
- **Notes** ⚠︎ fix (currently empty). Paste:
```
Posture Help measures forward lean using the iPhone's motion sensors (CoreMotion), so please review it on a physical iPhone; the Simulator provides no motion data.

How to test (about 1 minute):
1. Complete the short onboarding and tap "Allow Notifications".
2. Sit upright, tap "Start Calibration", and hold still for about 4 seconds.
3. On the Today tab, tap "Start Session".
4. Tilt the top of the phone toward you (as if hunching over it) by about 15-20 degrees and hold for 8 seconds. The gauge turns amber, then you'll feel a haptic and receive a reminder notification.
5. Reminders pause automatically when the phone is locked, in a pocket, or lying still on a table, so keep the phone in hand and unlocked while testing.

Background mode "processing" is used only to keep an active session's reminders working after the user switches apps. Reminder text is generated on-device with Apple's Foundation Models framework. The app has no account, makes no network requests, and no data leaves the device.

Widgets (Home Screen, Lock Screen) and Control Center controls are included and can start/stop a session.
```
- **Attachment**: optional. Skip it, or attach a short screen recording from a real device of steps 2–4.

### A12. App Store Version Release
"Automatically release this version" is fine. Choose Manual if you want to pick the launch day.

---

## B. General (left sidebar)

### B1. App Information
| Field | Value |
|---|---|
| Name | Posture Help |
| Subtitle | `Posture nudges for your phone` |
| Primary category | Health & Fitness |
| Secondary category | Lifestyle |
| Content Rights | "No, it does not contain, show, or access third-party content" |
| Age Rating | Edit → answer **None / No** to every item, including the new **Shared Location** and **Dating and Relationships** descriptors → result **4+** |

### B2. App Compliance (new)
Apple moved regulatory declarations here. Answer:
- **Medical device**: **No**. Posture Help is a general wellness app; it doesn't diagnose, treat or prevent any condition (the description says so).
- **AI-generated content**: the app uses Apple's on-device Foundation Models to write short reminder messages. If the form asks whether the app generates text with AI, answer **Yes** and describe it as "short posture reminder notifications generated on-device; no user-submitted content, no image or media generation".
- **Regulations / permits** (ICP, game license, China security assessment): **Not applicable**, unless you distribute in China mainland.

I couldn't find Apple's full question list for this page, so if a question doesn't match the above, paste it here and I'll answer it.

### B3. App Review
Status view only.

---

## C. App Store (left sidebar)

### C1. App Privacy (Trust & Safety)
1. **Privacy Policy URL**: publish `privacy-policy.md` (section D) and paste its URL.
2. **Data collection** → **"No, we do not collect data from this app"** → **Publish**.
   Accurate because the app has no networking code, no analytics/ads SDKs and no account. Motion data, settings and history stay on the device.

### C2. App Accessibility (Accessibility Nutrition Labels)
Optional today, but Apple says it will become required over time. Declare only what holds for the app's common tasks (calibrate, start/end a session, view Insights, change settings):
- **Dark Interface**: **Yes**. The whole app and its widgets support Dark Mode.
- VoiceOver, Voice Control, Larger Text (200%), Sufficient Contrast, Differentiate Without Color, Reduced Motion, Captions, Audio Descriptions: **don't declare yet**. They haven't been audited. I can audit them and fix any gaps if you'd like.

### C3. Ratings and Reviews, In-App Events, Custom Product Pages, Promo Codes, Game Center
Nothing required.

### C4. Pricing and Availability (Monetization)
- **Price**: Free (or choose a tier).
- **Availability**: All countries/regions.
- **EU (Digital Services Act)**: Apple requires a trader declaration to sell in the EU. Austin Ventures LLC is a business, so declare **Trader**. Apple then shows your business address, phone and email on the EU product page. If you'd rather not, untick the EU countries.

---

## D. Hosting the Support and Privacy pages (needed for A5 and C1)

`support.md` and `privacy-policy.md` in this folder are ready. Both use `ryankaya.dev@gmail.com` as the contact; change it if you want a different public address.

Fastest route, using your existing public repo:
1. Commit and push the `AppStore/` folder to `main`.
2. On GitHub: **Settings → Pages → Build and deployment → Deploy from a branch → main / (root) → Save**.
3. After about a minute your URLs are:
   - Support: `https://ryankaya.github.io/ios-coremotion-20260304-140650-6060c8/AppStore/support`
   - Privacy: `https://ryankaya.github.io/ios-coremotion-20260304-140650-6060c8/AppStore/privacy-policy`
4. Open both in a browser to check, then paste them into A5 and C1.

---

## E. Submit
**Save → Add for Review →** fix anything App Store Connect lists → **Submit for Review**. Review usually takes 24–48 hours.

---

### Regenerating screenshots after UI changes
1. Boot an iPhone with a 1206 × 2622 screen (iPhone 18 Pro / 17 Pro) and an iPad Pro 13" simulator.
2. Build the Debug app, then run `AppStore/capture.sh <udid> <path/to/PostureHelp.app> iphone63` (or `ipad`). The script uses the debug-only demo mode: `-demoMode YES`, `-demoLean`, `-demoTab`, `-demoCalibrate`, `-demoOnboardingStep`.
3. The widgets shot (`raw/iphone63_10_widgets.png`) is captured by hand: add the small and medium widgets to the Home Screen while a demo session is running.
4. From the repo root: `swift AppStore/compose.swift`
