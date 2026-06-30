# Setup Guide — Secure Exam Browser

This guide walks you from zero to running the app on your PC and phone.

---

## 1. Install Flutter

Go to https://docs.flutter.dev/get-started/install and download Flutter for your OS.

**Windows:**
```powershell
# Download the ZIP, extract to C:\flutter
# Add to PATH (System Environment Variables):
#   C:\flutter\bin
# Then in a NEW PowerShell window:
flutter doctor
```

**macOS:**
```bash
# Install via Homebrew:
brew install --cask flutter
# Or download from flutter.dev
flutter doctor
```

**Linux:**
```bash
sudo snap install flutter --classic
flutter doctor
```

`flutter doctor` will show what's missing (Android Studio, Xcode, etc.). Install whatever it complains about.

---

## 2. Generate Platform Files

```powershell
cd D:\Sofian\Mobile SE

# This creates temporary project with all platform boilerplate
flutter create --org com.exambrowser --project-name secure_exam_browser --platforms android,ios,windows,macos temp_gen

# Copy generated platform files INTO our project
Copy-Item -Recurse temp_gen\android\* secure_exam_browser\android\
Copy-Item -Recurse temp_gen\ios\* secure_exam_browser\ios\
Copy-Item -Recurse temp_gen\windows\* secure_exam_browser\windows\
Copy-Item -Recurse temp_gen\macos\* secure_exam_browser\macos\
Copy-Item temp_gen\.gitignore secure_exam_browser\
Copy-Item temp_gen\test\* secure_exam_browser\test\

# Clean up
Remove-Item -Recurse temp_gen
```

---

## 3. Register Native Plugins (Critical Step)

### iOS — Edit `ios/Runner/AppDelegate.swift`

Open the file at `secure_exam_browser/ios/Runner/AppDelegate.swift` and ADD this line inside the `didFinishLaunchingWithOptions` function, **after** `GeneratedPluginRegistrant.register(with: self)`:

```swift
if let registrar = self.registrar(forPlugin: "LockdownPlugin") {
    LockdownPlugin.register(with: registrar)
}
```

It should look like:
```swift
override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // ↓ ADD THIS ↓
    if let registrar = self.registrar(forPlugin: "LockdownPlugin") {
        LockdownPlugin.register(with: registrar)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
```

### Android — Edit `android/app/src/main/kotlin/.../MainActivity.kt`

Open the generated `MainActivity.kt` (in the same package folder) and replace it:

```kotlin
package com.exambrowser.secureexambrowser

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(LockdownPlugin())
    }
}
```

### Windows — Edit `windows/runner/flutter_window.cpp`

Find the `OnCreate` method and add after `RegisterPlugins()`:

```cpp
#include "lockdown_plugin.h"   // add at top

// Inside OnCreate(), after RegisterPlugins():
LockdownPluginRegisterWithRegistrar(
    registry_->GetRegistrarForPlugin("LockdownPlugin"));
```

### macOS — Edit `macos/Runner/MainFlutterWindow.swift`

Find the function that registers plugins (usually `awakeFromNib` or similar) and add:

```swift
if let registrar = self.registrar(forPlugin: "LockdownPlugin") {
    LockdownPlugin.register(with: registrar)
}
```

---

> **Important:** Replace `subsaharanlms.com` in the ATS exceptions below with your actual Moodle instance domain for production builds.

## 4. iOS Permissions — Edit Info.plist

Open `ios/Runner/Info.plist` and add:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera is used for exam proctoring</string>
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>subsaharanlms.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

---

## 5. Install Dependencies

```powershell
cd D:\Sofian\Mobile SE\secure_exam_browser
flutter pub get
```

---

## 6. Run on Your PC

```powershell
# Windows desktop
flutter run -d windows

# Or if that fails, build directly:
flutter build windows --release
# The .exe will be in build\windows\runner\Release\
```

**What you'll see:** A splash screen → login screen → after OAuth2 login → exam screen with WebView loading Moodle.

**For testing lockdown on PC:**
- Windows: Alt+Tab, Win key, Ctrl+Shift+Esc, Print Screen all blocked
- macOS: Cmd+Tab, Cmd+Q, Cmd+H, Cmd+W all blocked
- Our lockdown indicator bar shows "Exam Lockdown Active"

---

## 7. Run on Android Phone

### Setup (one time):
1. Enable **Developer options** on your phone:
   - Settings → About phone → Tap "Build number" 7 times
2. Enable **USB debugging**:
   - Settings → Developer options → USB debugging → ON
3. Connect phone to PC via USB cable

### Install:
```powershell
flutter run -d android
# Or build APK and side-load:
flutter build apk --debug
# APK at: build\app\outputs\flutter-apk\app-debug.apk
# Transfer to phone and open to install
```

### Full lockdown (LockTask):
For MDM-level kiosk:
1. Install the app
2. Settings → Security → Device admin apps → Enable "Secure Exam Browser"
3. The app will then be able to use LockTask mode

---

## 8. Run on iPhone/iPad

**iOS requires a Mac with Xcode.** You cannot build iOS from Windows.

```bash
# On a Mac:
cd secure_exam_browser
open ios/Runner.xcworkspace
# In Xcode: Select your team in Signing & Capabilities
# Then:
flutter run -d ios
```

---

## 9. Run on macOS Desktop

```bash
# On a Mac:
cd secure_exam_browser
flutter run -d macos
```

---

## 10. Troubleshooting

| Problem | Fix |
|---------|-----|
| `flutter: command not found` | Flutter not in PATH. Restart terminal after install. |
| `No devices found` | Connect phone or start emulator. `flutter devices` to list. |
| `GeneratedPluginRegistrant` errors | Run `flutter pub get` to regenerate. |
| LockdownPlugin not found | Check step 3 — plugin not registered in platform file. |
| Camera not working | Add `NSCameraUsageDescription` in Info.plist (iOS) or camera permission in AndroidManifest.xml |
| Windows builds fail | Install Visual Studio 2022 with "Desktop development with C++" workload. |
| macOS builds fail | Install Xcode from App Store, then `sudo xcode-select --install` |
