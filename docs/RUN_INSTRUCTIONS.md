# EduVerse Environment Setup & Execution Guide

This document provides exact instructions to set up, run, and test the **EduVerse** FastAPI backend and Flutter Android frontend on local network physical devices (such as a OnePlus phone connected via USB).

---

## 1. Backend File Structure & Entry-Point Explanation

The backend code is organized under the `/backend` folder as follows:

```text
EduVerse/
├── backend/
│   ├── app/
│   │   ├── main.py          <-- Main FastAPI Entry Point (app object)
│   │   ├── core/
│   │   │   ├── config.py    <-- Settings & Environment Variable Loader
│   │   │   └── security.py
│   │   ├── api/v1/          <-- Router and Endpoints
│   │   ├── db/              <-- Supabase Client & Mock Store
│   │   ├── schemas/         <-- Pydantic Data Models
│   │   └── services/        <-- Gemini, Auth, Quiz & Wellbeing Logic
│   ├── tests/
│   ├── .env                 <-- Environment Variables (Create from .env.example)
│   └── requirements.txt     <-- Complete Backend Dependencies
```

### Why `uvicorn main:app` Failed
When running inside `/backend`, executing `uvicorn main:app` fails with `ERROR: Could not import module 'main'` because `main.py` is nested inside `app/main.py`.

### Correct Uvicorn Command
- **From inside `/backend`**:
  ```bash
  uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
  ```
- **From root workspace directory**:
  ```bash
  uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
  ```
  *(Note: `--host 0.0.0.0` is required so the backend binds to all local network interfaces and is reachable by physical devices on your Wi-Fi network).*

---

## 2. Setting Up Python Environment & Environment Variables

### A. Create & Activate Virtual Environment
From inside `/backend`:
```powershell
# Windows PowerShell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

### B. Install Complete Dependencies
```powershell
pip install -r requirements.txt
```

### C. Create `.env` File
Create `backend/.env` (located at `EduVerse/backend/.env`):

```env
PROJECT_NAME="EduVerse API"
VERSION="1.0.0"
API_V1_STR="/api/v1"
ENVIRONMENT="development"

# Supabase (Optional - Mock fallback store will be used if left empty)
SUPABASE_URL=""
SUPABASE_KEY=""

# Google Gemini API Key (Required for live Gemini LLM responses)
GEMINI_API_KEY="YOUR_GEMINI_API_KEY_HERE"
```

### D. Start Backend Server
From inside `/backend`:
```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
- Open Swagger UI in browser: `http://localhost:8000/docs`
- Open Web Hub in browser: `http://localhost:8000/`

---

## 3. Configuring Flutter Frontend for Physical Android Devices

To test on a physical Android device over Wi-Fi or USB, update the API base URL in [frontend/lib/core/constants/app_constants.dart](file:///c:/Users/Aadya/OneDrive/Desktop/EduVerse/frontend/lib/core/constants/app_constants.dart).

### Target URL Guidelines:
1. **Physical Device (USB / Same Wi-Fi)**: Use your computer's local Wi-Fi IP (e.g., `http://192.168.x.x:8000/api/v1`).
2. **Android Emulator**: Uses `http://10.0.2.2:8000/api/v1`.
3. **Web / Localhost**: Uses `http://localhost:8000/api/v1`.

### How to Find Your Local IP on Windows:
Run in PowerShell:
```powershell
ipconfig
```
Look for `IPv4 Address` under your Wi-Fi adapter (e.g., `192.168.1.15`).

### Update [app_constants.dart](file:///c:/Users/Aadya/OneDrive/Desktop/EduVerse/frontend/lib/core/constants/app_constants.dart):
```dart
class AppConstants {
  static const String appName = 'EduVerse';

  // For Physical Device (Replace 192.168.x.x with your PC's local IP):
  static const String baseUrl = 'http://192.168.x.x:8000/api/v1';

  // For Android Emulator:
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
}
```

---

## 4. Running on a Physical Android Device (e.g., OnePlus)

### Step 1: Enable USB Debugging on Your OnePlus Device
1. On your phone: Open **Settings** $\rightarrow$ **About Device** $\rightarrow$ **Version** $\rightarrow$ Tap **Build Number** 7 times until it says *"You are now in Developer Mode!"*.
2. Go to **Settings** $\rightarrow$ **System / Additional Settings** $\rightarrow$ **Developer Options**.
3. Enable **USB Debugging**.

### Step 2: Connect Phone via USB
1. Plug your OnePlus phone into your computer via USB cable.
2. When prompted on your phone screen, select **Transfer Files / MTP** and check **"Always allow from this computer"** when asked for USB Debugging permission.

### Step 3: Verify Device Detection
1. **Check via ADB**:
   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
   ```
   *Expected Output:*
   ```text
   List of devices attached
   a1b2c3d4    device
   ```

2. **Check via Flutter**:
   ```powershell
   flutter devices
   ```
   *Expected Output:*
   ```text
   OnePlus (mobile) • a1b2c3d4 • android-arm64 • Android 13/14
   ```

### Step 4: Run the App on the Device
From the `/frontend` directory:

```powershell
cd frontend
flutter run -d android
```

Or target the exact device ID:
```powershell
flutter run -d <DEVICE_ID>
```
*(Replace `<DEVICE_ID>` with the ID shown in `flutter devices`, e.g., `flutter run -d a1b2c3d4`)*.
