import uuid
import json
import re
from datetime import datetime, timezone, timedelta
from typing import Dict, Any, List, Tuple
from app.db.supabase_client import db
from app.schemas.quiz import (
    QuizGenerateRequest, QuizResponse, QuizQuestion,
    QuizAttemptSubmit, QuizAttemptResponse, WeakTopicResponse,
    RevisionScheduleResponse, MockExamRequest
)
from app.services.gemini_service import gemini_service

class QuizService:
    """
    Service for Adaptive Quiz Generation, Mock Exams, Weak-Topic Tracking,
    and Spaced Repetition Scheduling.
    """

    @classmethod
    def evaluate_adaptive_difficulty(cls, student_id: str, topic: str) -> str:
        """
        Calculates adaptive difficulty level based on past attempts for this topic:
        - Past Avg > 80% => 'hard'
        - Past Avg < 50% => 'easy'
        - Otherwise => 'medium'
        """
        attempts = []
        if db.is_live:
            res = db.client.table("quiz_attempts").select("score").eq("student_id", student_id).execute()
            attempts = [a["score"] for a in (res.data or [])]
        else:
            attempts = [
                v["score"] for v in db._mock_lectures.values() if v.get("score") is not None and v.get("student_id") == student_id
            ]

        if not attempts:
            return "medium"

        avg_score = sum(attempts) / len(attempts)
        if avg_score > 80.0:
            return "hard"
        elif avg_score < 50.0:
            return "easy"
        return "medium"

    @classmethod
    async def generate_quiz(cls, payload: QuizGenerateRequest) -> QuizResponse:
        quiz_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc)
        difficulty = cls.evaluate_adaptive_difficulty(payload.student_id, payload.topic)

        prompt = f"""
You are an expert educational quiz creator.
Topic: {payload.topic}
Difficulty Level: {difficulty} (If easy: foundational concepts; If hard: deep analytical problem solving)
Context/Notes: {payload.notes_text or 'Standard curriculum'}
Number of questions: {payload.num_questions}

Generate a mix of Multiple Choice (MCQ) and Short Answer questions.
Return ONLY valid JSON with this exact schema:
{{
  "questions": [
    {{
      "id": "q1",
      "type": "mcq",
      "question": "What is ...?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct_answer": "Option A",
      "explanation": "Brief explanation why Option A is correct."
    }},
    {{
      "id": "q2",
      "type": "short_answer",
      "question": "Explain the concept of ...",
      "options": null,
      "correct_answer": "Expected key phrase",
      "explanation": "Explanation of core concept."
    }}
  ]
}}
"""
        questions_list = []
        if gemini_service.is_configured:
            res = await gemini_service.generate_response_stub(prompt, student_grade=8)
            raw = res.get("text", "")
            try:
                match = re.search(r'\{.*\}', raw, re.DOTALL)
                if match:
                    parsed = json.loads(match.group(0))
                    questions_list = [QuizQuestion(**q) for q in parsed.get("questions", [])]
            except Exception:
                pass

        if not questions_list:
            # Fallback mock questions generator
            questions_list = [
                QuizQuestion(
                    id="q1",
                    type="mcq",
                    question=f"Which fundamental principle governs '{payload.topic}'?",
                    options=[
                        f"Standard Rule of {payload.topic}",
                        "Law of Conservation of Energy",
                        "Pythagorean Theorem",
                        "Newton's First Law"
                    ],
                    correct_answer=f"Standard Rule of {payload.topic}",
                    explanation=f"The Standard Rule of {payload.topic} is the primary theorem applied in this subject."
                ),
                QuizQuestion(
                    id="q2",
                    type="mcq",
                    question=f"What is the key application of {payload.topic} in real-world problem solving?",
                    options=[
                        "System Optimization",
                        "Data Normalization",
                        "Structural Modeling",
                        "All of the above"
                    ],
                    correct_answer="All of the above",
                    explanation=f"Applications of {payload.topic} span across optimization, modeling, and analysis."
                ),
                QuizQuestion(
                    id="q3",
                    type="short_answer",
                    question=f"Define the main objective of {payload.topic} in 1-2 sentences.",
                    options=None,
                    correct_answer="Analysis and problem solving",
                    explanation=f"{payload.topic} aims to analyze fundamental rules and apply them to solve problem sets."
                )
            ]

        questions_json = [q.model_dump() for q in questions_list]

        db_record = {
            "id": quiz_id,
            "student_id": payload.student_id,
            "topic": payload.topic,
            "difficulty": difficulty,
            "questions_json": questions_json,
            "created_at": now.isoformat()
        }

        if db.is_live:
            db.client.table("quizzes").insert(db_record).execute()
        else:
            db._mock_lectures[quiz_id] = db_record

        return QuizResponse(
            id=quiz_id,
            student_id=payload.student_id,
            topic=payload.topic,
            difficulty=difficulty,
            questions=questions_list,
            created_at=now
        )

    @classmethod
    def submit_attempt(cls, payload: QuizAttemptSubmit) -> QuizAttemptResponse:
        attempt_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc)

        # Retrieve quiz record
        quiz = None
        if db.is_live:
            res = db.client.table("quizzes").select("*").eq("id", payload.quiz_id).execute()
            if res.data:
                quiz = res.data[0]
        else:
            quiz = db._mock_lectures.get(payload.quiz_id)

        if not quiz:
            raise ValueError("Quiz record not found")

        questions = [QuizQuestion(**q) for q in quiz["questions_json"]]
        correct_count = 0
        answers_detail = []

        for q in questions:
            user_ans = payload.user_answers.get(q.id, "").strip().lower()
            correct_ans = q.correct_answer.strip().lower()
            is_correct = (user_ans == correct_ans) or (user_ans and user_ans in correct_ans)
            if is_correct:
                correct_count += 1

            answers_detail.append({
                "question_id": q.id,
                "question": q.question,
                "user_answer": payload.user_answers.get(q.id, ""),
                "correct_answer": q.correct_answer,
                "is_correct": is_correct,
                "explanation": q.explanation
            })

        score_pct = (correct_count / len(questions)) * 100.0 if questions else 0.0

        # Save Attempt Record
        attempt_record = {
            "id": attempt_id,
            "quiz_id": payload.quiz_id,
            "student_id": payload.student_id,
            "score": score_pct,
            "answers_json": answers_detail,
            "completed_at": now.isoformat()
        }

        if db.is_live:
            db.client.table("quiz_attempts").insert(attempt_record).execute()
        else:
            db._mock_lectures[attempt_id] = attempt_record

        # Analytics: Weak-Topic Tracker update if score < 60%
        if score_pct < 60.0:
            cls._update_weak_topic(payload.student_id, quiz["topic"])
            # Schedule Spaced Repetition (1, 3, 7 days)
            cls._schedule_spaced_repetition(payload.student_id, quiz["topic"])

        return QuizAttemptResponse(
            id=attempt_id,
            quiz_id=payload.quiz_id,
            student_id=payload.student_id,
            score=score_pct,
            total_questions=len(questions),
            correct_count=correct_count,
            answers_detail=answers_detail,
            completed_at=now
        )

    @classmethod
    def _update_weak_topic(cls, student_id: str, topic: str):
        now = datetime.now(timezone.utc).isoformat()
        if db.is_live:
            # Try finding existing record
            res = db.client.table("weak_topics").select("*").eq("student_id", student_id).eq("topic", topic).execute()
            if res.data:
                existing = res.data[0]
                db.client.table("weak_topics").update({
                    "times_wrong": existing["times_wrong"] + 1,
                    "last_updated": now
                }).eq("id", existing["id"]).execute()
            else:
                db.client.table("weak_topics").insert({
                    "id": str(uuid.uuid4()),
                    "student_id": student_id,
                    "topic": topic,
                    "times_wrong": 1,
                    "last_updated": now
                }).execute()
        else:
            key = f"wt_{student_id}_{topic}"
            existing = db._mock_students.get(key)
            if existing:
                existing["times_wrong"] += 1
                existing["last_updated"] = now
            else:
                db._mock_students[key] = {
                    "id": str(uuid.uuid4()),
                    "student_id": student_id,
                    "topic": topic,
                    "times_wrong": 1,
                    "last_updated": now
                }

    @classmethod
    def _schedule_spaced_repetition(cls, student_id: str, topic: str):
        now = datetime.now(timezone.utc)
        for interval in [1, 3, 7]:
            next_date = now + timedelta(days=interval)
            item = {
                "id": str(uuid.uuid4()),
                "student_id": student_id,
                "topic": topic,
                "interval_days": interval,
                "next_review_date": next_date.isoformat(),
                "completed": False,
                "created_at": now.isoformat()
            }
            if db.is_live:
                db.client.table("revision_schedule").insert(item).execute()
            else:
                db._mock_links.append(item)

    @classmethod
    def get_weak_topics(cls, student_id: str) -> List[WeakTopicResponse]:
        if db.is_live:
            res = db.client.table("weak_topics").select("*").eq("student_id", student_id).order("times_wrong", desc=True).execute()
            return [
                WeakTopicResponse(
                    id=item["id"],
                    student_id=item["student_id"],
                    topic=item["topic"],
                    times_wrong=item["times_wrong"],
                    last_updated=datetime.fromisoformat(item["last_updated"])
                )
                for item in (res.data or [])
            ]
        else:
            items = [
                v for k, v in db._mock_students.items() if k.startswith("wt_") and v["student_id"] == student_id
            ]
            items.sort(key=lambda x: x["times_wrong"], reverse=True)
            return [
                WeakTopicResponse(
                    id=item["id"],
                    student_id=item["student_id"],
                    topic=item["topic"],
                    times_wrong=item["times_wrong"],
                    last_updated=datetime.fromisoformat(item["last_updated"])
                )
                for item in items
            ]

    @classmethod
    def get_revision_schedule(cls, student_id: str) -> List[RevisionScheduleResponse]:
        if db.is_live:
            res = db.client.table("revision_schedule").select("*").eq("student_id", student_id).eq("completed", False).order("next_review_date").execute()
            return [
                RevisionScheduleResponse(
                    id=item["id"],
                    student_id=item["student_id"],
                    topic=item["topic"],
                    interval_days=item["interval_days"],
                    next_review_date=datetime.fromisoformat(item["next_review_date"]),
                    completed=item["completed"]
                )
                for item in (res.data or [])
            ]
        else:
            items = [v for v in db._mock_links if v.get("interval_days") and v.get("student_id") == student_id]
            return [
                RevisionScheduleResponse(
                    id=item["id"],
                    student_id=item["student_id"],
                    topic=item["topic"],
                    interval_days=item["interval_days"],
                    next_review_date=datetime.fromisoformat(item["next_review_date"]),
                    completed=item["completed"]
                )
                for item in items
            ]
