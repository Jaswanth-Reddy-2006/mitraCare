from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User, PatientProfile, CaregiverProfile
from app.schemas.user import UserResponse, PatientOnboard, CaregiverProfileSchema

router = APIRouter()

@router.put("/patients/me", response_model=UserResponse)
def update_patient_profile(
    profile_in: PatientOnboard,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "PATIENT":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Patient accounts have a patient profile."
        )
        
    profile = db.query(PatientProfile).filter(PatientProfile.id == current_user.id).first()
    if not profile:
        # Create profile if it didn't exist for some reason
        profile = PatientProfile(id=current_user.id)
        db.add(profile)
        
    # Update fields
    if profile_in.age is not None:
        profile.age = profile_in.age
    if profile_in.emergency_contact_name is not None:
        profile.emergency_contact_name = profile_in.emergency_contact_name
    if profile_in.emergency_contact_phone is not None:
        profile.emergency_contact_phone = profile_in.emergency_contact_phone
    if profile_in.profile_photo_url is not None:
        profile.profile_photo_url = profile_in.profile_photo_url
        
    db.commit()
    db.refresh(current_user)
    return current_user

@router.put("/caregivers/me", response_model=UserResponse)
def update_caregiver_profile(
    profile_in: CaregiverProfileSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "CAREGIVER":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Caregiver accounts have a caregiver profile."
        )
        
    profile = db.query(CaregiverProfile).filter(CaregiverProfile.id == current_user.id).first()
    if not profile:
        profile = CaregiverProfile(id=current_user.id)
        db.add(profile)
        
    if profile_in.organization is not None:
        profile.organization = profile_in.organization
        
    db.commit()
    db.refresh(current_user)
    return current_user
