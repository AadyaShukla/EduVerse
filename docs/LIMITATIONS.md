# EduVerse Operational Limitations & Scope Disclosures

This document explicitly outlines the technical, infrastructural, and regulatory limitations of the current **EduVerse** release.

---

## 1. Unmeasured Empirical Performance Benchmarks

- **OCR Accuracy**: On-device text recognition (via Google ML Kit) has not undergone formal quantitative benchmark testing across varied lighting conditions, handwriting styles, or mathematical notations.
- **API Response Latency**: End-to-end response latency for Gemini API doubt solving and lecture script generation depends on external network connectivity and server-side model processing times.
- **Pedagogical Outcomes**: Learning outcomes, retention rates, and academic performance improvements have not yet been evaluated through formal clinical or empirical field trials.

---

## 2. Infrastructure & Rate Limits

- **Free-Tier Constraints**: The system currently runs on Google Gemini API free-tier quotas. Rate-limit throttles (RPM/TPM) may occur under high load.
- **Concurrency & Load Testing**: The architecture has not been stress-tested for large-scale concurrent user spikes (e.g. thousands of simultaneous active users).

---

## 3. Regulatory & Design Assumptions

- **Grade 7 Guardian Threshold**: The requirement for mandatory parent/guardian account activation for students in grade < 7 is a design assumption based on general K-12 age-gating guidelines. It does not constitute a formal legal or regulatory certification under COPPA or GDPR-K.
