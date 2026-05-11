# 🔭 Gama Physics — EdTech Mobile App

<p align="center">
  <img src="assets/images/GAMA.png" width="120" alt="Gama Physics Logo"/>
</p>

<p align="center">
  <strong>A full-featured physics education platform built with Flutter & Firebase</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black"/>
  <img src="https://img.shields.io/badge/Android-Ready-3DDC84?style=for-the-badge&logo=android&logoColor=white"/>
  <img src="https://img.shields.io/badge/iOS-Ready-000000?style=for-the-badge&logo=apple&logoColor=white"/>
  <img src="https://img.shields.io/badge/Windows-Ready-0078D6?style=for-the-badge&logo=windows&logoColor=white"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
</p>

---

## 📱 Platform Support

| Platform | Status |
|----------|--------|
| 🤖 Android | ✅ Fully Supported |
| 🍎 iOS | ✅ Fully Supported |
| 🪟 Windows | ✅ Fully Supported |

> The app is production-ready and tested across all three platforms with platform-specific optimizations (notifications, PDF viewer, file export, video streaming).

---

## 📖 About

**Gama Physics** is a complete EdTech solution connecting students with their physics teacher. It supports video lessons (YouTube & Google Drive), access code monetization, QR-based attendance, push notifications, and full bilingual support (Arabic/English).

---

## ✨ Features

### 👨‍🎓 Student Side
- 📲 **Phone-based Authentication** — register & login with phone number + password
- 🎥 **Video Lessons** — stream YouTube and Google Drive videos natively inside the app
- 🔐 **Access Codes** — enter a code to unlock paid lessons
- 📄 **PDF & Image Viewer** — view lesson materials directly in-app
- 🔔 **Push Notifications** — get notified instantly when new announcements are posted
- 📢 **Announcements** — read teacher announcements with PDF/image attachments
- 🪪 **QR Code Profile** — each student gets a unique QR code + student code for attendance
- 🌐 **Bilingual UI** — full Arabic & English support with RTL layout
- 📴 **Offline Support** — cached session data works without internet

### 👨‍🏫 Teacher / Admin Side
- 📊 **Teacher Dashboard** — full control panel with statistics
- 🗂️ **Content Management** — manage stages → semesters → lessons hierarchy
- 💳 **Access Code System** — generate, manage, and expire codes per lesson
- 👥 **Student Management** — view, disable, delete students with QR display
- 📋 **QR Attendance** — scan student QR codes to take attendance in real-time
- 💰 **Payment Tracking** — record per-student payments and export to PDF
- 👁️ **Lesson Viewers** — see exactly who watched each lesson and how many times
- 📢 **Announcements** — post announcements with PDF/image attachments + push notifications
- 📊 **Excel Export** — export student lists and access codes to `.xlsx`
- 📄 **PDF Export** — generate professional attendance & student reports

---

## 🏗️ Tech Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter 3.x (Dart) |
| **Backend** | Firebase (Auth, Firestore, FCM) |
| **State Management** | Provider |
| **Video Streaming** | `video_player` + `fvp` + `youtube_explode_dart` |
| **PDF Viewer** | `webview_flutter` |
| **QR Code** | `qr_flutter` + `mobile_scanner` |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **Excel Export** | `excel` package |
| **PDF Generation** | `pdf` + `printing` |
| **Localization** | Flutter `intl` + ARB files (AR/EN) |
| **Local Cache** | `shared_preferences` |

---

## 📂 Project Structure

