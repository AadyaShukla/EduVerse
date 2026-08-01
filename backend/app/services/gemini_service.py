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

    def sanitize_k12_output(self, text: str) -> str:
        """
        K-12 Content Safety Filter: Sanitizes response text for appropriate student context.
        """
        if not text:
            return ""

        inappropriate_keywords = ["violence", "explicit", "nsfw", "harmful"]
        lower_text = text.lower()
        for word in inappropriate_keywords:
            if word in lower_text:
                return "The generated content was flagged for safety and sanitized for K-12 educational standards."

        return text

    async def generate_response_stub(self, prompt: str, student_grade: Optional[int] = None) -> Dict[str, Any]:
        """
        Simulates calling Google Gemini API 1.5 Flash (free tier) with K-12 safety settings.
        """
        if not self.is_configured:
            return {
                "text": f"Stub Gemini response for grade {student_grade or 'general'}: Content sanitized for K-12 safety.",
                "status": "mock"
            }

        try:
            import google.generativeai as genai
            model = genai.GenerativeModel(
                'gemini-1.5-flash',
                safety_settings={
                    "HARASSMENT": "BLOCK_LOW_AND_ABOVE",
                    "HATE_SPEECH": "BLOCK_LOW_AND_ABOVE",
                    "SEXUALLY_EXPLICIT": "BLOCK_LOW_AND_ABOVE",
                    "DANGEROUS_CONTENT": "BLOCK_LOW_AND_ABOVE",
                }
            )
            response = await model.generate_content_async(prompt)
            sanitized = self.sanitize_k12_output(response.text)
            return {"text": sanitized, "status": "success"}
        except Exception as e:
            return {"text": f"Error calling Gemini: {e}", "status": "error"}

    def _clean_json_string(self, text: str) -> str:
        text = text.replace("```json", "").replace("```", "")
        return text.strip()

    async def generate_lecture_script(self, topic: str, grade: int) -> Dict[str, Any]:
        """
        Generate a multi-segment interactive lecture with slides and checkpoint questions.
        """
        prompt = f"""
Generate an interactive 3-segment AI lecture script for Grade {grade} on topic '{topic}'.
Return strictly valid JSON with this exact structure:
{{
  "topic": "{topic}",
  "segments": [
    {{
      "segment_index": 0,
      "segment_title": "Introduction & Basic Concepts",
      "narration_text": "Welcome! Today we are exploring {topic}...",
      "slide_bullets": ["Key Point 1", "Key Point 2", "Key Point 3"],
      "diagram_description": "A simple diagram illustrating {topic}",
      "checkpoint": {{
        "question": "Sample Checkpoint Question 1",
        "options": ["Option A", "Option B", "Option C", "Option D"],
        "correct_answer": "Option A",
        "explanation": "Explanation for Option A",
        "recap_text": "Let's review: Key concept recap..."
      }}
    }},
    {{
      "segment_index": 1,
      "segment_title": "Deep Dive & Applications",
      "narration_text": "Now let's look closer at how {topic} works in practice...",
      "slide_bullets": ["Application 1", "Application 2"],
      "diagram_description": "Process flowchart",
      "checkpoint": {{
        "question": "Sample Checkpoint Question 2",
        "options": ["Option A", "Option B", "Option C", "Option D"],
        "correct_answer": "Option B",
        "explanation": "Explanation for Option B",
        "recap_text": "Quick recap of application..."
      }}
    }},
    {{
      "segment_index": 2,
      "segment_title": "Summary & Advanced Takeaways",
      "narration_text": "To wrap up our lesson on {topic}...",
      "slide_bullets": ["Summary Point 1", "Summary Point 2"],
      "diagram_description": "Summary chart",
      "checkpoint": {{
        "question": "Sample Checkpoint Question 3",
        "options": ["Option A", "Option B", "Option C", "Option D"],
        "correct_answer": "Option C",
        "explanation": "Explanation for Option C",
        "recap_text": "Final segment recap..."
      }}
    }}
  ]
}}
"""
        if self.is_configured:
            res = await self.generate_response_stub(prompt, student_grade=grade)
            if res.get("text"):
                try:
                    cleaned = self._clean_json_string(res["text"])
                    return json.loads(cleaned)
                except Exception:
                    pass

        return {
            "topic": topic,
            "segments": [
                {
                    "segment_index": 0,
                    "segment_title": f"Introduction to {topic}",
                    "narration_text": f"Welcome to our lesson on {topic}! Today we will discover core principles suitable for Grade {grade}.",
                    "slide_bullets": [f"Definition of {topic}", "Core Principles", "Key Formula/Rule"],
                    "diagram_description": "Concept Overview Diagram",
                    "checkpoint": {
                        "question": f"What is the main focus of {topic}?",
                        "options": ["Core Principles", "History only", "Unrelated topic", "None"],
                        "correct_answer": "Core Principles",
                        "explanation": f"Core principles form the foundation of {topic}.",
                        "recap_text": f"Remember, {topic} relies on fundamental principles."
                    }
                },
                {
                    "segment_index": 1,
                    "segment_title": f"Step-by-Step Applications",
                    "narration_text": f"Now let's apply {topic} through practical step-by-step problem solving.",
                    "slide_bullets": ["Step 1: Identify Given Data", "Step 2: Apply Rules", "Step 3: Solve"],
                    "diagram_description": "Step-by-Step Flowchart",
                    "checkpoint": {
                        "question": "What is the first step in solving these problems?",
                        "options": ["Guess the answer", "Identify Given Data", "Skip to end", "Ignore rules"],
                        "correct_answer": "Identify Given Data",
                        "explanation": "Always start by identifying given information.",
                        "recap_text": "First identify data, then apply core rules."
                    }
                }
            ]
        }

    async def generate_lecture_recap(self, topic: str, segments: list) -> str:
        prompt = f"Write a short 2-3 sentence end-of-lecture recap for '{topic}'."
        if self.is_configured:
            res = await self.generate_response_stub(prompt)
            if res.get("text"):
                return res["text"].strip()
        return f"Great job completing the lecture on {topic}! You mastered the core definitions, step-by-step applications, and key takeaways."

gemini_service = GeminiService()

