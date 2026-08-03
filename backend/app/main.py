from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from app.core.config import settings
from app.api.v1.router import api_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/", response_class=HTMLResponse, tags=["health"])
def web_dashboard():
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>EduVerse Web Hub</title>
        <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0f0e17; color: #fffffe; margin: 0; padding: 40px; }
            .container { max-width: 900px; margin: 0 auto; }
            .card { background: #1f1d2b; border-radius: 20px; padding: 24px; margin-bottom: 20px; border: 1px solid #6c5ce7; }
            h1 { color: #6c5ce7; font-size: 32px; }
            h2 { color: #00cec9; margin-top: 0; }
            .btn { display: inline-block; background: #6c5ce7; color: white; padding: 12px 24px; border-radius: 12px; text-decoration: none; font-weight: bold; margin-top: 10px; }
            .btn-accent { background: #00cec9; color: #0f0e17; }
            .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 20px; }
            .pill { background: rgba(255,255,255,0.1); padding: 6px 12px; border-radius: 12px; font-size: 12px; color: #a7a9be; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="card" style="background: linear-gradient(135deg, #6c5ce7, #a29bfe);">
                <h1 style="color:white; margin:0;">EduVerse Interactive Web Hub</h1>
                <p style="color:rgba(255,255,255,0.9);">AI Study Assistant, Doubts Solver, Adaptive Quizzes & Guardian Portal</p>
                <span class="pill" style="background:rgba(255,255,255,0.25); color:white;">Status: Online & Healthy</span>
            </div>

            <div class="grid">
                <div class="card">
                    <h2>Interactive API Docs</h2>
                    <p>Test all API endpoints live via Swagger UI.</p>
                    <a href="/docs" target="_blank" class="btn">Open Swagger UI (/docs)</a>
                </div>
                <div class="card">
                    <h2>ReDoc API Reference</h2>
                    <p>Detailed OpenAPI schemas and endpoint docs.</p>
                    <a href="/redoc" target="_blank" class="btn btn-accent">Open ReDoc (/redoc)</a>
                </div>
            </div>

            <div class="card">
                <h2>Phase 0–9 Complete Feature Modules</h2>
                <ul>
                    <li><strong>AI Doubt Solver</strong>: Step-by-step explanations in English, Hindi & multilingual</li>
                    <li><strong>Interactive AI Lectures</strong>: Slide narration & pause-and-ask doubts</li>
                    <li><strong>Adaptive Quizzes</strong>: Score-based difficulty scaling</li>
                    <li><strong>Productivity Suite</strong>: Notes auto-tagging, OCR handwriting & timetable</li>
                    <li><strong>Wellbeing</strong>: Pomodoro sessions, XP streaks & anti-addiction nudge</li>
                    <li><strong>Guardian Portal</strong>: 1-on-1 metrics & daily cached Gemini insights</li>
                    <li><strong>Offline Mode</strong>: SQLite caching & sync queue engine</li>
                    <li><strong>Safety & Compliance</strong>: K-12 content filter & Right to be Forgotten</li>
                </ul>
            </div>
        </div>
    </body>
    </html>
    """

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
