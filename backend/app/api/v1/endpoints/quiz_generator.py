from fastapi import APIRouter, HTTPException, status
from typing import List
from app.schemas.quiz import (
    QuizGenerateRequest, QuizResponse, QuizAttemptSubmit,
    QuizAttemptResponse, WeakTopicResponse, RevisionScheduleResponse,
    MockExamRequest
)
from app.services.quiz_service import QuizService

router = APIRouter()

@router.post("/generate", response_model=QuizResponse, status_code=status.HTTP_200_OK)
async def generate_quiz(payload: QuizGenerateRequest):
    """
    Generates an adaptive AI quiz using Gemini based on topic/notes and past student performance.
    """
    try:
        return await QuizService.generate_quiz(payload)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/submit-attempt", response_model=QuizAttemptResponse)
def submit_quiz_attempt(payload: QuizAttemptSubmit):
    """
    Submits a student's quiz answers, calculates score %,
    updates weak topics table if score < 60%, and schedules spaced repetition.
    """
    try:
        return QuizService.submit_attempt(payload)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/weak-topics/{student_id}", response_model=List[WeakTopicResponse])
def get_weak_topics(student_id: str):
    """
    Retrieves student weak topics sorted by times_wrong descending.
    """
    try:
        return QuizService.get_weak_topics(student_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/revision-schedule/{student_id}", response_model=List[RevisionScheduleResponse])
def get_revision_schedule(student_id: str):
    """
    Retrieves upcoming spaced repetition reviews for the student.
    """
    try:
        return QuizService.get_revision_schedule(student_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/mock-exam", response_model=QuizResponse)
async def generate_mock_exam(payload: MockExamRequest):
    """
    Generates a multi-topic mock exam session.
    """
    combined_topic = " & ".join(payload.topics)
    req = QuizGenerateRequest(
        student_id=payload.student_id,
        topic=combined_topic,
        num_questions=len(payload.topics) * 3
    )
    return await QuizService.generate_quiz(req)
