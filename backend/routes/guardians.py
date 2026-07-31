from fastapi import APIRouter, HTTPException
from backend.models.schemas import GuardianInviteRequest
from backend.routes.auth import MOCK_DB_STUDENTS
import uuid

router = APIRouter()

MOCK_DB_GUARDIANS = {}
MOCK_DB_LINKS = {}

@router.post("/invite")
def invite_guardian(request: GuardianInviteRequest):
    if request.student_id not in MOCK_DB_STUDENTS:
        raise HTTPException(status_code=404, detail="Student not found")

    # In a real app, send an email/notification here.
    # For now, just generate a pending link record
    guardian_id = uuid.uuid4()
    MOCK_DB_GUARDIANS[guardian_id] = {
        "id": guardian_id,
        "name": request.guardian_name,
        "email": request.guardian_email
    }

    MOCK_DB_LINKS[(request.student_id, guardian_id)] = "pending"

    return {"message": "Invite sent successfully", "guardian_id": guardian_id}
