from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional, Dict, Any
from datetime import datetime

class QuizQuestion(BaseModel):
    id: str
    type: str = Field(..., description="mcq or short_answer")
    question: str
    options: Optional[List[str]] = None
    correct_answer: str
    explanation: str

class QuizGenerateRequest(BaseModel):
    student_id: str
    topic: str
    notes_text: Optional[str] = None
    num_questions: int = Field(default=5, ge=1, le=20)

class QuizResponse(BaseModel):
    id: str
    student_id: str
    topic: str
    difficulty: str
    questions: List[QuizQuestion]
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class QuizAttemptSubmit(BaseModel):
    quiz_id: str
    student_id: str
    user_answers: Dict[str, str]

class QuizAttemptResponse(BaseModel):
    id: str
    quiz_id: str
    student_id: str
    score: float
    total_questions: int
    correct_count: int
    answers_detail: List[Dict[str, Any]]
    completed_at: datetime

class WeakTopicResponse(BaseModel):
    id: str
    student_id: str
    topic: str
    times_wrong: int
    last_updated: datetime

class RevisionScheduleResponse(BaseModel):
    id: str
    student_id: str
    topic: str
    interval_days: int
    next_review_date: datetime
    completed: bool

class MockExamRequest(BaseModel):
    student_id: str
    topics: List[str]
    duration_minutes: int = Field(default=15, ge=5, le=180)
