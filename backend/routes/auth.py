from fastapi import APIRouter, HTTPException
from backend.models.schemas import StudentSignupRequest, StudentResponse, TOTPRecoveryRequest, TOTPVerifyRequest
from backend.services.auth import AuthService
import uuid

router = APIRouter()

# In-memory mock DB for this scaffold since we aren't connecting to real Supabase
MOCK_DB_STUDENTS = {}
MOCK_DB_TOTP_SECRETS = {}

@router.post("/signup", response_model=StudentResponse)
def signup(request: StudentSignupRequest):
    student_id = uuid.uuid4()

    # Age-gate logic
    parent_link_required = True if request.grade < 7 else False

    student_data = {
        "id": student_id,
        "name": request.name,
        "grade": request.grade,
        "parent_link_required": parent_link_required,
        "parent_id": None
    }

    MOCK_DB_STUDENTS[student_id] = student_data

    # Generate TOTP secret for account recovery
    secret = AuthService.generate_totp_secret()
    MOCK_DB_TOTP_SECRETS[student_id] = secret

    return student_data

@router.post("/recovery/generate")
def generate_recovery(request: TOTPRecoveryRequest):
    if request.student_id not in MOCK_DB_STUDENTS:
        raise HTTPException(status_code=404, detail="Student not found")

    secret = MOCK_DB_TOTP_SECRETS.get(request.student_id)
    if not secret:
        secret = AuthService.generate_totp_secret()
        MOCK_DB_TOTP_SECRETS[request.student_id] = secret

    uri = AuthService.get_totp_uri(secret, MOCK_DB_STUDENTS[request.student_id]['name'])
    return {"secret": secret, "uri": uri}

@router.post("/recovery/verify")
def verify_recovery(request: TOTPVerifyRequest):
    if request.student_id not in MOCK_DB_STUDENTS:
        raise HTTPException(status_code=404, detail="Student not found")

    secret = MOCK_DB_TOTP_SECRETS.get(request.student_id)
    if not secret:
        raise HTTPException(status_code=400, detail="TOTP not set up")

    is_valid = AuthService.verify_totp(secret, request.code)
    if is_valid:
        return {"status": "success", "message": "Recovery successful"}
    else:
        raise HTTPException(status_code=401, detail="Invalid code")
