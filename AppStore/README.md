# App Store submission kit: Posture Help 1.0

Everything for the **iOS App Version 1.0** page in App Store Connect, in page order.
Fill in the three `‹placeholders›`; everything else is ready to paste or upload.

---

## 1. Header and Search Results (Product Page Information)

Upload **one** of these (both are the same design; the wider one crops more cleanly):

| File | Size |
|---|---|
| `header/header-3840x1646.png` | 3840 × 1646 (recommended) |
| `header/header-5244x2950.png` | 5244 × 2950 |

Use **Preview** in App Store Connect to check the Header and Search Results crops. Key content is kept in the centre so it survives both.

> All images are true PNG files (8-bit sRGB, no alpha channel). Don't rename or re-save them as another format: App Store Connect checks the real file type, and files with transparency are rejected.

## 2. App Previews and Screenshots

Upload in this order (drag the whole folder in, then confirm order):

| # | iPhone 6.9" (1320 × 2868), `screenshots/iphone-6.9/` | iPad 13" (2064 × 2752), `screenshots/ipad-13/` | Caption |
|---|---|---|---|
| 1 | `01-today-good.png` | `01-today-good.png` | Catch the slouch as it happens |
| 2 | `02-today-alert.png` | `02-today-alert.png` | A gentle nudge before it hurts |
| 3 | `03-insights.png` | `03-insights.png` | Watch your posture improve |
| 4 | `04-calibrate.png` | `04-calibrate.png` | Calibrated to your body |
| 5 | `05-settings.png` | `05-settings.png` | Smart enough to pause |
| 6 | `06-welcome.png` | `06-welcome.png` | Private by design |

App Store Connect scales the 6.9" set down for smaller iPhones and the 13" set for smaller iPads, so these two sets cover every device. iPad screenshots are required because the app supports iPad.

App preview video: optional, skipped.

## 3. Text fields

**Promotional Text** (156/170, can be changed anytime without review)
```
Catch yourself slouching over your phone. Posture Help notices when you lean forward and gives you a gentle nudge to sit up straight. Private and on-device.
```

**Description** (up to 4000)
```
Posture Help notices when you're hunching over your phone and gives you a gentle nudge to sit up straight, so better posture becomes a habit instead of a chore.

HOW IT WORKS
• Calibrate once: hold your phone the way you normally read while sitting upright.
• Start a session and use your phone as usual. Posture Help uses the motion sensors to track how far you lean forward.
• Lean past your threshold for too long and you'll feel a haptic and get a friendly reminder, even while you're in other apps.

SMART PAUSE
Reminders pause on their own when they wouldn't help: when your phone is in a pocket, locked, or resting on a table. You can also limit them to portrait use or to times you're actively interacting.

SEE YOUR PROGRESS
• Live lean gauge and session stats
• Daily upright score, streaks and a 7-day trend
• Simple habits that help: screen height, regular resets and the 20-20-20 rule

MADE FOR YOU
• Relaxed, Balanced and Strict sensitivity presets, or fine-tune every threshold
• Home Screen and Lock Screen widgets with one-tap sessions
• Control Center controls to start a session or recalibrate

PRIVATE BY DESIGN
All posture data is processed and stored on your device. No account, no tracking, no ads.

Posture Help is a wellness tool and is not a medical device. If you have pain or a medical condition, talk to a healthcare professional.
```

**Keywords** (95/100; the app name is indexed separately, so it isn't repeated)
```
slouch,back,neck,text neck,ergonomic,reminder,habit,spine,sit straight,corrector,hunch,wellness
```

**Support URL**: `‹https://your-site/posture-help/support›` (host `support.md`, see section 6)

**Marketing URL**: optional, leave blank.

**Version** `1.0` · **Copyright** `2026 ‹Your name or company›`

**Routing App Coverage File**: not applicable, leave empty.

## 4. App Information (left sidebar → General → App Information)

| Field | Value |
|---|---|
| Name | Posture Help |
| Subtitle (29/30) | `Posture nudges for your phone` |
| Primary category | Health & Fitness |
| Secondary category | Lifestyle |
| Content rights | Does not contain third-party content |
| Age rating | Answer **None/No** to every question → **4+** |

## 5. App Privacy (left sidebar → Trust & Safety → App Privacy)

- **Privacy Policy URL**: `‹https://your-site/posture-help/privacy›` (host `privacy-policy.md`, see section 6)
- **Data collection**: choose **"No, we do not collect data from this app."**
  - This is accurate: the app has no networking code, no analytics or ads SDKs, and no account. Motion readings, settings and history stay in on-device storage, and reminder text is generated on-device.
- Result on the product page: **Data Not Collected**.

Export compliance: `ITSAppUsesNonExemptEncryption = NO` is now set in `Sources/Info.plist`, so App Store Connect won't ask the encryption question for each build.

## 6. Hosting the two required URLs

App Store Connect needs public URLs for **Support** and **Privacy Policy**. Quickest free options:

- **GitHub Pages**: put `support.md` and `privacy-policy.md` in a public repo, enable Pages, and use the resulting URLs.
- **Notion / Google Sites**: paste the text and publish to the web.

Replace `‹contact email›` in both files before publishing.

## 7. App Review Information (bottom of the version page)

- **Sign-in required**: No
- **Contact**: your name, phone and email
- **Notes** (paste):
```
Posture Help measures forward lean using the iPhone's motion sensors (CoreMotion), so it must be reviewed on a physical device; the Simulator has no motion data.

To test:
1. Complete the short onboarding and allow notifications.
2. Sit upright and tap "Start Calibration", then hold still for about 4 seconds.
3. On the Today tab, tap "Start Session".
4. Tilt the top of the phone toward you (as if hunching over it) by about 15-20 degrees and hold for 8 seconds. The gauge turns amber, then you'll feel a haptic and receive a reminder notification.
5. Reminders pause automatically when the phone is locked, in a pocket, or lying still on a table, so keep the phone in hand and unlocked while testing.

Background modes (fetch/processing) are used only to keep an active session's reminders working when the user switches apps. No account or network access is needed, and no data leaves the device.
```

## 8. Build

Select the uploaded build in the **Build** section (Xcode → Product → Archive → Distribute App → App Store Connect). Then **Add for Review**.

---

### Regenerating the images

The screenshots come from the real app running in **demo mode** (Debug builds only). Simulated motion and sample history stand in for the Simulator's missing sensors. To rebuild after UI changes:

1. Run the app on an iPhone 6.9" and an iPad 13" simulator with launch arguments
   `-hasCompletedOnboarding YES -demoMode YES` plus optionally `-demoLean 19`, `-demoTab insights|settings`, `-demoIdle YES -demoCalibrate YES`.
2. Save the raw captures into `raw/` with the same file names.
3. From the repo root: `swift AppStore/compose.swift`
