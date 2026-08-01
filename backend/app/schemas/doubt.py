from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

class DoubtSolveRequest(BaseModel):
    student_id: str
    question_text: str = Field(..., min_length=2)
    target_language: Optional[str] = "English"

class DoubtStep(BaseModel):
    step_number: int
    title: str
    explanation: str

class DoubtSolveResponse(BaseModel):
    id: str
    student_id: str
    question_text: str
    detected_language: str
    explanation_language: str
    topic: str
    summary: str
    steps: List[DoubtStep]
    created_at: datetime

class DoubtHistoryItem(BaseModel):
    id: str
    student_id: str
    question_text: str
    language: str
    answer_summary: str
    created_at: datetime
