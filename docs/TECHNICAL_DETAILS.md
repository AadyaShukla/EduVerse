# EduVerse Technical System Architecture & Algorithmic Specifications

This document provides a plain, transparent technical description of the algorithms, heuristics, and data structures implemented in **EduVerse**.

---

## 1. Weak Topic Detection

- **Implementation**: Deterministic Frequency-Based Counter.
- **Data Model**: `cached_weak_topics` / `weak_topics` (schema: `student_id`, `topic`, `times_wrong`, `last_updated`).
- **Algorithm**:
  - When a student completes an adaptive quiz or mock assessment, any question answered incorrectly increments the `times_wrong` counter for that specific topic by `+1`.
  - Topics with `times_wrong >= 2` are classified as **Weak Topics** and prioritized in upcoming quiz generation prompts.
- **Clarification**: This is a direct frequency-based counter, not a machine learning model or Bayesian knowledge tracing system.

---

## 2. Adaptive Quiz Difficulty Engine

- **Implementation**: Rule-Based Score Threshold Evaluator.
- **Evaluation Logic**:
  - **High Performance (`Score > 80%`)**: The next quiz for the same topic is generated with `difficulty = "hard"`, prompting Gemini for higher-order application & analytical questions.
  - **Moderate Performance (`50% <= Score <= 80%`)**: The next quiz maintains `difficulty = "medium"`.
  - **Low Performance (`Score < 50%`)**: The next quiz is generated with `difficulty = "easy"`, focusing on foundational concept recall.
- **Prompt Engineering**: Difficulty parameter is directly injected into the System Prompt sent to the Google Gemini API.

---

## 3. Spaced Repetition Scheduling

- **Implementation**: Fixed Interval Reminder Matrix.
- **Schedule Spacing**:
  - **Interval 1**: 24 hours (1 day) after initial review.
  - **Interval 2**: 72 hours (3 days) after initial review.
  - **Interval 3**: 168 hours (7 days) after initial review.
- **Clarification**: Revision notifications follow these fixed time intervals rather than adaptive algorithmic spacing models like SuperMemo (SM-2) or Anki E-Factor decay curves.

---

## 4. Local SQLite Caching & Offline Sync Queue

- **Local Storage Engine**: SQLite (`sqflite` v2.3.2) writing to local SQLite database file `eduverse_offline_v2.db`.
- **Sync Engine**: FIFO Queue (`sync_queue` table).
  - When offline: User actions (creating notes, completing quizzes, modifying schedule) are serialized to JSON payload strings and queued in `sync_queue`.
  - When connection is restored: The app iterates through `sync_queue` in chronological order and posts buffered payloads to Supabase.
