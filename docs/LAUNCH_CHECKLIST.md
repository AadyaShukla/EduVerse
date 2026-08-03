# EduVerse Pre-Launch & Deployment Checklist

Complete this checklist prior to submitting **EduVerse** to Google Play Console.

---

## 1. Keystore & Signing Setup (Developer Step)

Run the Java `keytool` command locally to generate your private upload keystore. **DO NOT** commit the resulting `.jks` file or passwords to version control.

```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `frontend/android/key.properties` with your private details:

```properties
storePassword=<YOUR_STORE_PASSWORD>
keyPassword=<YOUR_KEY_PASSWORD>
keyAlias=upload
storeFile=../upload-keystore.jks
```

---

## 2. Release App Bundle (AAB) Build

From the `frontend` directory, execute:

```bash
flutter build appbundle --release
```

The output file will be generated at:
`frontend/build/app/outputs/bundle/release/app-release.aab`

---

## 3. Privacy Policy Public Hosting Requirement

Google Play Console requires a **live HTTPS URL** for your Privacy Policy.
- Host [docs/PRIVACY_POLICY.md](file:///c:/Users/Aadya/OneDrive/Desktop/EduVerse/docs/PRIVACY_POLICY.md) on GitHub Pages or your custom web domain (e.g. `https://aadyashukla.github.io/EduVerse/PRIVACY_POLICY.html`).
- Enter this live URL in **Play Console > App Content > Privacy Policy**.

---

## 4. Play Console Target Audience & COPPA Declarations

- **Target Age Groups**: Select `5 and under`, `6-8`, `9-12`, and `13-17`.
- **Neutral Age Screen**: Confirmed (Age-gate checks student grade).
- **Parental Consent**: Confirmed (Grade < 7 accounts require mandatory parent linking).
- **Ads / Trackers**: Declare `No Ads`.

---

## 5. Closed Testing Track Setup

1. Create a **Closed Testing Track** in Play Console.
2. Upload `app-release.aab`.
3. Add at least 12–20 internal test users.
4. Verify end-to-end installation and performance on physical Android devices.
