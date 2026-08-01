import os
from typing import Optional, Dict, Any
from app.core.config import settings

class GeminiService:
    """
    Scaffold service for Google Gemini API integration (Free Tier).
    Configured for future doubt solving & adaptive lecture content generation.
    """

    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY or os.getenv("GEMINI_API_KEY", "")
        self._model = None
        
        if self.api_key:
            try:
                import google.generativeai as genai
                genai.configure(api_key=self.api_key)
                self._model = genai.GenerativeModel("gemini-1.5-flash")
                print("[GeminiService] Initialized Gemini 1.5 Flash client.")
            except Exception as e:
                print(f"[GeminiService] Warning: Could not initialize google.generativeai: {e}")

    @property
    def is_configured(self) -> bool:
        return self._model is not None

    async def generate_response_stub(self, prompt: str, student_grade: int) -> Dict[str, Any]:
        """
        Placeholder response generator for Phase 0.
        """
        if self._model:
            try:
                response = await self._model.generate_content_async(
                    f"You are EduVerse AI Tutor for Grade {student_grade}. Answer: {prompt}"
                )
                return {"text": response.text, "status": "success"}
            except Exception as e:
                return {"text": f"Gemini API call failed: {str(e)}", "status": "error"}

        return {
            "text": f"[Phase 0 Gemini Stub for Grade {student_grade}]: Received prompt '{prompt}'. Configure GEMINI_API_KEY in backend/.env for live LLM responses.",
            "status": "mock"
        }

gemini_service = GeminiService()
