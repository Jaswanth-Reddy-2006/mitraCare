from datetime import datetime, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User, CaregiverPatientRelationship, PatientProfile
from app.models.patient_features import DailyTask, Reminder, ActivitySession, ActivityResult, Activity, PatientMood, PatientAlert

router = APIRouter()

# --- Schemas ---

class TaskCreateRequest(BaseModel):
    title: str
    description: Optional[str] = None
    task_type: str  # "MEDICATION", "HYDRATION", "ACTIVITY", "APPOINTMENT", "DAILY_ROUTINE"
    scheduled_time: str  # e.g., "09:00"
    date: str  # "YYYY-MM-DD"
    priority: Optional[str] = "MEDIUM"

class ReminderCreateRequest(BaseModel):
    type: str  # "MEDICINE", "WATER", "ACTIVITY", "APPOINTMENT"
    title: str
    description: Optional[str] = None
    scheduled_at: datetime
    recurrence_rule: Optional[str] = None

class PatientProfileUpdateRequest(BaseModel):
    age: Optional[int] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    preferred_language: Optional[str] = None

# --- Ownership Guard ---

def verify_caregiver_patient_relationship(caregiver_id: str, patient_id: str, db: Session):
    relation = db.query(CaregiverPatientRelationship).filter(
        CaregiverPatientRelationship.caregiver_id == caregiver_id,
        CaregiverPatientRelationship.patient_id == patient_id,
        CaregiverPatientRelationship.status == "ACTIVE"
    ).first()
    if not relation:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to view or edit this patient's data."
        )

# --- Routes ---

@router.get("/dashboard-summary")
def get_dashboard_summary(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "CAREGIVER":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Caregivers can access dashboard summary."
        )
    
    verify_caregiver_patient_relationship(current_user.id, patient_id, db)
    
    # 1. Fetch patient user and profile details
    patient = db.query(User).filter(User.id == patient_id).first()
    profile = db.query(PatientProfile).filter(PatientProfile.id == patient_id).first()
    
    today_str = datetime.utcnow().strftime("%Y-%m-%d")
    
    # 2. Count Daily Tasks status
    total_tasks = db.query(DailyTask).filter(
        DailyTask.patient_id == patient_id,
        DailyTask.date == today_str
    ).count()
    
    completed_tasks = db.query(DailyTask).filter(
        DailyTask.patient_id == patient_id,
        DailyTask.date == today_str,
        DailyTask.status == "COMPLETED"
    ).count()
    
    # 3. Games played today
    games_played = db.query(ActivitySession).filter(
        ActivitySession.patient_id == patient_id,
        ActivitySession.status == "COMPLETED",
        func.date(ActivitySession.started_at) == datetime.utcnow().date()
    ).count()
    
    # 4. Latest recorded mood
    latest_mood_rec = db.query(PatientMood).filter(
        PatientMood.patient_id == patient_id,
        PatientMood.recorded_date == today_str
    ).order_by(PatientMood.created_at.desc()).first()
    mood_str = latest_mood_rec.mood if latest_mood_rec else "Good" # default placeholder
    
    # 5. Average Cognitive Score (from game sessions)
    avg_score_query = db.query(func.avg(ActivityResult.score)).join(ActivitySession).filter(
        ActivitySession.patient_id == patient_id,
        ActivitySession.status == "COMPLETED"
    ).scalar()
    cognitive_score = int(avg_score_query) if avg_score_query is not None else 72 # default placeholder
    
    # 6. Recent Activity List
    recent_sessions = db.query(ActivitySession).filter(
        ActivitySession.patient_id == patient_id,
        ActivitySession.status == "COMPLETED"
    ).order_by(ActivitySession.started_at.desc()).limit(5).all()
    
    recent_activities = []
    for s in recent_sessions:
        act = db.query(Activity).filter(Activity.id == s.activity_id).first()
        res = db.query(ActivityResult).filter(ActivityResult.session_id == s.id).first()
        if act and res:
            recent_activities.append({
                "title": act.title,
                "score": res.score,
                "completed_at": s.completed_at or s.started_at
            })
            
    # Mock some default recent activities if empty
    if not recent_activities:
        recent_activities = [
            {"title": "Memory Game", "score": 80, "completed_at": datetime.utcnow() - timedelta(hours=2)},
            {"title": "Bihu Drum Rhythm", "score": 100, "completed_at": datetime.utcnow() - timedelta(hours=4)},
        ]
        
    return {
        "patient_name": patient.name,
        "age": profile.age if profile else 72,
        "completed_tasks_count": completed_tasks,
        "total_tasks_count": total_tasks if total_tasks > 0 else 5,
        "games_played_today": games_played if games_played > 0 else 2,
        "latest_mood": mood_str,
        "cognitive_score": cognitive_score,
        "recent_activities": recent_activities
    }

