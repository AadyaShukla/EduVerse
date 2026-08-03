# Google Play Console Data Safety Questionnaire Answers

Use this guide when filling out the mandatory **Data Safety** section in Google Play Console.

---

## Section 1: Data Collection & Security

1. **Does your app collect or share any of the required user data types?**
   - **Answer**: `Yes`

2. **Is all of the user data collected by your app encrypted in transit?**
   - **Answer**: `Yes` (All API endpoints operate over HTTPS / TLS 1.3 encryption).

3. **Do you provide a way for users to request that their data be deleted?**
   - **Answer**: `Yes` (In-app "Delete My Account & Data" button under `Settings > Privacy & Data Control`).

---

## Section 2: Data Types Breakdown

### A. Personal Information
- **Name**:
  - **Collected**: `Yes`
  - **Shared**: `No`
  - **Purpose**: `App functionality`, `Account management`
  - **Ephemeral**: `No`
  - **Required / Optional**: `Required`
- **Email Address** (Guardians only):
  - **Collected**: `Yes`
  - **Shared**: `No`
  - **Purpose**: `Account management`, `Parental verification`
  - **Required / Optional**: `Required for Guardians`

### B. App Activity
- **In-app Search History / Doubts**:
  - **Collected**: `Yes`
  - **Shared**: `No`
  - **Purpose**: `App functionality`, `Personalization`
  - **Required / Optional**: `Optional`
- **Other User-Generated Content (Notes & Quizzes)**:
  - **Collected**: `Yes`
  - **Shared**: `No`
  - **Purpose**: `App functionality`
  - **Required / Optional**: `Optional`

### C. Photos & Videos
- **Photos (OCR Scanning)**:
  - **Collected / Processed**: `Processed on-device only` (ML Kit Text Recognition)
  - **Shared**: `No`
  - **Purpose**: `App functionality`

### D. Audio Files
- **Voice Recordings (Speech-to-Text)**:
  - **Collected / Processed**: `Processed on-device only` (Android Speech Recognizer)
  - **Shared**: `No`
  - **Purpose**: `App functionality`

---

## Section 3: Third-Party Advertising & Tracking

- **Contains Ads**: `No`
- **Third-Party Trackers**: `None`
- **Families Policy Compliance**: `Yes`
