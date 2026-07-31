# EduVerse Architecture & Auth Flow

## Overview
EduVerse is a student learning app scaffolded with a Flutter frontend and a FastAPI backend. It leverages Supabase (PostgreSQL) for the database.

## Authentication Flow
The primary authentication mechanism is completely localized using device-native features (Android Keystore via `flutter_secure_storage` and `local_auth`), with no reliance on Firebase Auth or SMS/Email OTPs for the main login.

1. **Local PIN/Biometric Login**:
   - The user registers a PIN or uses device biometrics (fingerprint/face).
   - A secure token or session state is stored in the Android Keystore.
   - On subsequent app launches, local authentication (PIN or Biometric) grants access.

2. **Account Recovery (TOTP)**:
   - For account recovery (e.g., if a PIN is forgotten), a Time-Based One-Time Password (TOTP) mechanism is used.
   - During signup, a TOTP secret is generated and shared with the user (e.g., as a QR code or text to add to an Authenticator app).
   - If recovery is needed, the user provides a TOTP code which is verified against the backend.

## Age-Gate & Guardian Linking
- **Age < 7**: If a student signs up with a grade < 7, `parent_link_required` is set to `true`. Their account is blocked from full activation until a `guardians` record exists and is linked via `student_guardian_links`.
- **Age >= 7**: If grade >= 7, account activates immediately. Guardian linking is optional via an invite-code endpoint.

## Data Storage
- **Backend Database**: Supabase (PostgreSQL) handles all relational data.
- **Local Storage**: Offline caching and local app state are managed using SQLite via the `sqflite` package in Flutter.
