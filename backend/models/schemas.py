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

class QuizGenerateRequest(BaseModel):
    student_id: UUID
    topic: str
    notes_text: Optional[str] = None
    is_mock_exam: bool = False

class QuizQuestion(BaseModel):
    question: str
    options: Optional[list[str]] = None
    correct_answer: str
    explanation: str

class QuizGenerateResponse(BaseModel):
    quiz_id: UUID
    questions: list[QuizQuestion]

class QuizAttemptRequest(BaseModel):
    student_id: UUID
    quiz_id: UUID
    score: int
    answers: dict[str, str] # question -> given answer
    weak_topics: list[str] # Topics the user failed on (simple extraction from frontend for this mock)

class WeakTopic(BaseModel):
    topic: str
    times_wrong: int
