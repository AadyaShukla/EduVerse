from fastapi import APIRouter, HTTPException, status
from app.schemas.auth import (
    StudentRegisterRequest, StudentRegisterResponse,
    LocalLoginRequest, TOTPVerifyRequest, TOTPVerifyResponse
)
from app.services.auth_service import AuthService

router = APIRouter()

@router.post("/register", response_model=StudentRegisterResponse, status_code=status.HTTP_201_CREATED)
def register_student(payload: StudentRegisterRequest):
    """
    Register a new student and evaluate age-gating rules based on grade.
    - Grade < 7: parent_link_required = True, is_active = False (blocked until guardian link)
    - Grade >= 7: parent_link_required = False, is_active = True
    Generates TOTP secret for account recovery.
    """
    try:
        return AuthService.register_student(payload)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/login-local")
def login_local(payload: LocalLoginRequest):
    """
    Endpoint validating student account status for local PIN/Biometric auth login.
    """
    student = AuthService.get_student(payload.student_id)
    if not student:
        raise HTTPException(status_code=404, detail="Student account not found")

    if not student.get("is_active"):
        raise HTTPException(
            status_code=403,
            detail="Account is inactive or pending guardian approval (age < grade 7 rule)."
        )

    return {
        "status": "success",
        "student": student,
        "message": "Local login authenticated successfully."
    }

@router.post("/totp/verify", response_model=TOTPVerifyResponse)
def verify_totp(payload: TOTPVerifyRequest):
    """
    Verifies a 6-digit TOTP token for account recovery or lost PIN reset.
    """
    is_valid = AuthService.verify_totp(payload.student_id, payload.totp_token)
    if not is_valid:
        raise HTTPException(status_code=400, detail="Invalid or expired TOTP recovery code")

    return TOTPVerifyResponse(
        success=True,
        student_id=payload.student_id,
        message="TOTP verified successfully. You can now reset local PIN credentials."
    )

@router.delete("/delete-data/{student_id}")
def delete_student_data(student_id: str):
    """
    Right to be Forgotten endpoint permanently deleting student records under GDPR / COPPA.
    """
    try:
        return AuthService.delete_student_data(student_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

