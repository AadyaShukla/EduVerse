# EduVerse System Architecture & Phase 0 Technical Document

## Overview
EduVerse is an AI-powered personal learning application designed for school students. Phase 0 establishes the foundation:
- Single-codebase Flutter Android frontend with Clean Architecture and Riverpod state management.
- FastAPI Python backend interfacing with Supabase PostgreSQL and Google Gemini API.
- Local biometric/PIN authentication backed by Android Keystore (`flutter_secure_storage` & `local_auth`).
- Account recovery via TOTP (Time-based One-Time Password) avoiding reliance on SMS/Email gateways.
- Automatic Age-Gating rule based on school grade.

---

## Architecture Blueprint

```
+-----------------------------------------------------------------------+
|                           FLUTTER FRONTEND                            |
|  [Splash] ---> [Auth/Signup (PIN/Biometric/TOTP)] ---> [Home Shell]  |
|                                                                       |
|  - Riverpod State Management (AuthProvider, StudentProvider)          |
|  - Local Auth Service (Android Keystore via flutter_secure_storage)   |
|  - Local Database Service (SQLite sqflite for offline sync)           |
+-----------------------------------+-----------------------------------+
                                    | HTTP / REST
                                    v
+-----------------------------------------------------------------------+
|                            FASTAPI BACKEND                            |
|  - Endpoints: /api/v1/auth, /api/v1/guardians, /api/v1/lectures      |
|  - Age-Gate Evaluator Service                                         |
|  - PyOTP TOTP Generator & Validator                                   |
|  - Gemini API Client Service Scaffold                                 |
+-----------------------------------+-----------------------------------+
                                    |
                                    v
+-----------------------------------------------------------------------+
|                          SUPABASE POSTGRESQL                          |
|  - Tables: students, guardians, student_guardian_links, sessions      |
+-----------------------------------------------------------------------+
```

---

## Age-Gating Logic
- **Condition**: Checked upon student registration (`grade`).
- **Grade < 7 (Underage / Primary School)**:
  - `parent_link_required = true`
  - `is_active = false`
  - **Behavior**: Account activation is BLOCKED. The frontend renders an Age-Gate screen preventing full access until a linked guardian completes verification.
- **Grade >= 7 (Middle/High School)**:
  - `parent_link_required = false`
  - `is_active = true`
  - **Behavior**: Account activates IMMEDIATELY. An optional invite code can be generated for parent linking at any time.

---

## Authentication & Account Recovery Model
1. **Local Authentication**:
   - The user configures a 4 to 6 digit PIN or Biometric credential on sign-up.
   - The PIN hash and secret token are stored securely in Android Keystore via `flutter_secure_storage`.
2. **TOTP Account Recovery**:
   - During registration, the backend generates a unique `totp_secret` using `pyotp.random_base32()`.
   - The QR code URI (`otpauth://...`) is presented to the user to back up into Google Authenticator or Microsoft Authenticator.
   - In case of lost PIN or device transfer, the user provides their Student ID and current 6-digit TOTP token to authenticate and reset local PIN credentials.

---

## API Routes Specification

### `/api/v1/auth`
- `POST /register`: Registers a new student, applies age-gating rules, returns student details & initial TOTP secret.
- `POST /login-local`: Validates local PIN authentication payload against active student account.
- `POST /totp/setup`: Generates a new TOTP secret & QR code uri.
- `POST /totp/verify`: Verifies a 6-digit TOTP token for account recovery or PIN reset.

### `/api/v1/guardians`
- `POST /invite-code`: Generates a unique 6-digit invite code for student-guardian linking.
- `POST /link`: Links a guardian account with a student via invite code.

### `/api/v1/lectures`
- `GET /sessions`: Retrieves active lecture sessions for the authenticated student.
- `POST /sessions`: Scaffolds creating/pausing a lecture session segment.
