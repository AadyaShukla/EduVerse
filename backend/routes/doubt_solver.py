from fastapi import APIRouter, HTTPException
from backend.models.schemas import DoubtRequest, DoubtResponse
import google.generativeai as genai
import os
import uuid
import datetime

router = APIRouter()

MOCK_DB_DOUBTS = {}

@router.post("/", response_model=DoubtResponse)
def solve_doubt(request: DoubtRequest):
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return DoubtResponse(steps=["Mock step 1: 2+2 is 4", "Mock step 2: The Gemini API key is missing"])

    genai.configure(api_key=api_key)

    model = genai.GenerativeModel('gemini-1.5-flash') # Using flash for speed/free tier

    prompt = f"""
You are an expert tutor. Please explain the following question step-by-step.
Do not just give the final answer. Provide a list of clearly delineated steps.
Your response must be entirely in the language: {request.language}.

Format your response exactly as a numbered list where each item is a step.

Question: {request.question}
"""

    try:
        response = model.generate_content(prompt)
        text = response.text
        # Naive parsing of numbered list, or just split by newlines if it returns something else
        steps = [step.strip() for step in text.split('\n') if step.strip()]

        # Log to "DB"
        doubt_id = uuid.uuid4()
        MOCK_DB_DOUBTS[doubt_id] = {
            "id": doubt_id,
            "student_id": request.student_id,
            "question_text": request.question,
            "language": request.language,
            "answer_summary": " ".join(steps)[:200], # store a snippet
            "created_at": datetime.datetime.now(datetime.timezone.utc)
        }

        return DoubtResponse(steps=steps)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
