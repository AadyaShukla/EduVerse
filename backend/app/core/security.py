from fastapi import HTTPException, status
from typing import Optional

def verify_student_access(request_user_id: str, target_student_id: str, is_guardian: bool = False):
    """
    Authorization helper ensuring a user (student or linked guardian)
    only accesses authorized student data.
    """
    if not request_user_id or not target_student_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required for student data access."
        )

    # Strictly verify ID alignment
    if request_user_id != target_student_id and not is_guardian:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied: You are not authorized to view another student's data."
        )
