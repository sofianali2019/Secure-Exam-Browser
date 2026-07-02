# Secure Exam Browser — Project Summary

> Cross-platform Flutter app embedding Moodle with OS-level exam lockdown.
> Generated for AI model handoff — contains all architectural decisions, file structure, dependencies, and known issues.

---

## Table of Contents

1. [Overview](#overview)
2. [Tech Stack](#tech-stack)
3. [Project Structure](#project-structure)
4. [Architecture](#architecture)
5. [Authentication Flow](#authentication-flow)
6. [Exam Lifecycle](#exam-lifecycle)
7. [Moodle API Integration](#moodle-api-integration)
8. [Key Screens](#key-screens)
9. [Dependencies](#dependencies)
10. [Build & Run](#build--run)
11. [Testing](#testing)
12. [Git History](#git-history)
13. [Known Issues & Decisions](#known-issues--decisions)

---

## Overview

A secure exam browser that wraps Moodle quizzes inside a locked-down WebView. Features:
- **Cross-platform**: Android, Windows, iOS, macOS
- **Authentication**: Moodle token API (`/login/token.php`)
- **Lockdown**: OS-level kiosk mode (Android Device Admin, Windows kiosk, etc.)
- **Exam launcher**: From enrolled courses via the app's dashboard
- **Proctoring**: Periodic webcam snapshots during exams
- **Moodle API**: Retrieve courses, quizzes, attempts, and access info
- **SEB-compatible**: Import QR codes / config keys, create lockdown configs

**GitHub**: https://github.com/sofianali2019/Secure-Exam-Browser
**Default branch**: `master`

---

## Tech Stack

| Component | Choice | Version |
|-----------|--------|---------|
| Framework | Flutter | 3.41.0 |
| Language | Dart | 3.x |
| Android SDK | AGP | 8.14+ |
| Gradle | Wrapper | 8.14 |
| JDK | Android Studio JBR | 21 |
| iOS | CocoaPods | — |

---

## Project Structure

```
secure_exam_browser/
├── lib/
│   ├── main.dart                     # Entry point
│   ├── app.dart                      # Route definitions
│   ├── config/
│   │   └── defaults.dart             # Default LMS URL, constants
│   ├── models/
│   │   ├── auth_state.dart           # Token + isAuthenticated + error
│   │   ├── course_info.dart          # Moodle course model
│   │   ├── exam_config.dart          # Lockdown config (QR/SEB compatible)
│   │   ├── lockdown_state.dart       # Lockdown status enum
│   │   ├── quiz_attempt.dart         # Quiz attempt model
│   │   ├── quiz_info.dart            # Quiz metadata model
│   │   └── user_info.dart            # Moodle user (isSiteAdmin, etc.)
│   ├── providers/
│   │   └── app_provider.dart         # Central ChangeNotifier, bridges all services
│   ├── screens/
│   │   ├── splash_screen.dart        # Auth check → /login or /dashboard
│   │   ├── login_screen.dart         # LMS URL + username + password form
│   │   ├── dashboard_screen.dart     # Role-based cards (My Exams, QR, Config, Admin)
│   │   ├── exam_list_screen.dart     # Enrolled courses → quizzes list
│   │   ├── exam_detail_screen.dart   # Quiz details + Start Exam button
│   │   ├── exam_screen.dart          # Lockdown WebView + toolbar + timer + submit
│   │   ├── admin_panel_screen.dart   # Dashboard/Courses/Exams/Monitor tabs
│   │   ├── qr_scanner_screen.dart    # QR code → ExamConfig
│   │   ├── config_key_screen.dart    # Manual config key entry
│   │   └── results_screen.dart       # Placeholder results view
│   ├── services/
│   │   ├── auth_service.dart         # Token login, secure storage, user info
│   │   ├── moodle_api_service.dart   # REST API: courses, quizzes, attempts
│   │   ├── config_service.dart       # Persist/load ExamConfig
│   │   ├── lockdown_service.dart     # OS-level lockdown (cross-platform plugin)
│   │   ├── proctoring_service.dart   # Periodic camera snapshots
│   │   └── webview_service.dart      # WebViewController, JS bridge, CSP, login
│   ├── widgets/
│   │   ├── exam_timer.dart           # Countdown timer widget
│   │   ├── exam_info_overlay.dart    # Exam details bottom sheet
│   │   ├── lockdown_indicator.dart   # Lockdown status bar
│   │   └── proctoring_overlay.dart   # Proctoring status overlay
│   └── utils/                        # (reserved for utilities)
├── test/
│   ├── auth_service_test.dart        # 9 tests: login validation, token, init
│   ├── lockdown_service_test.dart    # 8 tests: ExamConfig, LockdownViolation, AuthState
│   ├── moodle_api_service_test.dart  # 16 tests: courses, quizzes, attempts, errors
│   ├── models/
│   │   └── moodle_models_test.dart   # 15 tests: CourseInfo, QuizInfo, QuizAttempt
│   └── fixtures/
│       └── moodle_responses.dart     # Mock JSON fixtures for all API responses
├── android/                          # Android native code (LockdownPlugin, etc.)
├── ios/                              # iOS native code
├── macos/                            # macOS native code
├── windows/                          # Windows native code
├── .github/workflows/                # CI pipeline
├── pubspec.yaml
├── analysis_options.yaml
├── SETUP.md                          # Moodle admin setup guide
└── README.md
```

---

## Architecture

### Data Flow

```
User Input → Screens → AppProvider (ChangeNotifier) → Services → Moodle REST API
                              ↕
                        Secure Storage
                        (token, LMS URL, configs)
```

- **AppProvider** is the single source of truth. Screens `watch` or `read` it via `Provider`.
- **Services** are stateless helpers owned by AppProvider.
- **Screens** read state and call methods on AppProvider — never directly on services.

### Route Map (`app.dart`)

| Route | Screen | Auth Required |
|-------|--------|---------------|
| `/` | SplashScreen | No (checks) |
| `/login` | LoginScreen | No |
| `/dashboard` | DashboardScreen | Yes |
| `/exam-list` | ExamListScreen | Yes |
| `/exam-detail` | ExamDetailScreen | Yes |
| `/exam` | ExamScreen | Yes + config |
| `/admin-panel` | AdminPanelScreen | Yes (admin) |
| `/qr-scanner` | QrScannerScreen | Yes |
| `/config-key` | ConfigKeyScreen | Yes |
| `/results` | ResultsScreen | Yes |

---

## Authentication Flow

1. **Login screen** collects LMS URL, username, password
2. App calls `AuthService.login()` → HTTP POST to `{url}/login/token.php`
3. Moodle returns a **web service token** (stored in `flutter_secure_storage`)
4. App calls `core_webservice_get_site_info` to get user info (userId, role, name)
5. UserInfo is used to determine `isSiteAdmin` → dashboard role cards
6. Token + credentials kept in memory for WebView auto-login
7. On subsequent launches, `init()` reads stored token from secure storage

### Moodle Admin Requirements

Three settings must be enabled in Moodle:
1. **Enable web services** (`enablewebservices`)
2. **Enable REST protocol** (`webservice/rest:use`)
3. **Moodle mobile web service** (`moodle_mobile_app` external service)

---

## Exam Lifecycle

```
Dashboard → My Exams → Select Course → Select Quiz → Exam Detail → Start Exam
                                                                          ↓
                                                              Lockdown activated
                                                              WebView loads quiz
                                                              Proctoring starts
                                                                          ↓
                                                          User takes quiz in WebView
                                                                          ↓
                                                      Submit (JS injection) or manual
                                                                          ↓
                                                      endExam() called → lockdown off
                                                                          ↓
                                                      Navigate back to Dashboard
```

### `startExam(ExamConfig config)`

1. Stores config as `currentConfig`, records `examStartTime`
2. Activates OS lockdown via `LockdownService`
3. Builds `WebViewController` with domain restrictions, CSP, JS bridge
4. Stores credentials for WebView auto-login detection
5. Navigates to `config.moodleUrl`
6. Starts proctoring if enabled

### `endExam()`

1. Stops proctoring
2. Stops lockdown
3. Disposes WebView controller
4. Clears `currentConfig`
5. User can now navigate freely

---

## Moodle API Integration

File: `lib/services/moodle_api_service.dart`

All calls go to `{baseUrl}/webservice/rest/server.php` with `wstoken` and `wsfunction`.

| Method | Moodle Function | Returns | Used By |
|--------|----------------|---------|---------|
| `getUserCourses(userId)` | `core_enrol_get_users_courses` | `List<CourseInfo>` | Student enrolled courses |
| `getEnrolledCourses()` | `core_course_get_enrolled_courses_by_timeline_classification` | `List<CourseInfo>` | Fallback |
| `getAllCourses()` | `core_course_get_courses` | `List<CourseInfo>` | Admin courses tab, fallback |
| `getCourseQuizzes(courseIds)` | `mod_quiz_get_quizzes_by_courses` | `Map<int, List<QuizInfo>>` | Quiz list per course |
| `getUserAttempts(quizId)` | `mod_quiz_get_user_attempts` | `List<QuizAttempt>` | Attempt history |
| `getQuizAccessInfo(quizId)` | `mod_quiz_get_quiz_access_information` | `Map<String, dynamic>` | Access validation |

### Error Handling

- `MoodleApiException` for Moodle errors (exception in response) and HTTP errors
- `fetchCourses()` uses a **3-method fallback chain** so it works on most Moodle versions
- `core_course_get_courses` returns a JSON **array** (not wrapped in a map) — handled separately

---

## Key Screens

### Dashboard (`dashboard_screen.dart`)
- Welcome message with user name
- Role-based cards: Administrator (admin only), My Exams, Scan QR Code, Enter Config Key
- Account info section (username, role, LMS URL)
- Logout button in AppBar

### Admin Panel (`admin_panel_screen.dart`)
- **Dashboard tab**: Course/quiz counts, role, LMS URL
- **Courses tab**: Lists all courses from `core_course_get_courses` with "Quizzes" button
- **Exams tab**: Shows quizzes for selected course, lockdown config dialog
- **Monitor tab**: Live status of active exam session (lockdown, proctoring)

### Exam Detail (`exam_detail_screen.dart`)
- Shows quiz name, intro, time limit, attempts allowed, availability
- Lists lockdown features enforced during exam
- **Start Exam** button creates `ExamConfig` and calls `startExam()`

### Exam Screen (`exam_screen.dart`)
- Full-screen WebView with Moodle quiz
- Top toolbar: lock icon, exam title, countdown timer, info button, End Exam button
- Floating submit button (bottom-right)
- Lockdown indicator, proctoring overlay
- After submit → `endExam()` → navigate to `/dashboard`

### Login (`login_screen.dart`)
- LMS URL field (persisted across sessions)
- Username + password fields with validation
- Loading state during login, error display

---

## Dependencies

Key packages from `pubspec.yaml`:

| Package | Purpose |
|---------|---------|
| `flutter_secure_storage` | Token, LMS URL, config persistence |
| `http` | REST API calls |
| `webview_flutter` | Exam WebView |
| `provider` | State management |
| `qr_code_scanner` | QR code config import |
| `camera` + `image` | Proctoring snapshots |

---

## Build & Run

### Environment
```powershell
# Required per session:
$env:PATH = "C:\flutter\bin;$env:PATH"
$env:ANDROID_HOME = "C:\Users\Sub-Saharan College\AppData\Local\Android\Sdk"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
```

### Commands
```powershell
# Analyze
flutter analyze

# Test
flutter test

# Build APK (use Gradle directly due to space-in-path bug)
cd android
gradlew.bat assembleDebug
# APK at: android\app\build\outputs\flutter-apk\app-debug.apk
```

### Known Build Issues
- **Space in project path** (`Mobile SE`): `flutter build apk` fails post-Gradle APK discovery. Use `gradlew.bat assembleDebug` directly.
- **Kotlin incremental compilation**: Disabled in `gradle.properties` (`kotlin.incremental=false`)
- **Gradle daemon**: JVM args `-Xmx8G -XX:MaxMetaspaceSize=4G` in `gradle.properties`

---

## Testing

**51 tests total** — all pass.

| Test File | Count | What It Tests |
|-----------|-------|---------------|
| `auth_service_test.dart` | 9 | Configure, init, login validation, token, logout |
| `lockdown_service_test.dart` | 8 | ExamConfig parse/round-trip, LockdownViolation, AuthState |
| `moodle_models_test.dart` | 15 | CourseInfo, QuizInfo, QuizAttempt JSON + edge cases |
| `moodle_api_service_test.dart` | 19 | All API methods + error handling + request construction |

### Test Architecture

Uses `MockClient` (from `http/testing.dart`) with a `_mockHandler` router that switches on `wsfunction` POST field. Per-test overrides via `MockClientOptions` (function-specific response, HTTP error, network error).

---

## Git History

```
f50b178 Fix all reported issues: course loading quiz auth exam exit monitoring
578b43a Fix student enrolled courses admin courses tab quiz popup
bd888b8 Merge pull request #3 from sofianali2019/main
2495d9c Implement dashboard cards: My Exams QR Scanner Config Key Admin Panel
976f3e1 Merge pull request #2 from sofianali2019/master
9b6927b Merge pull request #1 from sofianali2019/main
3434660 Merge branch 'master'
66e52d4 Fix CI workflow to use Flutter 3.41.0 and master branch
1d46d3d Fix CI workflow to use Flutter 3.41.0 and master branch
554bba7 Add dashboard, UserInfo model, Moodle token auth
0a4d642 Initial commit: Secure Exam Browser Flutter app with ...
```

Local feature branches (not on remote):
- `feature/admin-panel`
- `feature/config-key`
- `feature/exam-list`
- `feature/exam-timer`
- `feature/moodle-api`
- `feature/qr-scanner`

---

## Known Issues & Decisions

### Architecture Decisions

1. **Token auth over OAuth2**: Moodle does not natively act as an OAuth2 server. `/login/token.php` with `service=moodle_mobile_app` is the correct mobile auth path.

2. **No OAuth2 dependency**: `flutter_appauth` was removed after discovering Moodle's OAuth2 endpoints only work when Moodle acts as an OAuth2 *client*, not server.

3. **WebView auto-login**: The web service token is NOT a Moodle session cookie. The WebView uses a login page detection + auto-fill approach to create a proper browser session.

4. **Fallback chain for courses**: Different Moodle versions/enablements support different API functions. The app tries `core_enrol_get_users_courses` → `core_course_get_courses` → `core_course_get_enrolled_courses_by_timeline_classification`.

5. **Space-in-path workaround**: Flutter CLI has a bug detecting APK paths with spaces. Build via Gradle directly.

### Known Issues

1. **Proctoring requires camera permission**: Android manifest includes camera permission, but runtime permission flow needs testing.

2. **Windows lockdown**: Windows kiosk mode requires Windows 10/11 Enterprise or Pro with MDM. Home edition not supported.

3. **iOS lockdown**: iOS/macOS lockdown plugins are written but untested (no macOS dev environment).

4. **Moodle version compatibility**: Tested against Moodle 4.x. Some API functions may not exist on Moodle 3.x.

5. **WebView popup handling**: Override of `window.open` redirects popups to the same WebView. Some Moodle themes/styles may not trigger this.

6. **CI only for `master` branch**: GitHub Actions workflow triggers on `master` pushes only.

### Moodle Admin Configuration

1. Site administration → Advanced features → Enable web services
2. Site administration → Plugins → Web services → Manage protocols → Enable REST protocol
3. Site administration → Plugins → Web services → External services → Add `moodle_mobile_app`
4. Site administration → Plugins → Web services → Manage tokens → Allow token creation

### Default LMS URL

`https://subsaharanlms.com` (configured in `lib/config/defaults.dart`)

### Application ID

`com.exambrowser.secure_exam_browser`
