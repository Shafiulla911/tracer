# TRACER — Cyber-Security Scam Reporting & Tracking Platform

TRACER is a counter-fraud intelligence platform designed to report fraudulent contacts (UPI / phone numbers), analyze scam patterns via AI, deploy honeypot trap links to extract fraudster geolocation and device signatures, and export police evidence dockets.

---

## 🏗️ Architecture

- **Backend (`/backend`)**: FastAPI, SQLite / SQLAlchemy, OpenStreetMap / Nominatim geolocation reverse-coding, ReportLab PDF docket generation, AI threat pattern classification.
- **Mobile (`/mobile/tracer_app`)**: Flutter app with modern Sentinel Cyber-FinTech dark theme, dynamic threat gauges, OpenStreetMap live markers, tactical radar sweep animations, and instant trap deployment.

---

## 🚀 Getting Started

### 1. Backend Setup (FastAPI)
```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Mobile App Setup (Flutter)
```bash
cd mobile/tracer_app
flutter pub get
flutter run
```

To build a standalone Android debug APK:
```bash
flutter build apk --debug
```
The APK will be generated at `build/app/outputs/flutter-apk/app-debug.apk`.
