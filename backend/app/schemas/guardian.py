from pydantic import BaseModel, Field, EmailStr, ConfigDict
from typing import Optional, List, Dict, Any
from datetime import datetime

class GuardianCreateRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    pin: str = Field(..., min_length=4)

class GuardianLoginRequest(BaseModel):
    email: EmailStr
    pin: str

class GuardianResponse(BaseModel):
    id: str
    name: str
    email: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class InviteCodeRequest(BaseModel):
    student_id: str

class InviteCodeResponse(BaseModel):
    student_id: str
    invite_code: str
    expires_at: Optional[str] = None
    message: str

class LinkGuardianRequest(BaseModel):
    invite_code: str
    guardian_name: str
    guardian_email: EmailStr

class LinkGuardianResponse(BaseModel):
    student_id: str
    guardian_id: str
    status: str
    student_activated: bool
    message: str

class RevokeLinkRequest(BaseModel):
    student_id: str

class GuardianAIInsightsResponse(BaseModel):
    student_name: str
    weekly_insight_summary: str
    generated_at: datetime
    is_cached: bool

class GuardianDashboardResponse(BaseModel):
    guardian_id: str
    student_id: str
    student_name: str
    student_grade: int
    is_link_active: bool
    link_status: str
    total_study_minutes: int
    quiz_attempts_count: int
    avg_quiz_score: float
    current_streak: int
    xp: int
    weak_topics: List[Dict[str, Any]]
    recent_doubts: List[Dict[str, Any]]
    inactivity_alert: bool
    inactivity_days: int
