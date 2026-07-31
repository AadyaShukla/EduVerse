from pydantic import BaseModel, EmailStr
from typing import Optional
from uuid import UUID

class StudentSignupRequest(BaseModel):
    name: str
    grade: int
    pin: str # Stored locally on frontend mostly, but could be sent if needed. In this scaffold we don't store it on backend, we rely on local_auth and just verify if they signed up. Let's assume frontend just registers them.

class StudentResponse(BaseModel):
    id: UUID
    name: str
    grade: int
    parent_link_required: bool
    parent_id: Optional[UUID]

class GuardianInviteRequest(BaseModel):
    student_id: UUID
    guardian_email: EmailStr
    guardian_name: str

class TOTPRecoveryRequest(BaseModel):
    student_id: UUID

class TOTPVerifyRequest(BaseModel):
    student_id: UUID
    code: str

class DoubtRequest(BaseModel):
    student_id: UUID
    question: str
    language: str

class DoubtResponse(BaseModel):
    steps: list[str]
