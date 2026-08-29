from pydantic import BaseModel, ConfigDict
from typing import Optional, List
from datetime import datetime

class ActivityCategoryBase(BaseModel):
    name: str
    description: Optional[str] = None

class ActivityCategoryResponse(ActivityCategoryBase):
    id: str
    model_config = ConfigDict(from_attributes=True)

class ActivityBase(BaseModel):
    category_id: str
    title: str
    description: Optional[str] = None
    icon: str
    difficulty: str
    estimated_duration: int
    language: str
    is_active: bool

class ActivityResponse(ActivityBase):
    id: str
    model_config = ConfigDict(from_attributes=True)

class ActivitySessionCreate(BaseModel):
    activity_id: str
    difficulty_level: Optional[str] = None

class ActivitySessionResponse(BaseModel):
    id: str
    patient_id: str
    activity_id: str
    started_at: datetime
    completed_at: Optional[datetime] = None
    status: str
    difficulty_level: Optional[str] = None
    model_config = ConfigDict(from_attributes=True)

class ActivityResultCreate(BaseModel):
    score: int
    accuracy: float
    response_time: Optional[int] = None
    mistakes: int = 0
    hints_used: int = 0
    metadata_json: Optional[str] = None

class ActivityResultResponse(BaseModel):
    id: str
    session_id: str
    score: int
    accuracy: float
    response_time: Optional[int] = None
    mistakes: int
    hints_used: int
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

class DailyTaskResponse(BaseModel):
    id: str
    patient_id: str
    title: str
    description: Optional[str] = None
    task_type: str
    scheduled_time: str
    date: str
    status: str
    completed_at: Optional[datetime] = None
    model_config = ConfigDict(from_attributes=True)

class ReminderResponse(BaseModel):
    id: str
    patient_id: str
    type: str
    title: str
    description: Optional[str] = None
    scheduled_at: datetime
    status: str
    is_active: bool
    model_config = ConfigDict(from_attributes=True)
