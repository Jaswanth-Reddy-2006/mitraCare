from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.services.patient_service import PatientService
from app.schemas.patient_features import DailyTaskResponse

router = APIRouter()

@router.get("/my-day", response_model=List[DailyTaskResponse])
def get_my_day(
    date: Optional[str] = Query(None, regex=r"^\d{4}-\d{2}-\d{2}$"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not date:
        date = datetime.utcnow().strftime("%Y-%m-%d")
    return PatientService.get_my_day(db, current_user.id, date)

@router.post("/my-day/tasks/{task_id}/complete", response_model=DailyTaskResponse)
def complete_task(
    task_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return PatientService.complete_task(db, current_user.id, task_id)

@router.post("/my-day/tasks/{task_id}/skip", response_model=DailyTaskResponse)
def skip_task(
    task_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return PatientService.skip_task(db, current_user.id, task_id)

@router.post("/my-day/tasks/{task_id}/snooze", response_model=DailyTaskResponse)
def snooze_task(
    task_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return PatientService.snooze_task(db, current_user.id, task_id)
