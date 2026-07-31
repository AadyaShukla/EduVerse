from fastapi import APIRouter, HTTPException
from backend.models.schemas import QuizGenerateRequest, QuizGenerateResponse, QuizQuestion, QuizAttemptRequest
import google.generativeai as genai
import os
import uuid
import datetime
import json
import typing

router = APIRouter()

MOCK_DB_QUIZZES = {}
MOCK_DB_QUIZ_ATTEMPTS = {}
MOCK_DB_WEAK_TOPICS = {}
MOCK_DB_REVISION = {}

class QuizQuestionSchema(typing.TypedDict, total=False):
    question: str
    options: list[str]
    correct_answer: str
    explanation: str

class QuizSchema(typing.TypedDict):
    questions: list[QuizQuestionSchema]

@router.post("/generate", response_model=QuizGenerateResponse)
def generate_quiz(request: QuizGenerateRequest):
    api_key = os.getenv("GEMINI_API_KEY")

    # Adaptive difficulty logic based on past score for the SPECIFIC topic
    difficulty = "standard"

    # Handle multiple topics if mock exam (basic comma separation assumption)
    topics = [t.strip() for t in request.topic.split(",")]

    past_attempts = []
    for t in topics:
        past_attempts.extend([a for a in MOCK_DB_QUIZ_ATTEMPTS.values() if a['student_id'] == request.student_id and a['quiz_id'] in [q_id for q_id, q_data in MOCK_DB_QUIZZES.items() if t.lower() in q_data['topic'].lower()]])

    if past_attempts:
        avg_score = sum(a['score'] for a in past_attempts) / len(past_attempts)
        if avg_score > 80:
            difficulty = "hard, advanced"
        elif avg_score < 50:
            difficulty = "easy, foundational"

    if not api_key:
        # Mock response if no key
        quiz_id = uuid.uuid4()
        questions = [
            QuizQuestion(
                question=f"Mock {difficulty} Question for {request.topic}",
                options=["A", "B", "C", "D"],
                correct_answer="A",
                explanation="Because A is mock correct."
            )
        ]
        MOCK_DB_QUIZZES[quiz_id] = {
            "id": quiz_id,
            "student_id": request.student_id,
            "topic": request.topic,
            "questions_json": [q.model_dump() for q in questions],
            "created_at": datetime.datetime.now(datetime.timezone.utc)
        }
        return QuizGenerateResponse(quiz_id=quiz_id, questions=questions)

    genai.configure(api_key=api_key)
    model = genai.GenerativeModel('gemini-1.5-flash')

    prompt = f"Generate 5 quiz questions about '{request.topic}'. The difficulty should be {difficulty}. Include a mix of multiple choice and short answer questions."
    if request.notes_text:
        prompt += f"\nBase the questions on these notes:\n{request.notes_text}"

    try:
        response = model.generate_content(
            prompt,
            generation_config=genai.GenerationConfig(
                response_mime_type="application/json",
                response_schema=QuizSchema,
            ),
        )
        data = json.loads(response.text)

        questions = []
        for q in data.get('questions', []):
            questions.append(QuizQuestion(
                question=q['question'],
                options=q.get('options'),
                correct_answer=q['correct_answer'],
                explanation=q['explanation']
            ))

        quiz_id = uuid.uuid4()
        MOCK_DB_QUIZZES[quiz_id] = {
            "id": quiz_id,
            "student_id": request.student_id,
            "topic": request.topic,
            "questions_json": [q.model_dump() for q in questions],
            "created_at": datetime.datetime.now(datetime.timezone.utc)
        }

        return QuizGenerateResponse(quiz_id=quiz_id, questions=questions)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
