import pytest
from app.services.guardian_service import GuardianService

def test_generate_invite_code_and_dashboard():
    guardian_id = "mock_guardian_123"
    dash = GuardianService.get_guardian_dashboard(guardian_id)
    assert dash.guardian_id == guardian_id
    assert dash.student_name is not None
    assert dash.total_study_minutes >= 0
