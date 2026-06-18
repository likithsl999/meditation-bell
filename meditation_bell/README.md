# Meditation Bell

A clean, minimal Flutter Android app for guided meditation with bell sounds, session tracking, and streak stats.

## Features

- **Session Timer** — choose 5, 10, 15, 30 min or a custom duration
- **Bell Intervals** — ring every 30 sec, 1 min, 2 min, or 5 min
- **Three Bell Sounds** — Temple Bell, Singing Bowl, Soft Chime (preview in Settings)
- **Vibration** — optional haptic feedback on each bell
- **Background Support** — timer and audio continue while the app is minimized
- **Stats** — total minutes, total sessions, current daily streak (stored locally)
- **Offline** — no internet, no accounts, no ads

## Project Structure

```
lib/
├── main.dart                    # App entry point, theme, routing
├── models/
│   ├── app_settings.dart        # Settings value object
│   └── meditation_session.dart  # Session data model
├── services/
│   ├── audio_service.dart       # audioplayers wrapper
│   └── storage_service.dart     # SharedPreferences CRUD
├── providers/
│   ├── meditation_provider.dart # Timer logic + state
│   ├── settings_provider.dart   # Bell sound + vibration state
│   └── stats_provider.dart      # Session recording + stats
└── screens/
    ├── home_screen.dart         # Duration/interval selectors, Start button
    ├── meditation_screen.dart   # Countdown timer, controls, breathing ring
    ├── stats_screen.dart        # Total time, sessions, streak
    └── settings_screen.dart     # Bell sound picker, vibration toggle

assets/
└── audio/
    ├── temple_bell.mp3          # ← ADD BEFORE BUILDING
    ├── singing_bowl.mp3         # ← ADD BEFORE BUILDING
    └── soft_chime.mp3           # ← ADD BEFORE BUILDING
```

## Quick Start

### Prerequisites

- Flutter 3.10+ installed and on your PATH
- Android SDK installed, `ANDROID_HOME` set
- A physical Android device or emulator (API 21+)

### 1. Add audio files

Place three MP3 files in `assets/audio/` — see `assets/audio/README.md` for sources.

### 2. Configure Android SDK path

```bash
cp android/local.properties.template android/local.properties
# Edit local.properties and set sdk.dir and flutter.sdk paths
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run

```bash
flutter run
```

### 5. Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Packages Used

| Package                      | Purpose                          |
|------------------------------|----------------------------------|
| `provider`                   | State management                 |
| `shared_preferences`         | Local storage for stats/settings |
| `audioplayers`               | Bell sound playback              |
| `vibration`                  | Haptic feedback                  |
| `wakelock_plus`              | Keep screen on during session    |
| `flutter_background_service` | Background timer support         |

## Android Permissions

- `VIBRATE` — haptic feedback
- `FOREGROUND_SERVICE` — background timer
- `FOREGROUND_SERVICE_MEDIA_PLAYBACK` — background audio
- `WAKE_LOCK` — screen stays on during session
- `RECEIVE_BOOT_COMPLETED` — service persistence

## Customization

- **App ID**: change `applicationId` in `android/app/build.gradle`
- **App name**: change `android:label` in `AndroidManifest.xml`
- **Accent color**: change `seedColor` in `main.dart → _buildTheme()`
- **Add more durations**: extend `_durations` list in `home_screen.dart`
