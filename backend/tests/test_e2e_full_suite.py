import pytest
import asyncio
from datetime import datetime, timezone
from app.services.auth_service import AuthService
from app.services.doubt_service import DoubtService
from app.services.quiz_service import QuizService
from app.services.productivity_service import ProductivityService
from app.services.wellbeing_service import WellbeingService
from app.services.guardian_service import GuardianService
from app.services.lecture_service import LectureService
from app.schemas.auth import StudentRegisterRequest
from app.schemas.doubt import DoubtSolveRequest
from app.schemas.quiz import QuizGenerateRequest, QuizAttemptSubmit
from app.schemas.productivity import NoteCreate, ScheduleItemCreate
from app.schemas.wellbeing import FocusSessionCreate
from app.schemas.guardian import LinkGuardianRequest
from app.schemas.lecture import LectureCreateRequest, LectureSessionUpdate

@pytest.mark.asyncio
async def test_e2e_flow_1_auth_age_gating():
    # Grade 5: require guardian link before activation
    g5_req = StudentRegisterRequest(name="Aarav Grade5", grade=5, pin="1234")
    g5_res = AuthService.register_student(g5_req)
    assert g5_res.student.parent_link_required == True
    assert g5_res.student.is_active == False

    # Grade 9: immediate activation
    g9_req = StudentRegisterRequest(name="Priya Grade9", grade=9, pin="5678")
    g9_res = AuthService.register_student(g9_req)
    assert g9_res.student.parent_link_required == False
    assert g9_res.student.is_active == True

@pytest.mark.asyncio
async def test_e2e_flow_2_doubt_solver_multilingual():
    req_en = DoubtSolveRequest(student_id="st_123", question_text="What is Photosynthesis?", target_language="English")
    res_en = await DoubtService.solve_doubt(req_en)
    assert res_en.question_text == "What is Photosynthesis?"
    assert len(res_en.steps) > 0

    req_hi = DoubtSolveRequest(student_id="st_123", question_text="प्रकाश संश्लेषण क्या है?", target_language="Hindi")
    res_hi = await DoubtService.solve_doubt(req_hi)
    assert res_hi.explanation_language == "Hindi"
    assert len(res_hi.steps) > 0

@pytest.mark.asyncio
async def test_e2e_flow_3_adaptive_quiz_difficulty():
    gen_req = QuizGenerateRequest(student_id="st_123", topic="Algebra")
    quiz = await QuizService.generate_quiz(gen_req)
    assert quiz.difficulty == "medium"

    # Submit high score (>80%) -> Hard difficulty
    high_score_req = QuizAttemptSubmit(
        student_id="st_123",
        quiz_id=quiz.id,
        user_answers={q.id: q.correct_answer for q in quiz.questions}
    )
    res_high = QuizService.submit_attempt(high_score_req)
    assert res_high.score == 100.0

    # Submit low score -> Quiz attempt evaluation
    low_score_req = QuizAttemptSubmit(
        student_id="st_123",
        quiz_id=quiz.id,
        user_answers={q.id: "wrong_answer" for q in quiz.questions}
    )
    res_low = QuizService.submit_attempt(low_score_req)
    assert res_low.score == 0.0

@pytest.mark.asyncio
async def test_e2e_flow_4_productivity_notes_and_schedule():
    note_req = NoteCreate(student_id="st_123", title="Physics Laws", content="Newton third law every action equal opposite reaction", tags=["Physics", "Laws"])
    note_res = ProductivityService.create_note(note_req)
    assert note_res.subject is not None
    assert len(note_res.tags) > 0

    sched_req = ScheduleItemCreate(student_id="st_123", type="assignment", title="Math Exam", subject="Mathematics", item_datetime=datetime.now(timezone.utc))
    sched_res = ProductivityService.create_schedule_item(sched_req)
    assert sched_res.title == "Math Exam"

@pytest.mark.asyncio
async def test_e2e_flow_5_wellbeing_pomodoro_and_receipt():
    focus_req = FocusSessionCreate(student_id="st_123", duration_minutes=25, type="focus")
    focus_res = WellbeingService.log_focus_session(focus_req)
    assert focus_res.duration_minutes == 25

    receipt = WellbeingService.generate_study_receipt("st_123")
    assert receipt.total_study_minutes >= 25
    assert receipt.student_id == "st_123"

@pytest.mark.asyncio
async def test_e2e_flow_6_guardian_insights_caching():
    guardian_id = "g_test_99"
    dash = GuardianService.get_guardian_dashboard(guardian_id)
    assert dash.guardian_id == guardian_id

    insights_1 = await GuardianService.generate_ai_insights(guardian_id)
    assert insights_1.is_cached == False

    insights_2 = await GuardianService.generate_ai_insights(guardian_id)
    assert insights_2.is_cached == True

@pytest.mark.asyncio
async def test_e2e_flow_7_interactive_lecture_and_resume():
    lec_req = LectureCreateRequest(student_id="st_123", topic="Gravity", grade=8)
    lecture = await LectureService.get_or_create_lecture(lec_req)
    assert len(lecture.segments) >= 2

    # Pause at segment 1
    update_res = LectureService.update_session(LectureSessionUpdate(
        student_id="st_123",
        lecture_id=lecture.lecture_id,
        current_segment=1,
        completed=False
    ))
    assert update_res["session"]["current_segment"] == 1

    recap = await LectureService.get_recap(lecture.lecture_id, "Gravity")
    assert recap.topic == "Gravity"
