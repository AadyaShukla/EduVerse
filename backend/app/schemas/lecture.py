from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List
from datetime import datetime

class LectureSessionBase(BaseModel):
    student_id: str
    topic: str
    current_segment: int = 0

class LectureSessionCreate(LectureSessionBase):
    pass

class LectureSessionResponse(LectureSessionBase):
    id: str
    paused_at: Optional[datetime] = None
    completed: bool = False
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

