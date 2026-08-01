from fastapi import APIRouter, HTTPException, status
from typing import List
from app.schemas.doubt import DoubtSolveRequest, DoubtSolveResponse, DoubtHistoryItem
from app.services.doubt_service import DoubtService

router = APIRouter()

@router.post("/explain", response_model=DoubtSolveResponse, status_code=status.HTTP_200_OK)
async def solve_doubt(payload: DoubtSolveRequest):
    """
    Solves a student's doubt using backend-only Gemini LLM integration.
    Returns structured step-by-step explanations in the target language.
    Logs the question & summary in Supabase doubts table.
    """
    try:
        return await DoubtService.solve_doubt(payload)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/history/{student_id}", response_model=List[DoubtHistoryItem])
def get_doubt_history(student_id: str):
    """
    Retrieves a student's past solved doubts.
    """
    try:
        return DoubtService.get_doubt_history(student_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
