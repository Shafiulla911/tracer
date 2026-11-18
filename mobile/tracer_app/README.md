# TRACER — Flutter Mobile App

> **Cyber Security Scam Reporting & Tracking Platform**
> *Track. Report. Protect.*

---

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Android Studio / VS Code with Flutter extension
- Android emulator or physical device

### 1. Navigate to the project
```bash
cd c:\shafi\tracer\mobile\tracer_app
```

### 2. Update `android/local.properties`
Add your Flutter SDK path:
```properties
sdk.dir=C:\\Users\\<YourUser>\\AppData\\Local\\Android\\Sdk
flutter.sdk=C:\\src\\flutter
flutter.buildMode=debug
flutter.versionName=1.0.0
flutter.versionCode=1
```

### 3. Install dependencies
```bash
flutter pub get
```

### 4. Run the app
```bash
# On Android emulator
flutter run

# Release build
flutter build apk --release
```

---

## 📁 Project Structure

```
lib/
├── main.dart                        # Entry point, theme config
├── constants/
│   └── app_constants.dart           # API URL, colors, constants
├── models/
│   ├── scammer.dart                 # Scammer data model
│   ├── report.dart                  # Report data model
│   └── track_log.dart               # Track log data model
├── services/
│   ├── api_service.dart             # All HTTP API calls
│   └── storage_service.dart         # SharedPreferences persistence
├── providers/
│   └── app_provider.dart            # ChangeNotifier state management
├── screens/
│   ├── splash_screen.dart           # Animated splash
│   ├── home_screen.dart             # Dashboard + bottom nav
│   ├── report_screen.dart           # Report a scammer form
│   ├── search_screen.dart           # Search by phone/UPI
│   ├── scammer_detail_screen.dart   # Full profile + map
│   ├── trap_link_screen.dart        # Trap link share + logs
│   └── my_reports_screen.dart       # Locally stored reports
├── widgets/
│   ├── custom_button.dart           # Gradient buttons
│   ├── scammer_card.dart            # Red warning card
│   ├── stat_card.dart               # Stats dashboard card
│   └── track_log_card.dart          # IP/location log card
└── utils/
    └── helpers.dart                 # Date, currency, validation
```

---

## 🔧 Configuration

### Change API Base URL
Edit `lib/constants/app_constants.dart`:
```dart
static const String baseUrl = 'http://10.0.2.2:8000';  // Android emulator → localhost
// For physical device: use your machine's LAN IP e.g. http://192.168.1.100:8000
// For production: https://api.yourtracer.com
```

---

## 🎨 Design System

| Token | Value | Usage |
|---|---|---|
| Primary | `#C62828` | Danger, warnings, scammer flags |
| Secondary | `#0D1B2A` | App bar, dark headers |
| Accent | `#FF6D00` | Icons, highlights |
| Background | `#121212` | Scaffold background |
| Card | `#1E1E2E` | Cards, containers |
| Success | `#00C853` | Confirmation, clean results |

---

## 📱 Screens

| Screen | Description |
|---|---|
| Splash | Animated shield logo with fade-in |
| Home | Stats dashboard + quick actions + recent reports |
| Report | Multi-field scammer report form with validation |
| Search | Real-time phone/UPI search with danger/safe cards |
| Scammer Detail | Full profile + tabbed reports + map with markers |
| Trap Link | Copy/Share link + live tracking results |
| My Reports | Locally stored filed reports + generate new links |

---

## ⚠️ Notes

- **Internet permission** is set in `AndroidManifest.xml` with `usesCleartextTraffic="true"` for local dev.
- For production, switch to HTTPS and remove cleartext traffic.
- Map tiles use OpenStreetMap (free, no API key needed).
- `shared_preferences` stores report IDs locally — clearing app data removes them.
