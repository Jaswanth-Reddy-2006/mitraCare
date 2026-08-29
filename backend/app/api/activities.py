from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.services.patient_service import PatientService
from app.schemas.patient_features import (
    ActivityResponse, ActivitySessionCreate, ActivitySessionResponse, 
    ActivityResultCreate, ActivityResultResponse
)

router = APIRouter()

@router.get("/activities", response_model=List[ActivityResponse])
def get_activities(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return PatientService.get_activities(db)

@router.get("/activities/{activity_id}", response_model=ActivityResponse)
def get_activity(
    activity_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return PatientService.get_activity(db, activity_id)

@router.post("/activity-sessions", response_model=ActivitySessionResponse)
def start_session(
    session_in: ActivitySessionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return PatientService.start_session(
        db=db,
        patient_id=current_user.id,
        activity_id=session_in.activity_id,
        difficulty_level=session_in.difficulty_level
    )

@router.post("/activity-sessions/{session_id}/result", response_model=ActivityResultResponse)
def submit_result(
    session_id: str,
    result_in: ActivityResultCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return PatientService.submit_result(
        db=db,
        patient_id=current_user.id,
        session_id=session_id,
        result_in=result_in
    )

@router.get("/activity-history", response_model=List[ActivitySessionResponse])
def get_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return PatientService.get_history(db, current_user.id)
