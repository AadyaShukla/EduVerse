from fastapi import APIRouter, HTTPException, status
from typing import List
from app.schemas.productivity import (
    NoteCreate, NoteResponse, NoteTagRequest, NoteTagResponse,
    ScheduleItemCreate, ScheduleItemResponse, HomeworkParseRequest, HomeworkParseResponse,
    EssayGradeRequest, EssayGradeResponse
)
from app.services.productivity_service import ProductivityService

router = APIRouter()

@router.post("/notes/tag", response_model=NoteTagResponse)
async def tag_note_content(payload: NoteTagRequest):
    """
    AI subject auto-tagger for student notes.
    """
    try:
        return await ProductivityService.auto_tag_note(payload)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/notes", response_model=NoteResponse, status_code=status.HTTP_201_CREATED)
def create_note(payload: NoteCreate):
    """
    Creates and stores a student note in Supabase notes table.
    """
    try:
        return ProductivityService.create_note(payload)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/notes/{student_id}", response_model=List[NoteResponse])
def get_student_notes(student_id: str):
    """
    Retrieves all notes for a student.
    """
    try:
        return ProductivityService.get_notes(student_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/schedule", response_model=ScheduleItemResponse, status_code=status.HTTP_201_CREATED)
def create_schedule_item(payload: ScheduleItemCreate):
    """
    Adds a class or assignment deadline item to the timetable.
    """
    try:
        return ProductivityService.create_schedule_item(payload)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/schedule/{student_id}", response_model=List[ScheduleItemResponse])
def get_student_schedule(student_id: str):
    """
    Retrieves student timetable schedule & deadline items.
    """
    try:
        return ProductivityService.get_schedule(student_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/homework/parse", response_model=HomeworkParseResponse)
async def parse_homework_ocr(payload: HomeworkParseRequest):
    """
    Parses raw OCR text from homework diary pages into structured tasks and deadlines.
    """
    try:
        return await ProductivityService.parse_homework(payload)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/essay/grade", response_model=EssayGradeResponse)
async def grade_essay_assignment(payload: EssayGradeRequest):
    """
    Grades student essays/assignments and provides inline suggestions for Grammar, Structure, and Clarity.
    """
    try:
        return await ProductivityService.grade_essay(payload)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
