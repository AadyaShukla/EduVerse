from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field, EmailStr, ConfigDict

class StudentBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    grade: int = Field(..., ge=1, le=12, description="School grade 1 to 12")

class StudentRegisterRequest(StudentBase):
    pass

class StudentResponse(StudentBase):
    id: str
    parent_link_required: bool
    parent_id: Optional[str] = None
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class StudentRegisterResponse(BaseModel):
    student: StudentResponse
    totp_secret: str
    totp_qr_uri: str
    message: str

class LocalLoginRequest(BaseModel):
    student_id: str
    pin_hash: str

class TOTPVerifyRequest(BaseModel):
    student_id: str
    totp_token: str = Field(..., min_length=6, max_length=6)

class TOTPVerifyResponse(BaseModel):
    success: bool
    student_id: str
    message: str
