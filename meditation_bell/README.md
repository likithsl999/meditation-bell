# Meditation Bell

A clean, minimal Flutter Android app for guided meditation with bell sounds, session tracking, and streak stats.

## Features

- **Session Timer** — choose 5, 10, 15, 30 min or a custom duration
- **Bell Intervals** — ring every 30 sec, 1 min, 2 min, or 5 min
- **Three Bell Sounds** — Temple Bell, Singing Bowl, Soft Chime (preview in Settings)
- **Custom Sounds** — import any MP3 from local storage
- **Volume Controls** — independent bell and ambient volume sliders
- **Vibration** — optional haptic feedback on each bell
- **Accurate Timer** — uses real-time DateTime tracking; survives background throttling and pauses
- **Background Audio** — `audioplayers` configured with Android audio focus and Bluetooth routing
- **Stats** — total minutes, total sessions, current daily streak (stored locally)
- **Offline** — no internet, no accounts, no ads

## Project Structure

```
lib/
├── main.dart                    # App entry point, theme, routing
├── models/
│   ├── app_settings.dart        # Settings value object (bell, volume, vibration)
│   ├── custom_sound.dart        # Custom sound model + JSON serialization
│   └── meditation_session.dart  # Session data model
├── services/
│   ├── audio_service.dart       # audioplayers wrapper (AudioContext, background audio)
│   └── storage_service.dart     # SharedPreferences CRUD
├── providers/
│   ├── meditation_provider.dart # DateTime-based timer + state machine
│   ├── settings_provider.dart   # Bell, volume, vibration, custom sound import
│   └── stats_provider.dart      # Session recording + stats read
└── screens/
    ├── home_screen.dart         # Duration/interval selectors, Start button
    ├── meditation_screen.dart   # Countdown timer, controls, breathing ring
    ├── stats_screen.dart        # Total time, sessions, streak
    └── settings_screen.dart     # Volume sliders, bell picker, vibration toggle, custom sounds

assets/
└── audio/
    ├── temple_bell.mp3          # ← ADD BEFORE BUILDING
    ├── singing_bowl.mp3         # ← ADD BEFORE BUILDING
    └── soft_chime.mp3           # ← ADD BEFORE BUILDING
```

## Quick Start

### Prerequisites

- Flutter **3.22+** installed and on your PATH
- Android SDK installed, `ANDROID_HOME` set
- A physical Android device or emulator (**API 21+**)

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

| Package              | Purpose                                       |
|----------------------|-----------------------------------------------|
| `provider`           | State management                              |
| `shared_preferences` | Local storage for stats, settings, sounds     |
| `audioplayers`       | Bell + ambient sound playback                 |
| `vibration`          | Haptic feedback                               |
| `wakelock_plus`      | Keep screen on during session                 |
| `file_picker`        | Import custom MP3 files                       |
| `path_provider`      | Persistent storage path for custom sounds     |

## Android Permissions

| Permission                          | Reason                                      |
|-------------------------------------|---------------------------------------------|
| `VIBRATE`                           | Haptic feedback on each bell                |
| `WAKE_LOCK`                         | Keeps screen on during meditation           |
| `FOREGROUND_SERVICE`                | Required for media playback declaration     |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Audio focus / background audio category     |
| `READ_EXTERNAL_STORAGE` (API ≤ 32) | File picker on Android 12 and below         |
| `READ_MEDIA_AUDIO` (API 33+)        | File picker on Android 13+                  |

## Background Audio

Audio is configured with `AudioContextAndroid` using `USAGE_MEDIA` + `CONTENT_TYPE_MUSIC` + `AudioFocus.GAIN`, which gives the app a proper Android audio session. This allows audio to continue playing when the screen is off (with `wakelock_plus` keeping the display on during sessions) and routes correctly through Bluetooth headsets.

> **Note:** The Dart timer uses absolute `DateTime` arithmetic, so it remains accurate even if the OS throttles `Timer.periodic` when backgrounded.

## Customization

- **App ID**: change `applicationId` in `android/app/build.gradle`
- **App name**: change `android:label` in `AndroidManifest.xml`
- **Accent color**: change `seedColor` in `main.dart → _buildTheme()`
- **Add more preset durations**: extend `_durations` list in `home_screen.dart`
- **Add ambient sounds**: implement `AudioService.playBackground()` with an asset path
