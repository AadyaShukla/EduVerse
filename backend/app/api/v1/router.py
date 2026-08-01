from fastapi import APIRouter
from app.api.v1.endpoints import auth, guardians, lectures, doubt_solver, quiz_generator, productivity, wellbeing

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(guardians.router, prefix="/guardians", tags=["guardians"])
api_router.include_router(lectures.router, prefix="/lectures", tags=["lectures"])
api_router.include_router(doubt_solver.router, prefix="/doubt-solver", tags=["doubt-solver"])
api_router.include_router(quiz_generator.router, prefix="/quiz-generator", tags=["quiz-generator"])
api_router.include_router(productivity.router, prefix="/productivity", tags=["productivity"])
api_router.include_router(wellbeing.router, prefix="/wellbeing", tags=["wellbeing"])
