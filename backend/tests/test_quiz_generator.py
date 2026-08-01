import pytest
from app.services.quiz_service import QuizService

def test_evaluate_adaptive_difficulty_default():
    """
    Test default adaptive difficulty returns 'medium' when no past attempts exist.
    """
    diff = QuizService.evaluate_adaptive_difficulty("mock_student_1", "Algebra")
    assert diff == "medium"
