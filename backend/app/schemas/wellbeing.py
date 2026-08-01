from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional
from datetime import datetime, date

class FocusSessionCreate(BaseModel):
    student_id: str
    duration_minutes: int = Field(..., ge=1, le=180)
    type: str = Field(..., description="focus or break")

class FocusSessionResponse(BaseModel):
    id: str
    student_id: str
    duration_minutes: int
    type: str
    completed_at: datetime

    model_config = ConfigDict(from_attributes=True)

class AwardXPRequest(BaseModel):
    student_id: str
    activity: str = Field(..., description="doubt_solve, quiz_complete, focus_session, note_created")

class BadgeResponse(BaseModel):
    id: str
    student_id: str
    badge_name: str
    earned_at: datetime

class ProgressResponse(BaseModel):
    id: str
    student_id: str
    xp: int
    current_streak: int
    longest_streak: int
    last_active_date: date
    badges: List[BadgeResponse]

    model_config = ConfigDict(from_attributes=True)

class StudyReceiptResponse(BaseModel):
    student_id: str
    date: str
    total_study_minutes: int
    doubts_solved_count: int
    quizzes_completed_count: int
    mastered_topics: List[str] = []

