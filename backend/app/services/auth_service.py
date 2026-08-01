import uuid
import pyotp
from datetime import datetime, timezone
from typing import Dict, Any, Tuple
from app.db.supabase_client import db
from app.schemas.auth import StudentRegisterRequest, StudentResponse, StudentRegisterResponse

class AuthService:
    """
    Auth service handling student registration, age-gating rules,
    and TOTP-based recovery.
    """

    @staticmethod
    def evaluate_age_gate(grade: int) -> Tuple[bool, bool]:
        """
        Evaluates age-gate rules based on student grade.
        Returns (parent_link_required, is_active).
        - grade < 7  => parent_link_required=True, is_active=False
        - grade >= 7 => parent_link_required=False, is_active=True
        """
        if grade < 7:
            return True, False
        return False, True

    @classmethod
    def register_student(cls, payload: StudentRegisterRequest) -> StudentRegisterResponse:
        student_id = str(uuid.uuid4())
        created_at = datetime.now(timezone.utc)

        parent_link_req, is_active = cls.evaluate_age_gate(payload.grade)
        
        # Generate TOTP Secret
        totp_secret = pyotp.random_base32()
        totp_uri = pyotp.totp.TOTP(totp_secret).provisioning_uri(
            name=f"{payload.name} (Grade {payload.grade})",
            issuer_name="EduVerse"
        )

        student_dict = {
            "id": student_id,
            "name": payload.name,
            "grade": payload.grade,
            "parent_link_required": parent_link_req,
            "parent_id": None,
            "is_active": is_active,
            "totp_secret": totp_secret,
            "created_at": created_at.isoformat()
        }

        # Store in Supabase if live, or in-memory mock db
        if db.is_live:
            db.client.table("students").insert(student_dict).execute()
        else:
            db._mock_students[student_id] = student_dict

        student_res = StudentResponse(
            id=student_id,
            name=payload.name,
            grade=payload.grade,
            parent_link_required=parent_link_req,
            parent_id=None,
            is_active=is_active,
            created_at=created_at
        )

        message = (
            "Account created! Account activation pending guardian approval." 
            if parent_link_req else 
            "Account created and activated successfully."
        )

        return StudentRegisterResponse(
            student=student_res,
            totp_secret=totp_secret,
            totp_qr_uri=totp_uri,
            message=message
        )

    @classmethod
    def get_student(cls, student_id: str) -> Dict[str, Any]:
        if db.is_live:
            res = db.client.table("students").select("*").eq("id", student_id).execute()
            if res.data:
                return res.data[0]
            return None
        return db._mock_students.get(student_id)

    @classmethod
    def verify_totp(cls, student_id: str, token: str) -> bool:
        student = cls.get_student(student_id)
        if not student or not student.get("totp_secret"):
            return False
        totp = pyotp.TOTP(student["totp_secret"])
        return totp.verify(token)

    @classmethod
    def delete_student_data(cls, student_id: str) -> Dict[str, Any]:
        """
        Right to be Forgotten: Permanently deletes all student doubts, notes,
        quiz attempts, schedule items, and profile metrics from database.
        """
        if db.is_live:
            db.client.table("doubts").delete().eq("student_id", student_id).execute()
            db.client.table("notes").delete().eq("student_id", student_id).execute()
            db.client.table("quiz_attempts").delete().eq("student_id", student_id).execute()
            db.client.table("schedule_items").delete().eq("student_id", student_id).execute()
            db.client.table("focus_sessions").delete().eq("student_id", student_id).execute()
            db.client.table("student_progress").delete().eq("student_id", student_id).execute()
            db.client.table("students").delete().eq("id", student_id).execute()
        else:
            db._mock_students.pop(student_id, None)

        return {
            "success": True,
            "message": "All student account records and learning history permanently deleted under privacy regulations."
        }

