import uuid
import json
from datetime import datetime, timezone
from typing import Dict, Any, Optional, List
from app.db.supabase_client import db
from app.services.gemini_service import gemini_service
from app.schemas.lecture import (
    LectureCreateRequest, LectureResponse, LectureSegment, CheckpointQuestion,
    LectureSessionUpdate, LectureRecapResponse
)

# Local memory cache for mock mode
_mock_lectures: Dict[str, Dict[str, Any]] = {}
_mock_sessions: Dict[str, Dict[str, Any]] = {}

class LectureService:
    """
    Service for multi-segment AI Interactive Lectures,
    lecture caching, session tracking, and recap generation.
    """

    @classmethod
    async def get_or_create_lecture(cls, payload: LectureCreateRequest) -> LectureResponse:
        topic_clean = payload.topic.strip().lower()

        # 1. Check Cache
        cached_lecture = None
        if db.is_live:
            res = db.client.table("lectures").select("*").eq("topic", payload.topic).eq("grade", payload.grade).execute()
            if res.data:
                cached_lecture = res.data[0]
        else:
            for l in _mock_lectures.values():
                if l["topic"].lower() == topic_clean and l["grade"] == payload.grade:
                    cached_lecture = l
                    break

        if cached_lecture:
            segments_data = cached_lecture.get("segments_json")
            if isinstance(segments_data, str):
                segments_data = json.loads(segments_data)

            segments = [
                LectureSegment(
                    segment_index=s["segment_index"],
                    segment_title=s["segment_title"],
                    narration_text=s["narration_text"],
                    slide_bullets=s["slide_bullets"],
                    diagram_description=s.get("diagram_description"),
                    checkpoint=CheckpointQuestion(**s["checkpoint"])
                ) for s in segments_data
            ]

            return LectureResponse(
                lecture_id=cached_lecture["id"],
                topic=cached_lecture["topic"],
                grade=cached_lecture["grade"],
                total_segments=len(segments),
                segments=segments,
                created_at=datetime.fromisoformat(cached_lecture["created_at"]) if isinstance(cached_lecture["created_at"], str) else cached_lecture["created_at"],
                is_cached=True
            )

        # 2. Generate via Gemini
        generated = await gemini_service.generate_lecture_script(payload.topic, payload.grade)
        segments_raw = generated.get("segments", [])

        segments = [
            LectureSegment(
                segment_index=s["segment_index"],
                segment_title=s["segment_title"],
                narration_text=s["narration_text"],
                slide_bullets=s["slide_bullets"],
                diagram_description=s.get("diagram_description"),
                checkpoint=CheckpointQuestion(**s["checkpoint"])
            ) for s in segments_raw
        ]

        lecture_id = str(uuid.uuid4())
        created_at = datetime.now(timezone.utc)
        record = {
            "id": lecture_id,
            "topic": payload.topic,
            "grade": payload.grade,
            "segments_json": [s.model_dump() for s in segments],
            "created_at": created_at.isoformat()
        }

        if db.is_live:
            db.client.table("lectures").insert(record).execute()
        else:
            _mock_lectures[lecture_id] = record

        # Initialize or reset student lecture session
        cls.update_session(LectureSessionUpdate(
            student_id=payload.student_id,
            lecture_id=lecture_id,
            current_segment=0,
            completed=False
        ))

        return LectureResponse(
            lecture_id=lecture_id,
            topic=payload.topic,
            grade=payload.grade,
            total_segments=len(segments),
            segments=segments,
            created_at=created_at,
            is_cached=False
        )

    @classmethod
    def update_session(cls, update: LectureSessionUpdate) -> Dict[str, Any]:
        session_id = f"{update.student_id}_{update.lecture_id}"
        record = {
            "id": session_id,
            "student_id": update.student_id,
            "lecture_id": update.lecture_id,
            "current_segment": update.current_segment,
            "paused_at": datetime.now(timezone.utc).isoformat(),
            "completed": update.completed
        }

        if db.is_live:
            db.client.table("lecture_sessions").upsert(record).execute()
        else:
            _mock_sessions[session_id] = record

        return {"success": True, "session": record}

    @classmethod
    async def get_recap(cls, lecture_id: str, topic: str) -> LectureRecapResponse:
        recap_text = await gemini_service.generate_lecture_recap(topic, [])
        return LectureRecapResponse(
            lecture_id=lecture_id,
            topic=topic,
            recap_summary=recap_text,
            suggested_quiz_topic=topic
        )
