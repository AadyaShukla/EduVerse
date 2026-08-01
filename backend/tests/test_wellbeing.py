import pytest
from app.services.wellbeing_service import WellbeingService

def test_award_xp_and_streak():
    student_id = "test_wellbeing_student_1"
    res = WellbeingService.award_xp(student_id, "doubt_solve")
    assert res.xp >= 50
    assert res.current_streak >= 1

def test_generate_study_receipt():
    student_id = "test_wellbeing_student_1"
    receipt = WellbeingService.generate_study_receipt(student_id)
    assert receipt.student_id == student_id
    assert receipt.total_study_minutes >= 0
