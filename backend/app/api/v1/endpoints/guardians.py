from fastapi import APIRouter, HTTPException, status
from app.schemas.guardian import (
    InviteCodeRequest, InviteCodeResponse,
    LinkGuardianRequest, LinkGuardianResponse,
    RevokeLinkRequest, GuardianDashboardResponse, GuardianAIInsightsResponse
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

@router.post("/revoke")
def revoke_guardian_link(payload: RevokeLinkRequest):
    """
    Revokes guardian link for students grade >= 7.
    """
    try:
        return GuardianService.revoke_guardian_link(payload.student_id)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/dashboard/{guardian_id}", response_model=GuardianDashboardResponse)
def get_guardian_dashboard(guardian_id: str):
    """
    Retrieves 1-on-1 student progress metrics for the linked guardian.
    """
    try:
        return GuardianService.get_guardian_dashboard(guardian_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/insights/{guardian_id}", response_model=GuardianAIInsightsResponse)
async def get_guardian_ai_insights(guardian_id: str):
    """
    Generates short plain-language weekly AI summary for guardian via Gemini (daily cached).
    """
    try:
        return await GuardianService.generate_ai_insights(guardian_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
