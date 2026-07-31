from fastapi import FastAPI
from backend.routes import auth, guardians, doubt_solver

app = FastAPI(title="EduVerse API")

app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(guardians.router, prefix="/api/guardians", tags=["guardians"])
app.include_router(doubt_solver.router, prefix="/api/doubt-solver", tags=["doubt_solver"])

@app.get("/")
def root():
    return {"message": "Welcome to EduVerse API"}