```
lib/
├── config/
│   ├── theme.dart           # App theme & colors
│   └── routes.dart          # Named routes
├── models/                  # Data models
│   ├── app_user.dart
│   ├── lesson.dart
│   ├── access_code.dart
│   ├── attendance_session.dart
│   ├── announcement.dart
│   └── video_view.dart
├── providers/               # State management
│   ├── auth_provider.dart
│   ├── data_provider.dart
│   └── language_provider.dart
├── screens/
│   ├── auth/                # Login & register screens
│   ├── student/             # Student-facing screens
│   └── teacher/             # Teacher dashboard & management
├── services/                # Business logic & Firebase
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── youtube_service.dart
│   ├── video_view_service.dart
│   ├── notification_service.dart
│   └── pdf_service.dart
├── widgets/                 # Reusable UI components
│   ├── video_player_widget.dart
│   ├── pdf_viewer_widget.dart
│   ├── lesson_card.dart
│   └── drive_image_viewer_widget.dart
└── l10n/                    # Arabic & English translations
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Firebase project (with Auth, Firestore, FCM enabled)
- Android Studio / Xcode / Visual Studio (for target platform)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-username/gama-physics.git
cd gama-physics

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase
# Replace lib/firebase_options.dart with your own Firebase config
# (generated via FlutterFire CLI)
flutterfire configure

# 4. Run the app
flutter run
```

### Platform-Specific Notes

**Android**
```bash
flutter run -d android
```
- Requires minimum SDK 21
- FCM notifications fully supported
- Downloads saved to `/storage/emulated/0/Download`

**iOS**
```bash
flutter run -d ios
```
- Requires iOS 12+
- FCM via APNs — configure in `ios/Runner/Info.plist`
- Files saved to app Documents directory

**Windows**
```bash
flutter run -d windows
```
- PDF files open in default browser (no embedded WebView)
- Video playback via `fvp` (hardware accelerated)
- Excel & PDF exports saved to `Downloads` folder

---

## 🔥 Firebase Setup

Create a Firebase project and enable:

- ✅ **Authentication** — Email/Password (phone stored as email format)
- ✅ **Firestore Database** — with the collections below
- ✅ **Cloud Messaging (FCM)** — for push notifications

### Firestore Collections

```
users/           → student & teacher profiles
stages/          → academic stages
semesters/       → semesters per stage
lessons/         → lessons per semester
accessCodes/     → paid lesson access codes
attendance/      → attendance sessions
announcements/   → teacher announcements
announcementViews/ → tracks who read each announcement
videoViews/      → tracks who watched each lesson
```

### Firestore Security Rules (basic example)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
    match /lessons/{id} {
      allow read: if request.auth != null;
      allow write: if false; // Teacher writes via admin SDK or special UID check
    }
  }
}
```

---

## 🌍 Localization

The app supports full **Arabic (RTL)** and **English (LTR)** switching at runtime.

- Translation files: `lib/l10n/app_localizations_ar.dart` & `app_localizations_en.dart`
- Language preference is persisted via `SharedPreferences`
- RTL/LTR layout switches automatically with the language

---

## 📸 Screenshots

> *(Add your screenshots here)*

| Splash Screen | Student Home | Lesson Player |
|---|---|---|
| ![](screenshots/splash.png) | ![](screenshots/home.png) | ![](screenshots/player.png) |

| Teacher Dashboard | QR Attendance | Access Codes |
|---|---|---|
| ![](screenshots/dashboard.png) | ![](screenshots/attendance.png) | ![](screenshots/codes.png) |

---

## 📦 Key Dependencies

```yaml
dependencies:
  firebase_core:
  firebase_auth:
  cloud_firestore:
  firebase_messaging:
  flutter_local_notifications:
  provider:
  video_player:
  fvp:                        # Hardware video decoding
  youtube_explode_dart:       # YouTube stream extraction
  webview_flutter:            # PDF viewer
  mobile_scanner:             # QR code scanner
  qr_flutter:                 # QR code generator
  pdf:                        # PDF generation
  printing:                   # PDF share/print
  excel:                      # Excel export
  shared_preferences:         # Local cache
  flutter_localizations:      # i18n
  google_fonts:               # Cairo & Figtree fonts
  path_provider:
  url_launcher:
```

---

## 🤝 Contributing

This is a private educational project. For inquiries, reach out via LinkedIn.

---

## 📄 License

© 2026 Gama Physics. All rights reserved.

---

<p align="center">
  Built with ❤️ using Flutter & Firebase
  <br/>
  <strong>Android • iOS • Windows</strong>
</p>
