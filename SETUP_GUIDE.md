# TalkNotify — Setup & Installation Guide

## Prerequisites

- Windows PC (low-end is fine)
- Android phone (Android 5.0+, USB cable)
- Internet connection for first-time setup

---

## Step 1 — Install Flutter

1. Download Flutter SDK from https://flutter.dev/docs/get-started/install/windows
2. Extract to `C:\flutter` (avoid spaces in path)
3. Add `C:\flutter\bin` to your system PATH:
   - Search "Environment Variables" in Windows
   - Edit `Path` under System Variables → Add `C:\flutter\bin`
4. Open a new terminal and run:
   ```
   flutter doctor
   ```
   Fix any issues it reports (usually just Android SDK or licenses).

---

## Step 2 — Install VS Code

1. Download from https://code.visualstudio.com
2. Install these extensions:
   - **Flutter** (by Dart Code)
   - **Dart** (by Dart Code)

---

## Step 3 — Install Android SDK (without Android Studio)

1. Download **Command Line Tools only** from:
   https://developer.android.com/studio#command-tools
2. Extract to `C:\Android\cmdline-tools\latest\`
3. Add to PATH:
   - `C:\Android\cmdline-tools\latest\bin`
   - `C:\Android\platform-tools`
4. Run:
   ```
   sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
   sdkmanager --licenses
   ```

---

## Step 4 — Set Up Your Android Phone

1. Enable **Developer Options**:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
2. Enable **USB Debugging** in Developer Options
3. Connect phone via USB → Allow debugging when prompted
4. Verify connection:
   ```
   flutter devices
   ```
   Your phone should appear in the list.

---

## Step 5 — Open and Run the Project

```bash
# Navigate to project folder
cd talknotify

# Get all dependencies
flutter pub get

# Run on your connected phone
flutter run
```

---

## Step 6 — Grant Notification Access (REQUIRED)

This is the most important step. Without it, the app cannot read messages.

1. Open the app on your phone
2. Go to **Settings** tab → tap **Notification Access**
3. You'll be taken to: `Settings > Apps > Special app access > Notification access`
4. Find **TalkNotify** and toggle it ON
5. Confirm the warning dialog

> Without this, the app cannot detect WhatsApp, Telegram, or SMS messages.

---

## Step 7 — Grant Microphone Access

When prompted, allow microphone access for voice commands.
Or go to: `Settings > Apps > TalkNotify > Permissions > Microphone`

---

## Build APK (for sharing/installing without USB)

```bash
flutter build apk --release
```

APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

Transfer to phone and install (enable "Install from unknown sources" first).

---

## Common Errors & Fixes

| Error | Fix |
|-------|-----|
| `flutter: command not found` | Add Flutter to PATH, restart terminal |
| `No devices found` | Enable USB debugging, try different USB cable |
| `Gradle build failed` | Run `flutter clean` then `flutter pub get` |
| `SDK not found` | Set `ANDROID_HOME` env variable to your SDK path |
| `Notification listener not working` | Manually grant access in Android settings (Step 6) |
| `Microphone not working` | Grant microphone permission in app settings |
| `Speech recognition unavailable` | Ensure Google app is installed on device |

---

## Voice Commands Reference

| Say this | What happens |
|----------|-------------|
| "Read my message" | Reads the latest message aloud |
| "Read latest message" | Same as above |
| "Who texted me?" | Says the sender's name |
| "Read WhatsApp message" | Reads latest WhatsApp message |
| "Read Telegram message" | Reads latest Telegram message |
| "Stop reading" | Stops TTS immediately |
| "Repeat message" | Re-reads the last message |

---

## Performance Tips for Low-End Devices

- Keep "Voice Alerts" off if you don't need them (saves CPU)
- Clear message history regularly (Settings → History → Clear All)
- Don't run other heavy apps simultaneously
- Use `flutter run --release` for better performance than debug mode

---

## Project Structure

```
talknotify/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/
│   │   ├── message_model.dart       # Message data model
│   │   └── app_settings.dart        # Settings model
│   ├── providers/
│   │   └── app_provider.dart        # State management
│   ├── screens/
│   │   ├── splash_screen.dart       # Launch screen
│   │   ├── home_screen.dart         # Dashboard
│   │   ├── history_screen.dart      # Message history
│   │   └── settings_screen.dart     # App settings
│   ├── services/
│   │   ├── tts_service.dart         # Text-to-speech
│   │   ├── speech_service.dart      # Voice recognition
│   │   ├── notification_service.dart # Local notifications
│   │   ├── message_stream_service.dart # Android bridge
│   │   ├── database_service.dart    # SQLite storage
│   │   └── settings_service.dart    # Preferences
│   ├── widgets/
│   │   └── message_card.dart        # Reusable message card
│   └── utils/
│       ├── constants.dart           # Colors, themes, constants
│       └── permissions_helper.dart  # Permission utilities
└── android/
    └── app/src/main/
        ├── AndroidManifest.xml      # Permissions & services
        └── java/com/example/talknotify/
            ├── MainActivity.java    # Flutter-Android bridge
            └── NotificationListener.java # Reads notifications
```