@router.get("/reports")
def get_cognitive_reports(
    patient_id: str,
    range_days: int = 30,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "CAREGIVER":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Caregivers can access cognitive reports."
        )
    verify_caregiver_patient_relationship(current_user.id, patient_id, db)
    
    # Fetch score trend coordinates
    cutoff_date = datetime.utcnow() - timedelta(days=range_days)
    results = db.query(
        func.date(ActivitySession.started_at).label("date"),
        func.avg(ActivityResult.score).label("score")
    ).join(ActivityResult, ActivityResult.session_id == ActivitySession.id).filter(
        ActivitySession.patient_id == patient_id,
        ActivitySession.started_at >= cutoff_date
    ).group_by(func.date(ActivitySession.started_at)).order_by("date").all()
    
    score_trends = [{"date": r.date.strftime("%d %b"), "score": int(r.score)} for r in results]
    
    if not score_trends:
        # Mock some default data points to display line chart cleanly
        score_trends = [
            {"date": "22 May", "score": 68},
            {"date": "29 May", "score": 75},
            {"date": "5 Jun", "score": 70},
            {"date": "12 Jun", "score": 82},
            {"date": "19 Jun", "score": 72},
        ]
        
    return {
        "score_trends": score_trends,
        "domain_performance": {
            "Memory": 78,
            "Attention": 68,
            "Language": 72,
            "Problem Solving": 65
        }
    }

@router.post("/patients/{patient_id}/tasks")
def add_patient_task(
    patient_id: str,
    req: TaskCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "CAREGIVER":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Caregivers can add patient tasks."
        )
    verify_caregiver_patient_relationship(current_user.id, patient_id, db)
    
    task = DailyTask(
        patient_id=patient_id,
        title=req.title,
        description=req.description,
        task_type=req.task_type,
        scheduled_time=req.scheduled_time,
        date=req.date,
        status="PENDING",
        priority=req.priority
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task

@router.delete("/patients/{patient_id}/tasks/{task_id}")
def delete_patient_task(
    patient_id: str,
    task_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "CAREGIVER":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN)
    verify_caregiver_patient_relationship(current_user.id, patient_id, db)
    
    task = db.query(DailyTask).filter(DailyTask.id == task_id, DailyTask.patient_id == patient_id).first()
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found.")
        
    db.delete(task)
    db.commit()
    return {"status": "success", "message": "Task deleted successfully."}

@router.post("/patients/{patient_id}/reminders")
def add_patient_reminder(
    patient_id: str,
    req: ReminderCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "CAREGIVER":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN)
    verify_caregiver_patient_relationship(current_user.id, patient_id, db)
    
    reminder = Reminder(
        patient_id=patient_id,
        type=req.type,
        title=req.title,
        description=req.description,
        scheduled_at=req.scheduled_at,
        recurrence_rule=req.recurrence_rule,
        status="PENDING",
        is_active=True
    )
    db.add(reminder)
    db.commit()
    db.refresh(reminder)
    return reminder

@router.delete("/patients/{patient_id}/reminders/{reminder_id}")
def delete_patient_reminder(
    patient_id: str,
    reminder_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "CAREGIVER":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN)
    verify_caregiver_patient_relationship(current_user.id, patient_id, db)
    
    reminder = db.query(Reminder).filter(Reminder.id == reminder_id, Reminder.patient_id == patient_id).first()
    if not reminder:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reminder not found.")
        
    db.delete(reminder)
    db.commit()
    return {"status": "success", "message": "Reminder deleted successfully."}

@router.get("/alerts")
def get_alerts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "CAREGIVER":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN)
        
    # Get connected patient IDs
    relations = db.query(CaregiverPatientRelationship).filter(
        CaregiverPatientRelationship.caregiver_id == current_user.id,
        CaregiverPatientRelationship.status == "ACTIVE"
    ).all()
    patient_ids = [r.patient_id for r in relations]
    
    alerts = db.query(PatientAlert).filter(
        PatientAlert.patient_id.in_(patient_ids)
    ).order_by(PatientAlert.created_at.desc()).all()
    
    if not alerts:
        # Seed default mock alerts for testing the UI
        alerts_data = [
            {"type": "MEDICINE_MISSED", "title": "Medicine Missed", "desc": "Amma missed morning medication."},
            {"type": "LOW_ACTIVITY", "title": "Low Activity", "desc": "Amma has not completed any activity today."},
            {"type": "GOOD_PROGRESS", "title": "Good Progress", "desc": "Great job! Cognitive score improved by 8%."},
            {"type": "APPOINTMENT_REMINDER", "title": "Appointment Reminder", "desc": "Doctor appointment tomorrow at 04:00 PM."}
        ]
        result = []
        for index, a in enumerate(alerts_data):
            result.append({
                "id": f"mock-alert-{index}",
                "alert_type": a["type"],
                "title": a["title"],
                "description": a["desc"],
                "is_read": False,
                "created_at": datetime.utcnow() - timedelta(hours=index * 3)
            })
        return result
        
    return alerts

@router.post("/patients/{patient_id}/profile")
def update_patient_profile(
    patient_id: str,
    req: PatientProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "CAREGIVER":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN)
    verify_caregiver_patient_relationship(current_user.id, patient_id, db)
    
    patient = db.query(User).filter(User.id == patient_id).first()
    profile = db.query(PatientProfile).filter(PatientProfile.id == patient_id).first()
    
    if req.preferred_language:
        patient.preferred_language = req.preferred_language
    if profile:
        if req.age is not None:
            profile.age = req.age
        if req.emergency_contact_name:
            profile.emergency_contact_name = req.emergency_contact_name
        if req.emergency_contact_phone:
            profile.emergency_contact_phone = req.emergency_contact_phone
            
    db.commit()
    return {"status": "success", "message": "Patient profile updated successfully."}
