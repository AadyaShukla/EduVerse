import pytest
from app.schemas.lecture import LectureCreateRequest
from app.services.lecture_service import LectureService

@pytest.mark.asyncio
async def test_generate_and_cache_lecture():
    req = LectureCreateRequest(student_id="student_123", topic="Photosynthesis", grade=7)
    res = await LectureService.get_or_create_lecture(req)

    assert res.topic == "Photosynthesis"
    assert res.total_segments >= 2
    assert len(res.segments) > 0
    assert res.segments[0].checkpoint.correct_answer is not None

    # Test cache retrieval
    res_cached = await LectureService.get_or_create_lecture(req)
    assert res_cached.is_cached == True
