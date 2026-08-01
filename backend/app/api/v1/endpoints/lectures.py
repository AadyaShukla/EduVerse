import uuid
from datetime import datetime
from fastapi import APIRouter, HTTPException
from typing import List
from app.schemas.lecture import LectureSessionCreate, LectureSessionResponse
from app.db.supabase_client import db

router = APIRouter()

@router.get("/sessions", response_model=List[LectureSessionResponse])
def get_lecture_sessions(student_id: str):
    """
    Retrieve lecture sessions for a student.
    """
    if db.is_live:
        res = db.client.table("lecture_sessions").select("*").eq("student_id", student_id).execute()
        return res.data or []
    else:
        return [
            v for v in db._mock_lectures.values() if v.get("student_id") == student_id
        ]

@router.post("/sessions", response_model=LectureSessionResponse)
def create_lecture_session(payload: LectureSessionCreate):
    """
    Create a new lecture session stub for student learning.
    """
    session_id = str(uuid.uuid4())
    now = datetime.utcnow()
    record = {
        "id": session_id,
        "student_id": payload.student_id,
        "topic": payload.topic,
        "current_segment": payload.current_segment,
        "paused_at": None,
        "completed": False,
        "created_at": now.isoformat()
    }

    if db.is_live:
        db.client.table("lecture_sessions").insert(record).execute()
    else:
        db._mock_lectures[session_id] = record

    return LectureSessionResponse(
        id=session_id,
        student_id=payload.student_id,
        topic=payload.topic,
        current_segment=payload.current_segment,
        paused_at=None,
        completed=False,
        created_at=now
    )
