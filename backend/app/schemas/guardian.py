from pydantic import BaseModel, Field, EmailStr
from typing import Optional
from datetime import datetime

class GuardianCreateRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr

class GuardianResponse(BaseModel):
    id: str
    name: str
    email: str
    created_at: datetime

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
