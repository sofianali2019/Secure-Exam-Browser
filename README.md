# Secure Exam Browser

Cross-platform native app embedding Moodle with OS-level exam lockdown. Flutter codebase targeting iOS, Android, Windows, and macOS.

## Quick Start

```bash
# Prerequisites: Flutter 3.16+ installed
# https://docs.flutter.dev/get-started/install

cd secure_exam_browser
flutter pub get
flutter run            # runs on connected device/emulator
flutter build apk      # Android release
flutter build ios      # iOS release (macOS only)
flutter build windows  # Windows release
flutter build macos    # macOS release (macOS only)
```

## Obfuscated Release Build

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
flutter build ios --release --obfuscate --split-debug-info=build/debug-info
flutter build windows --release --obfuscate --split-debug-info=build/debug-info
flutter build macos --release --obfuscate --split-debug-info=build/debug-info
```

## Project Structure

```
lib/
  services/     → auth, lockdown, webview, proctoring, config
  screens/      → splash, login, exam, results
  widgets/      → lockdown_indicator, proctoring_overlay
  config/       → app defaults
  models/       → exam_config, lockdown_state, auth_state
  providers/    → state management (AppProvider)

ios/            → Swift lockdown plugin
android/        → Kotlin lockdown plugin
windows/        → C++ lockdown plugin (keyboard hooks, Win32)
macos/          → Swift lockdown plugin
```

## Lockdown Features

| Feature | iOS | Android | Windows | macOS |
|---------|-----|---------|---------|-------|
| Full-screen kiosk | Guided Access (MDM) | LockTask (MDM) | Win32 fullscreen | NSApp kiosk |
| Block screenshots | UIScreen.isCaptured | FLAG_SECURE | SetWindowDisplayAffinity | CGDisplayStream |
| Block app switch | Single App Mode | LockTask | Low-level keyboard hook | NSEvent monitor |
| Block shortcuts | N/A | Key override | WH_KEYBOARD_LL | NSEvent tap |
| Block notifications | DND via MDM | AudioManager mute | N/A | DND API |
| Block right-click | N/A | N/A | WH_MOUSE_LL | NSEvent tap |

## Auth Flow

1. User taps "Sign in with Moodle"
2. OAuth2 authorization via platform browser (ASWebAuth / Chrome Custom Tab)
3. Token stored in Keychain/KeyStore via `flutter_secure_storage`
4. Token injected as cookie into WebView
5. Automatic refresh on expiry

## SEB Config Support

The app accepts configuration via:
- **Config key**: Entered manually or scanned as QR code
- **Moodle integration**: Quiz launch triggers app with config
- JSON structure supports all lockdown flags, exam duration, proctoring settings

## Proctoring

- Front camera capture at configurable interval
- Periodic upload to configured endpoint
- Visual recording indicator overlay
- Disabled by default; enabled via SEB config

## Security

- Dart obfuscation via `--obfuscate`
- Android ProGuard rules
- iOS symbol stripping
- Certificate pinning (platform-specific)
- Secure storage for credentials
- Platform channel caller validation

## CI/CD

GitHub Actions builds all platforms:
- `flutter analyze` + `flutter test` on every push
- Android: APK artifact
- iOS: IPA artifact (requires Apple Developer account)
- Windows: Release executable
- macOS: Release bundle

## MDM Requirements (Mobile)

For full lockdown on mobile:
- **iOS**: MDM profile with Guided Access / Single App Mode
- **Android**: Device Policy Controller (DPC) app for LockTask mode

See your MDM provider's documentation for deployment profiles.

## License

Proprietary.
