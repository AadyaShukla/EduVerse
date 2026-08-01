import secrets
import string
import uuid
from datetime import datetime, timezone
from typing import Dict, Any, Optional
from app.db.supabase_client import db
from app.services.auth_service import AuthService
from app.schemas.guardian import (
    InviteCodeResponse, LinkGuardianRequest, LinkGuardianResponse
)

class GuardianService:
    """
    Handles guardian invite code generation and linking to student accounts.
    """

    @classmethod
    def generate_invite_code(cls, student_id: str) -> InviteCodeResponse:
        student = AuthService.get_student(student_id)
        if not student:
            raise ValueError("Student not found")

        # Generate 6-character alphanumeric code
        chars = string.ascii_uppercase + string.digits
        invite_code = ''.join(secrets.choice(chars) for _ in range(6))

        link_record = {
            "student_id": student_id,
            "guardian_id": None,
            "invite_code": invite_code,
            "status": "pending",
            "linked_at": datetime.now(timezone.utc).isoformat()
        }


        if db.is_live:
            db.client.table("student_guardian_links").upsert(link_record).execute()
        else:
            db._mock_links.append(link_record)

        return InviteCodeResponse(
            student_id=student_id,
            invite_code=invite_code,
            message="Invite code generated successfully. Share with your parent/guardian."
        )

    @classmethod
    def link_guardian(cls, payload: LinkGuardianRequest) -> LinkGuardianResponse:
        # Find link record by invite code
        matching_link = None
        if db.is_live:
            res = db.client.table("student_guardian_links").select("*").eq("invite_code", payload.invite_code).execute()
            if res.data:
                matching_link = res.data[0]
        else:
            for l in db._mock_links:
                if l.get("invite_code") == payload.invite_code:
                    matching_link = l
                    break

        if not matching_link:
            raise ValueError("Invalid or expired invite code")

        student_id = matching_link["student_id"]
        student = AuthService.get_student(student_id)
        if not student:
            raise ValueError("Associated student record not found")

        # Create or find Guardian
        guardian_id = str(uuid.uuid4())
        guardian_record = {
            "id": guardian_id,
            "name": payload.guardian_name,
            "email": payload.guardian_email,
            "created_at": datetime.utcnow().isoformat()
        }

        if db.is_live:
            db.client.table("guardians").insert(guardian_record).execute()
            # Update link
            db.client.table("student_guardian_links").update({
                "guardian_id": guardian_id,
                "status": "approved"
            }).eq("invite_code", payload.invite_code).execute()
            # Activate student account & link parent_id
            db.client.table("students").update({
                "parent_id": guardian_id,
                "is_active": True,
                "parent_link_required": False
            }).eq("id", student_id).execute()
        else:
            db._mock_guardians[guardian_id] = guardian_record
            matching_link["guardian_id"] = guardian_id
            matching_link["status"] = "approved"
            student["parent_id"] = guardian_id
            student["is_active"] = True
            student["parent_link_required"] = False

        return LinkGuardianResponse(
            student_id=student_id,
            guardian_id=guardian_id,
            status="approved",
            student_activated=True,
            message="Guardian successfully linked. Student account activated!"
        )
