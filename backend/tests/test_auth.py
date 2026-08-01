import pytest
from app.services.auth_service import AuthService
from app.schemas.auth import StudentRegisterRequest

def test_evaluate_age_gate_under_7():
    """
    Test grade < 7 blocks activation and requires parent linking.
    """
    parent_req, is_active = AuthService.evaluate_age_gate(grade=5)
    assert parent_req is True
    assert is_active is False

def test_evaluate_age_gate_7_and_above():
    """
    Test grade >= 7 activates account immediately.
    """
    parent_req, is_active = AuthService.evaluate_age_gate(grade=8)
    assert parent_req is False
    assert is_active is True

def test_student_registration_underage():
    payload = StudentRegisterRequest(name="Alice Primary", grade=4)
    response = AuthService.register_student(payload)
    assert response.student.parent_link_required is True
    assert response.student.is_active is False
    assert response.totp_secret is not None

def test_student_registration_senior():
    payload = StudentRegisterRequest(name="Bob Senior", grade=10)
    response = AuthService.register_student(payload)
    assert response.student.parent_link_required is False
    assert response.student.is_active is True
    assert response.totp_secret is not None
