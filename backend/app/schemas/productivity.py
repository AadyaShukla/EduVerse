from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional, Dict, Any
from datetime import datetime

class NoteCreate(BaseModel):
    student_id: str
    subject: Optional[str] = "General"
    title: str
    content: str
    tags: Optional[List[str]] = []

class NoteResponse(BaseModel):
    id: str
    student_id: str
    subject: str
    title: str
    content: str
    tags: List[str]
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

class NoteTagRequest(BaseModel):
    content: str

class NoteTagResponse(BaseModel):
    suggested_subject: str
    suggested_tags: List[str]

class ScheduleItemCreate(BaseModel):
    student_id: str
    type: str = Field(..., description="class or assignment")
    title: str
    subject: str
    item_datetime: datetime
    reminder_set: bool = False

class ScheduleItemResponse(BaseModel):
    id: str
    student_id: str
    type: str
    title: str
    subject: str
    item_datetime: datetime
    reminder_set: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class HomeworkParseRequest(BaseModel):
    student_id: str
    raw_ocr_text: str

class HomeworkItem(BaseModel):
    title: str
    subject: str
    suggested_deadline: Optional[str] = None

class HomeworkParseResponse(BaseModel):
    extracted_items: List[HomeworkItem]

class EssayGradeRequest(BaseModel):
    student_id: str
    subject: str
    essay_text: str

class FeedbackCategory(BaseModel):
    category: str
    score_out_of_10: int
    suggestions: List[str]

class EssayGradeResponse(BaseModel):
    id: str
    student_id: str
    subject: str
    overall_feedback: str
    grammar_score: int
    structure_score: int
    clarity_score: int
    categories: List[FeedbackCategory]
    created_at: datetime
