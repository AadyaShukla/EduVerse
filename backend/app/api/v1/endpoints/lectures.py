from fastapi import APIRouter, HTTPException, Query
from app.schemas.lecture import (
    LectureCreateRequest, LectureResponse, LectureSessionUpdate, LectureRecapResponse
)
from app.services.lecture_service import LectureService

router = APIRouter()

@router.post("/generate", response_model=LectureResponse)
async def generate_lecture(payload: LectureCreateRequest):
    """
    Generate or fetch a cached multi-segment AI lecture for a given topic & grade.
    """
    try:
        return await LectureService.get_or_create_lecture(payload)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/session/update")
def update_lecture_session(payload: LectureSessionUpdate):
    """
    Update student lecture progress (current segment, paused position, completion).
    """
    try:
        return LectureService.update_session(payload)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/recap/{lecture_id}", response_model=LectureRecapResponse)
async def get_lecture_recap(lecture_id: str, topic: str = Query(..., min_length=2)):
    """
    Generates an end-of-lecture recap summary.
    """
    try:
        return await LectureService.get_recap(lecture_id, topic)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
