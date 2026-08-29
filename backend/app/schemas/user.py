from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    name: str
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    role: str  # "PATIENT", "CAREGIVER", "ADMIN", "HEALTHCARE_WORKER"
    preferred_language: str = "en"

class UserRegister(BaseModel):
    name: str
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    password: str
    role: str
    preferred_language: Optional[str] = "en"
    
    # Optional fields for initial profiles
    age: Optional[int] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    organization: Optional[str] = None

class UserLogin(BaseModel):
    username: str  # Email or phone number
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    name: str
    user_id: str

class PatientProfileSchema(BaseModel):
    age: Optional[int] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    profile_photo_url: Optional[str] = None

    class Config:
        from_attributes = True

class CaregiverProfileSchema(BaseModel):
    organization: Optional[str] = None

    class Config:
        from_attributes = True

class UserResponse(UserBase):
    id: str
    created_at: datetime
    patient_profile: Optional[PatientProfileSchema] = None
    caregiver_profile: Optional[CaregiverProfileSchema] = None

    class Config:
        from_attributes = True

class PatientOnboard(BaseModel):
    age: Optional[int] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    profile_photo_url: Optional[str] = None

class ConnectionCodeResponse(BaseModel):
    code: str
    expires_at: datetime

    class Config:
        from_attributes = True

class JoinCodeRequest(BaseModel):
    code: str
