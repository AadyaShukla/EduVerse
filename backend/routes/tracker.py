from fastapi import APIRouter
from backend.models.schemas import QuizAttemptRequest, WeakTopic
from backend.routes.quiz_generator import MOCK_DB_QUIZ_ATTEMPTS, MOCK_DB_WEAK_TOPICS, MOCK_DB_REVISION
from backend.routes.doubt_solver import MOCK_DB_DOUBTS
import uuid
import datetime

router = APIRouter()

@router.post("/attempt")
def log_quiz_attempt(request: QuizAttemptRequest):
    attempt_id = uuid.uuid4()
    MOCK_DB_QUIZ_ATTEMPTS[attempt_id] = {
        "id": attempt_id,
        "quiz_id": request.quiz_id,
        "student_id": request.student_id,
        "score": request.score,
        "answers_json": request.answers,
        "completed_at": datetime.datetime.now(datetime.timezone.utc)
    }

    # Update weak topics and spaced repetition
    for topic in request.weak_topics:
        # Weak Topics tracking
        if topic not in MOCK_DB_WEAK_TOPICS:
            MOCK_DB_WEAK_TOPICS[topic] = {
                "id": uuid.uuid4(),
                "student_id": request.student_id,
                "topic": topic,
                "times_wrong": 0,
                "last_updated": datetime.datetime.now(datetime.timezone.utc)
            }
        MOCK_DB_WEAK_TOPICS[topic]["times_wrong"] += 1
        MOCK_DB_WEAK_TOPICS[topic]["last_updated"] = datetime.datetime.now(datetime.timezone.utc)

        # Basic Spaced Repetition logic: 1, 3, 7 days
        current_times_wrong = MOCK_DB_WEAK_TOPICS[topic]["times_wrong"]
        if current_times_wrong == 1:
            days_to_add = 1
        elif current_times_wrong == 2:
            days_to_add = 3
        else:
            days_to_add = 7

        MOCK_DB_REVISION[topic] = {
            "id": uuid.uuid4(),
            "student_id": request.student_id,
            "topic": topic,
            "next_review_date": datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=days_to_add)
        }

    return {"message": "Attempt logged successfully"}

@router.get("/weak-topics", response_model=list[WeakTopic])
def get_weak_topics(student_id: uuid.UUID):
    # Base from quizzes
    topics = {}
    for t in MOCK_DB_WEAK_TOPICS.values():
        if t["student_id"] == student_id:
            topics[t["topic"]] = t["times_wrong"]

    # Also analyze doubts to add to weak topics
    for d in MOCK_DB_DOUBTS.values():
        if d["student_id"] == student_id:
            # We don't have topic extraction, so use a placeholder generic or 'Doubt topic' logic.
            # Ideally NLP would extract topic. We will use a mock "Doubt" topic.
            doubt_topic = "Topic from Doubts"
            if doubt_topic in topics:
                topics[doubt_topic] += 1
            else:
                topics[doubt_topic] = 1

    result = [WeakTopic(topic=k, times_wrong=v) for k, v in topics.items()]
    result.sort(key=lambda x: x.times_wrong, reverse=True)
    return result
