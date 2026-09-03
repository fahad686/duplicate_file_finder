# Duplicate File Finder

A Flutter Android app that scans for duplicate files using MD5 hash comparison, helping you reclaim storage space.

## Features

- **Fast Scanning** — Size filter first, then chunked MD5 hashing
- **Large Files** — List the biggest files so you can reclaim space
- **Unused Files** — Find files not opened or changed in months
- **File Thumbnails** — Image previews for photos, type icons for other files
- **2x2 Filter Grid** — Filter results by Images, Videos, Audio, or Documents
- **Batch Selection** — Keeps the newest file; selects older duplicates
- **Multimedia Player** — Built-in viewer for images, videos, and audio files
- **File Details** — Name, size, path, hash, modification date
- **Delete Confirmation** — Safety dialog before removing files
- **Dark Theme** — Modern dark UI with blue accent colors

## Tech Stack

| Package | Purpose |
|---------|---------|
| `permission_handler` | Android storage / all-files-access permissions |
| `crypto` | Chunked MD5 file hashing |
| `shared_preferences` | Persist scan settings |
| `video_player` | In-app video playback |
| `just_audio` | In-app audio playback |
| `open_file` | Open files in external apps |
| `intl` | Date formatting |
| `path` | File path utilities |

## Project Structure

```
lib/
├── main.dart
├── models/
│   ├── duplicate_file.dart          # DuplicateFile & DuplicateGroup
│   └── file_types.dart              # Shared extension lists
├── services/
│   ├── app_settings.dart            # Persisted scan preferences
│   └── file_scanner_service.dart    # File scanning & hashing engine
├── screens/
│   ├── home_screen.dart             # Dashboard with scan button
│   ├── scanning_screen.dart         # Cancelable scan progress
│   ├── results_screen.dart          # Filtered duplicate groups list
│   ├── file_detail_screen.dart      # File info & actions
│   ├── media_player_screen.dart     # Custom multimedia player
│   └── settings_screen.dart         # Scan preferences
└── widgets/
    └── duplicate_group_card.dart    # Expandable group with thumbnails
```

## Getting Started

```bash
flutter pub get
flutter run
```

## Permissions (Android)

Play strategy: **keep All files access**. This app finds duplicate documents and archives, not only media, so MediaStore / `READ_MEDIA_*` is not enough.

| Android version | Permission |
|-----------------|------------|
| 11+ (API 30+) | `MANAGE_EXTERNAL_STORAGE` ("All files access") |
| 10 (API 29) | `READ_EXTERNAL_STORAGE` + `requestLegacyExternalStorage` |
| 9 and below | `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` |

### Play Console declaration

When uploading to Google Play, complete the **All files access** declaration:

- App type: file manager / storage tool
- Core feature: find and delete duplicate user files across shared storage
- Video demo: scan → review duplicates → delete extras

Do not use the `com.example.*` application ID. Current ID: `com.duplicatefilefinder.app` (change this to your Play account namespace before shipping).

## How It Works

1. Tap **Scan Now** on the home screen
2. Grant storage / all-files-access when prompted
3. App scans `/storage/emulated/0`, skipping `Android/data` and `Android/obb`
4. Settings control file types, minimum size, and auto-select oldest
5. Same-size files are grouped, then MD5-hashed in chunks
6. Groups keep the newest file first; older copies can be deleted

## Release signing

1. Create a keystore (once):

```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Copy `android/key.properties.example` to `android/key.properties` and fill in the passwords and alias.

`key.properties` and `*.jks` are gitignored. Release builds use the upload keystore when `key.properties` exists; otherwise they fall back to the debug key (dev only).

## Build APK

```bash
flutter build apk --release
```

## Version

1.0.0+1
