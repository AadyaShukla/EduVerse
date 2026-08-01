from fastapi import APIRouter, HTTPException, status
from app.schemas.guardian import (
    InviteCodeRequest, InviteCodeResponse,
    LinkGuardianRequest, LinkGuardianResponse
)
from app.services.guardian_service import GuardianService

router = APIRouter()

@router.post("/invite-code", response_model=InviteCodeResponse)
def generate_invite_code(payload: InviteCodeRequest):
    """
    Generate a 6-character invite code for linking a guardian.
    """
    try:
        return GuardianService.generate_invite_code(payload.student_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/link", response_model=LinkGuardianResponse)
def link_guardian(payload: LinkGuardianRequest):
    """
    Links a guardian to a student using their invite code.
    Activates student account if blocked by age-gate rule (grade < 7).
    """
    try:
        return GuardianService.link_guardian(payload)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
