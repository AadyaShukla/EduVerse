from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional, Dict, Any
from datetime import datetime

class CheckpointQuestion(BaseModel):
    question: str
    options: List[str]
    correct_answer: str
    explanation: str
    recap_text: str

class LectureSegment(BaseModel):
    segment_index: int
    segment_title: str
    narration_text: str
    slide_bullets: List[str]
    diagram_description: Optional[str] = None
    checkpoint: CheckpointQuestion

class LectureCreateRequest(BaseModel):
    student_id: str
    topic: str = Field(..., min_length=2, max_length=150)
    grade: int = Field(..., ge=1, le=12)

class LectureResponse(BaseModel):
    lecture_id: str
    topic: str
    grade: int
    total_segments: int
    segments: List[LectureSegment]
    created_at: datetime
    is_cached: bool

class LectureSessionUpdate(BaseModel):
    student_id: str
    lecture_id: str
    current_segment: int
    completed: bool = False

class LectureRecapResponse(BaseModel):
    lecture_id: str
    topic: str
    recap_summary: str
    suggested_quiz_topic: str
