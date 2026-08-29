from sqlalchemy.orm import Session
from datetime import datetime
from fastapi import HTTPException, status
from typing import List, Optional
from app.repositories.patient_repository import ActivityRepository, DailyTaskRepository, ReminderRepository
from app.models.patient_features import Activity, ActivitySession, ActivityResult, DailyTask, Reminder
from app.schemas.patient_features import ActivityResultCreate

class PatientService:
    # --- Activities ---
    @staticmethod
    def get_activities(db: Session) -> List[Activity]:
        return ActivityRepository.get_activities(db)

    @staticmethod
    def get_activity(db: Session, activity_id: str) -> Activity:
        activity = ActivityRepository.get_activity_by_id(db, activity_id)
        if not activity:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity not found."
            )
        return activity

    @staticmethod
    def start_session(db: Session, patient_id: str, activity_id: str, difficulty_level: str = None) -> ActivitySession:
        # Verify activity exists
        PatientService.get_activity(db, activity_id)
        return ActivityRepository.create_session(db, patient_id, activity_id, difficulty_level)

    @staticmethod
    def submit_result(db: Session, patient_id: str, session_id: str, result_in: ActivityResultCreate) -> ActivityResult:
        session = ActivityRepository.get_session_by_id(db, session_id)
        if not session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Activity session not found."
            )
        
        # Enforce patient ownership
        if session.patient_id != patient_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have access to this activity session."
            )
            
        if session.status == "COMPLETED":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This activity session has already been completed."
            )

        # Complete session
        session.status = "COMPLETED"
        session.completed_at = datetime.utcnow()
        db.add(session)
        
        # Save result
        result = ActivityRepository.create_result(
            db=db,
            session_id=session_id,
            score=result_in.score,
            accuracy=result_in.accuracy,
            response_time=result_in.response_time,
            mistakes=result_in.mistakes,
            hints_used=result_in.hints_used,
            metadata_json=result_in.metadata_json
        )
        return result

    @staticmethod
    def get_history(db: Session, patient_id: str) -> List[ActivitySession]:
        return ActivityRepository.get_history(db, patient_id)

    # --- Daily Tasks ---
    @staticmethod
    def get_my_day(db: Session, patient_id: str, date_str: str) -> List[DailyTask]:
        return DailyTaskRepository.get_tasks_for_date(db, patient_id, date_str)

    @staticmethod
    def complete_task(db: Session, patient_id: str, task_id: str) -> DailyTask:
        task = DailyTaskRepository.get_task_by_id(db, task_id)
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found."
            )
            
        if task.patient_id != patient_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have access to this task."
            )

        task.status = "COMPLETED"
        task.completed_at = datetime.utcnow()
        return DailyTaskRepository.update_task(db, task)

    @staticmethod
    def skip_task(db: Session, patient_id: str, task_id: str) -> DailyTask:
        task = DailyTaskRepository.get_task_by_id(db, task_id)
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found."
            )
            
        if task.patient_id != patient_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have access to this task."
            )

        task.status = "SKIPPED"
        task.completed_at = None
        return DailyTaskRepository.update_task(db, task)

    @staticmethod
    def snooze_task(db: Session, patient_id: str, task_id: str) -> DailyTask:
        task = DailyTaskRepository.get_task_by_id(db, task_id)
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found."
            )
            
        if task.patient_id != patient_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have access to this task."
            )

        task.status = "SNOOZED"
        task.completed_at = None
        return DailyTaskRepository.update_task(db, task)

    # --- Reminders ---
    @staticmethod
    def get_reminders(db: Session, patient_id: str) -> List[Reminder]:
        return ReminderRepository.get_reminders(db, patient_id)

    @staticmethod
    def get_reminders_for_today(db: Session, patient_id: str) -> List[Reminder]:
        reminders = ReminderRepository.get_reminders(db, patient_id)
        today = datetime.utcnow().date()
        return [r for r in reminders if r.scheduled_at.date() == today]

    @staticmethod
    def complete_reminder(db: Session, patient_id: str, reminder_id: str) -> Reminder:
        reminder = ReminderRepository.get_reminder_by_id(db, reminder_id)
        if not reminder:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reminder not found."
            )
            
        if reminder.patient_id != patient_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have access to this reminder."
            )

        reminder.status = "COMPLETED"
        return ReminderRepository.update_reminder(db, reminder)

    @staticmethod
    def snooze_reminder(db: Session, patient_id: str, reminder_id: str) -> Reminder:
        reminder = ReminderRepository.get_reminder_by_id(db, reminder_id)
        if not reminder:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reminder not found."
            )
            
        if reminder.patient_id != patient_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have access to this reminder."
            )

        reminder.status = "SNOOZED"
        return ReminderRepository.update_reminder(db, reminder)
