from fastapi import APIRouter, HTTPException, status
from app.schemas.wellbeing import (
    FocusSessionCreate, FocusSessionResponse,
    AwardXPRequest, ProgressResponse, StudyReceiptResponse
)
from app.services.wellbeing_service import WellbeingService

router = APIRouter()

@router.post("/focus-session", response_model=FocusSessionResponse, status_code=status.HTTP_201_CREATED)
def log_focus_session(payload: FocusSessionCreate):
    """
    Logs a completed Pomodoro focus or break session.
    """
    try:
        return WellbeingService.log_focus_session(payload)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/award-xp", response_model=ProgressResponse)
def award_xp(payload: AwardXPRequest):
    """
    Awards XP to a student and evaluates daily streak & badge unlocks.
    """
    try:
        return WellbeingService.award_xp(payload.student_id, payload.activity)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/progress/{student_id}", response_model=ProgressResponse)
def get_student_progress(student_id: str):
    """
    Retrieves student XP, current streak, longest streak, and earned badges.
    """
    try:
        return WellbeingService.get_student_progress(student_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/study-receipt/{student_id}", response_model=StudyReceiptResponse)
def generate_study_receipt(student_id: str):
    """
    Generates end-of-day study summary receipt.
    """
    try:
        return WellbeingService.generate_study_receipt(student_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
