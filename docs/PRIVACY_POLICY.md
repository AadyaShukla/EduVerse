# EduVerse Privacy Policy

**Effective Date**: August 1, 2026

## 1. Introduction & Overview
EduVerse ("we", "our", or "us") is dedicated to protecting student privacy, safety, and digital wellbeing. This Privacy Policy outlines our data collection, usage, cloud AI processing, and parental rights practices for our K-12 learning application.

---

## 2. Clarification of "Privacy-First" & Cloud Processing Disclosure

> [!IMPORTANT]
> **Cloud Processing Disclosure**: When you submit a question, OCR image text, or voice doubt, or generate a lecture/quiz, **the text of your question/topic is sent to Google's Gemini API over secure HTTPS for AI processing**.

Our "Privacy-First" commitment refers specifically to:
1. **On-Device Biometric & PIN Security**: Student PINs and biometric credentials are stored and verified strictly on-device using standard Android Keystore APIs. We do not use third-party OAuth trackers (e.g. Facebook Login).
2. **Zero Third-Party Advertising & Data Selling**: We do not display ads, participate in ad networks, or sell any user data to third parties.
3. **No Social/Public Broadcasts**: Student doubts, quizzes, and focus sessions are strictly 1-on-1 and private to the student and their linked guardian.

---

## 3. Data Flow Matrix: Local Storage vs Cloud Transmission

| Data Element | Stored Locally (On-Device) | Sent to Backend Server | Sent to Google Gemini API (Cloud) | Purpose |
|---|:---:|:---:|:---:|---|
| **PIN & Biometric Hashes** | **YES** | **NO** | **NO** | Local authentication & access control |
| **Doubt Question Text** | **YES** (Cached) | **YES** (HTTPS) | **YES** (HTTPS) | Generating step-by-step AI explanations |
| **OCR Image File / Camera Capture** | **YES** (Processed via ML Kit) | **NO** (Text only sent) | **NO** (Text only sent) | Extracting text on-device before sending text to API |
| **Voice STT Audio File** | **YES** (Processed via Android STT) | **NO** (Text only sent) | **NO** (Text only sent) | Converting voice to text on-device |
| **Quiz Topics & Scores** | **YES** (Cached) | **YES** (HTTPS) | **YES** (HTTPS - Topics) | Generating adaptive questions |
| **Notes & Timetable Items** | **YES** (Cached) | **YES** (Sync) | **NO** | Personal organization & study reminders |
| **Guardian Link Code & Email** | **YES** | **YES** | **NO** | 1-on-1 parent/guardian verification |

---

## 4. Children’s Privacy (COPPA & GDPR-K Compliance)
- **Grade < 7 Mandatory Guardian Link**: Students in grade < 7 require parent/guardian verification to activate their account.
- **Parental Rights**: Parents can request access to or permanent deletion of their child's data at any time through the in-app "Delete My Account & Data" option in Settings or by contacting privacy@eduverse.app.

---

## 5. Security & Data Deletion
All data transmitted between the app, backend, and Gemini API is encrypted via HTTPS / TLS 1.3. Students or guardians can permanently erase all account records and learning history at any time using the "Delete My Account & Data" button in Settings.
