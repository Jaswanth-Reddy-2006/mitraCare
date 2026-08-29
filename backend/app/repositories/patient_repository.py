from sqlalchemy.orm import Session
from datetime import datetime
from typing import List, Optional
from app.models.patient_features import (
    ActivityCategory, Activity, ActivitySession, ActivityResult, DailyTask, Reminder
)

class ActivityRepository:
    @staticmethod
    def get_activities(db: Session) -> List[Activity]:
        return db.query(Activity).filter(Activity.is_active == True).all()

    @staticmethod
    def get_activity_by_id(db: Session, activity_id: str) -> Optional[Activity]:
        return db.query(Activity).filter(Activity.id == activity_id, Activity.is_active == True).first()

    @staticmethod
    def create_session(db: Session, patient_id: str, activity_id: str, difficulty_level: str = None) -> ActivitySession:
        session = ActivitySession(
            patient_id=patient_id,
            activity_id=activity_id,
            difficulty_level=difficulty_level,
            status="STARTED",
            started_at=datetime.utcnow()
        )
        db.add(session)
        db.commit()
        db.refresh(session)
        return session

    @staticmethod
    def get_session_by_id(db: Session, session_id: str) -> Optional[ActivitySession]:
        return db.query(ActivitySession).filter(ActivitySession.id == session_id).first()

    @staticmethod
    def create_result(
        db: Session, 
        session_id: str, 
        score: int, 
        accuracy: float, 
        response_time: int = None, 
        mistakes: int = 0, 
        hints_used: int = 0, 
        metadata_json: str = None
    ) -> ActivityResult:
        result = ActivityResult(
            session_id=session_id,
            score=score,
            accuracy=accuracy,
            response_time=response_time,
            mistakes=mistakes,
            hints_used=hints_used,
            metadata_json=metadata_json,
            created_at=datetime.utcnow()
        )
        db.add(result)
        db.commit()
        db.refresh(result)
        return result

    @staticmethod
    def get_history(db: Session, patient_id: str) -> List[ActivitySession]:
        return db.query(ActivitySession).filter(
            ActivitySession.patient_id == patient_id,
            ActivitySession.status == "COMPLETED"
        ).order_by(ActivitySession.completed_at.desc()).all()

class DailyTaskRepository:
    @staticmethod
    def get_tasks_for_date(db: Session, patient_id: str, date_str: str) -> List[DailyTask]:
        return db.query(DailyTask).filter(
            DailyTask.patient_id == patient_id,
            DailyTask.date == date_str
        ).order_by(DailyTask.scheduled_time.asc()).all()

    @staticmethod
    def get_task_by_id(db: Session, task_id: str) -> Optional[DailyTask]:
        return db.query(DailyTask).filter(DailyTask.id == task_id).first()

    @staticmethod
    def update_task(db: Session, task: DailyTask) -> DailyTask:
        db.add(task)
        db.commit()
        db.refresh(task)
        return task

class ReminderRepository:
    @staticmethod
    def get_reminders(db: Session, patient_id: str) -> List[Reminder]:
        return db.query(Reminder).filter(
            Reminder.patient_id == patient_id,
            Reminder.is_active == True
        ).order_by(Reminder.scheduled_at.asc()).all()

    @staticmethod
    def get_reminder_by_id(db: Session, reminder_id: str) -> Optional[Reminder]:
        return db.query(Reminder).filter(
            Reminder.id == reminder_id,
            Reminder.is_active == True
        ).first()

    @staticmethod
    def update_reminder(db: Session, reminder: Reminder) -> Reminder:
        db.add(reminder)
        db.commit()
        db.refresh(reminder)
        return reminder

    @staticmethod
    def create_reminder(db: Session, patient_id: str, type: str, title: str, description: Optional[str], scheduled_at: datetime) -> Reminder:
        import uuid
        reminder = Reminder(
            id=str(uuid.uuid4()),
            patient_id=patient_id,
            type=type,
            title=title,
            description=description,
            scheduled_at=scheduled_at,
            status="PENDING",
            is_active=True
        )
        db.add(reminder)
        db.commit()
        db.refresh(reminder)
        return reminder
