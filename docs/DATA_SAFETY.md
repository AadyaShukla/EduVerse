# EduVerse Google Play Store Data Safety Form Mapping

This reference document maps EduVerse's privacy and data practices to the official **Google Play Console Data Safety** questionnaire requirements.

---

## 1. Data Collection & Sharing Summary

| Play Store Category | Data Type | Collected | Shared | Purpose | Optional / Mandatory |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Personal Info** | Name | Yes | No | Account Management & Personalization | Mandatory |
| **Personal Info** | Email Address | Yes (Guardians only) | No | Account Verification & Linking | Mandatory for Guardians |
| **Personal Info** | Grade Level | Yes | No | Content Personalization | Mandatory |
| **App Activity** | In-app Search / Doubts | Yes | No | AI Doubt Explanation | Optional |
| **App Activity** | Quiz History & Notes | Yes | No | App Functionality & Analytics | Optional |
| **Photos & Videos** | Photos (OCR scan) | Processed locally on-device | No | On-device ML Kit OCR Text Extraction | Optional |
| **Audio Files** | Voice Recordings | Processed locally on-device | No | Native Speech-to-Text Conversion | Optional |

---

## 2. Security Practices

- **Data Encrypted in Transit**: Yes (HTTPS / TLS 1.3).
- **Data Deletion Request Mechanism**: Yes. Users can delete all profile and learning data directly within the app (`Settings > Delete My Account & Data`).
- **Target Audience / Families Policy**: Designed for Students (K-12). Complies with Google Play Families Policy & COPPA regulations.
- **Third-Party SDK Trackers**: None. No ad SDKs, analytics tracking SDKs, or social login trackers are embedded.
