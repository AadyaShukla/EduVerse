import uuid
import json
import re
from datetime import datetime, timezone
from typing import Dict, Any, List
from app.db.supabase_client import db
from app.schemas.doubt import (
    DoubtSolveRequest, DoubtSolveResponse, DoubtStep, DoubtHistoryItem
)
from app.services.gemini_service import gemini_service

class DoubtService:
    """
    Service for AI Doubt Explanation, Multilingual prompt generation,
    and Supabase logging.
    """

    @classmethod
    async def solve_doubt(cls, payload: DoubtSolveRequest) -> DoubtSolveResponse:
        doubt_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc)
        target_lang = payload.target_language or "English"

        prompt = f"""
You are an expert AI Tutor for EduVerse.
Target Language: {target_lang}
Question: {payload.question_text}

Provide a structured, step-by-step explanation.
Return ONLY a JSON object with this exact structure:
{{
  "detected_language": "English/Hindi/Spanish/etc",
  "topic": "Mathematics/Physics/etc",
  "summary": "Brief 1-sentence summary of the answer",
  "steps": [
    {{
      "step_number": 1,
      "title": "Identify Given Values",
      "explanation": "Explanation for step 1 in {target_lang}"
    }},
    {{
      "step_number": 2,
      "title": "Apply Formula",
      "explanation": "Explanation for step 2 in {target_lang}"
    }}
  ]
}}
"""
        res_data = None
        if gemini_service.is_configured:
            gemini_res = await gemini_service.generate_response_stub(prompt, student_grade=8)
            raw_text = gemini_res.get("text", "")
            try:
                # Extract JSON if enclosed in markdown code blocks
                match = re.search(r'\{.*\}', raw_text, re.DOTALL)
                if match:
                    res_data = json.loads(match.group(0))
            except Exception:
                pass

        # Fallback structured response generator if LLM response is mock or raw text parsing fails
        if not res_data:
            res_data = {
                "detected_language": target_lang,
                "topic": "General Study Topic",
                "summary": f"Step-by-step explanation for: '{payload.question_text[:50]}...'",
                "steps": [
                    {
                        "step_number": 1,
                        "title": "Understand the Problem Statement",
                        "explanation": f"In {target_lang}: Carefully read the question statement and extract known variables."
                    },
                    {
                        "step_number": 2,
                        "title": "Apply Foundational Principles",
                        "explanation": f"In {target_lang}: Formulate the governing formula or rule applicable to this problem."
                    },
                    {
                        "step_number": 3,
                        "title": "Calculate Final Solution",
                        "explanation": f"In {target_lang}: Substitute known values into the equation to obtain the verified result."
                    }
                ]
            }

        steps = [DoubtStep(**s) for s in res_data.get("steps", [])]
        summary = res_data.get("summary", "Step-by-step solution compiled.")
        detected_lang = res_data.get("detected_language", target_lang)
        topic = res_data.get("topic", "General")

        # Database logging to 'doubts' table
        db_record = {
            "id": doubt_id,
            "student_id": payload.student_id,
            "question_text": payload.question_text,
            "language": target_lang,
            "answer_summary": summary,
            "created_at": now.isoformat()
        }

        if db.is_live:
            db.client.table("doubts").insert(db_record).execute()
        else:
            db._mock_lectures[doubt_id] = db_record

        return DoubtSolveResponse(
            id=doubt_id,
            student_id=payload.student_id,
            question_text=payload.question_text,
            detected_language=detected_lang,
            explanation_language=target_lang,
            topic=topic,
            summary=summary,
            steps=steps,
            created_at=now
        )

    @classmethod
    def get_doubt_history(cls, student_id: str) -> List[DoubtHistoryItem]:
        if db.is_live:
            res = db.client.table("doubts").select("*").eq("student_id", student_id).order("created_at", desc=True).execute()
            return [DoubtHistoryItem(**item) for item in (res.data or [])]
        else:
            return [
                DoubtHistoryItem(
                    id=v["id"],
                    student_id=v["student_id"],
                    question_text=v["question_text"],
                    language=v["language"],
                    answer_summary=v["answer_summary"],
                    created_at=datetime.fromisoformat(v["created_at"])
                )
                for v in db._mock_lectures.values() if v.get("question_text")
            ]
