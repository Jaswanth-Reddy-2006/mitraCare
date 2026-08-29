from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.services.patient_service import PatientService
from app.schemas.patient_features import ReminderResponse

router = APIRouter()

@router.get("/reminders", response_model=List[ReminderResponse])
def get_reminders(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return PatientService.get_reminders(db, current_user.id)

@router.get("/reminders/today", response_model=List[ReminderResponse])
def get_reminders_for_today(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return PatientService.get_reminders_for_today(db, current_user.id)

@router.post("/reminders/{reminder_id}/complete", response_model=ReminderResponse)
def complete_reminder(
    reminder_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return PatientService.complete_reminder(db, current_user.id, reminder_id)

@router.post("/reminders/{reminder_id}/snooze", response_model=ReminderResponse)
def snooze_reminder(
    reminder_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return PatientService.snooze_reminder(db, current_user.id, reminder_id)
