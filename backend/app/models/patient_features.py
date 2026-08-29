import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, DateTime, Boolean, ForeignKey, Index
from sqlalchemy.orm import relationship
from app.core.database import Base

def generate_uuid():
    return str(uuid.uuid4())

class ActivityCategory(Base):
    __tablename__ = "activity_categories"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    name = Column(String, unique=True, nullable=False, index=True)
    description = Column(String, nullable=True)

    activities = relationship("Activity", back_populates="category", cascade="all, delete-orphan")

class Activity(Base):
    __tablename__ = "activities"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    category_id = Column(String(36), ForeignKey("activity_categories.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    icon = Column(String, nullable=False) # e.g. "psychology", "calendar_today"
    difficulty = Column(String, default="MEDIUM") # "EASY", "MEDIUM", "HARD"
    estimated_duration = Column(Integer, default=300) # duration in seconds
    language = Column(String, default="en")
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    category = relationship("ActivityCategory", back_populates="activities")
    sessions = relationship("ActivitySession", back_populates="activity", cascade="all, delete-orphan")

class ActivitySession(Base):
    __tablename__ = "activity_sessions"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    patient_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    activity_id = Column(String(36), ForeignKey("activities.id", ondelete="CASCADE"), nullable=False, index=True)
    started_at = Column(DateTime, default=datetime.utcnow, index=True)
    completed_at = Column(DateTime, nullable=True)
    status = Column(String, default="STARTED") # "STARTED", "COMPLETED", "ABANDONED"
    difficulty_level = Column(String, nullable=True)

    # Relationships
    activity = relationship("Activity", back_populates="sessions")
    result = relationship("ActivityResult", back_populates="session", uselist=False, cascade="all, delete-orphan")
    patient = relationship("User")

class ActivityResult(Base):
    __tablename__ = "activity_results"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    session_id = Column(String(36), ForeignKey("activity_sessions.id", ondelete="CASCADE"), nullable=False, unique=True, index=True)
    score = Column(Integer, nullable=False)
    accuracy = Column(Float, default=1.0)
    response_time = Column(Integer, nullable=True) # response time in milliseconds
    mistakes = Column(Integer, default=0)
    hints_used = Column(Integer, default=0)
    metadata_json = Column(String, nullable=True) # JSON string for game specifics
    
    created_at = Column(DateTime, default=datetime.utcnow, index=True)

    # Relationships
    session = relationship("ActivitySession", back_populates="result")

class DailyTask(Base):
    __tablename__ = "daily_tasks"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    patient_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    task_type = Column(String, nullable=False, index=True) # "MEDICATION", "HYDRATION", "ACTIVITY", "APPOINTMENT", "DAILY_ROUTINE", "CUSTOM"
    scheduled_time = Column(String, nullable=False) # e.g. "09:00"
    date = Column(String(10), nullable=False, index=True) # "YYYY-MM-DD"
    status = Column(String, default="PENDING") # "PENDING", "COMPLETED", "SKIPPED", "SNOOZED"
    completed_at = Column(DateTime, nullable=True)
    recurrence_rule = Column(String, nullable=True)
    priority = Column(String, default="MEDIUM")
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    patient = relationship("User")

class Reminder(Base):
    __tablename__ = "reminders"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    patient_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    type = Column(String, nullable=False, index=True) # "MEDICINE", "WATER", "ACTIVITY", "APPOINTMENT"
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    scheduled_at = Column(DateTime, nullable=False, index=True) # timezone aware (handled by client/server)
    recurrence_rule = Column(String, nullable=True)
    status = Column(String, default="PENDING") # "PENDING", "COMPLETED", "SNOOZED"
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    patient = relationship("User")

# Indexes for common query combinations
Index("idx_tasks_patient_date", DailyTask.patient_id, DailyTask.date)
Index("idx_reminders_patient_active", Reminder.patient_id, Reminder.is_active)

class PatientMood(Base):
    __tablename__ = "patient_moods"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    patient_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    mood = Column(String, nullable=False) # "GOOD", "NORMAL", "SAD"
    recorded_date = Column(String(10), nullable=False, index=True) # YYYY-MM-DD
    created_at = Column(DateTime, default=datetime.utcnow)

    patient = relationship("User")

class PatientAlert(Base):
    __tablename__ = "patient_alerts"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    patient_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    alert_type = Column(String, nullable=False, index=True) # e.g. MEDICINE_MISSED, LOW_ACTIVITY, GOOD_PROGRESS
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)

    patient = relationship("User")

Index("idx_moods_patient_date", PatientMood.patient_id, PatientMood.recorded_date)
Index("idx_alerts_patient_unread", PatientAlert.patient_id, PatientAlert.is_read)
