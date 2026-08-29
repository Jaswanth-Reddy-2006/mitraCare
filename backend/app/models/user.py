import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, DateTime, Boolean, ForeignKey, Enum
from sqlalchemy.orm import relationship
from app.core.database import Base

def generate_uuid():
    return str(uuid.uuid4())

class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=True, index=True)
    phone = Column(String, unique=True, nullable=True, index=True)
    password_hash = Column(String, nullable=False)
    role = Column(String, nullable=False)  # "PATIENT", "CAREGIVER", "ADMIN", "HEALTHCARE_WORKER"
    preferred_language = Column(String, default="en")
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    patient_profile = relationship("PatientProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    caregiver_profile = relationship("CaregiverProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")

class PatientProfile(Base):
    __tablename__ = "patient_profiles"

    id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    age = Column(Integer, nullable=True)
    emergency_contact_name = Column(String, nullable=True)
    emergency_contact_phone = Column(String, nullable=True)
    profile_photo_url = Column(String, nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="patient_profile")

class CaregiverProfile(Base):
    __tablename__ = "caregiver_profiles"

    id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    organization = Column(String, nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="caregiver_profile")

class CaregiverPatientRelationship(Base):
    __tablename__ = "caregiver_patient_relationships"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    caregiver_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    patient_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    status = Column(String, default="ACTIVE")  # "ACTIVE", "PENDING", "INACTIVE", "REJECTED"
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    caregiver = relationship("User", foreign_keys=[caregiver_id])
    patient = relationship("User", foreign_keys=[patient_id])

class ConnectionCode(Base):
    __tablename__ = "connection_codes"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    code = Column(String, unique=True, index=True, nullable=False)  # e.g., 7X3K-9P2B
    patient_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    is_used = Column(Boolean, default=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    patient = relationship("User")
