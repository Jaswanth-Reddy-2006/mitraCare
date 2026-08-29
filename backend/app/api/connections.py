import uuid
import random
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User, ConnectionCode, CaregiverPatientRelationship, PatientProfile
from app.schemas.user import JoinCodeRequest

router = APIRouter()

def generate_eight_digit_code() -> str:
    # Generates a random alphanumeric pairing code in XXXX-XXXX format
    chars = "123456789ABCDEFGHIJKLMNPQRSTUVWXYZ" # exclude ambiguous chars like 0, O
    part1 = "".join(random.choices(chars, k=4))
    part2 = "".join(random.choices(chars, k=4))
    return f"{part1}-{part2}"

@router.post("/generate-code")
def generate_code(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "PATIENT":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Patients can generate connection codes."
        )
    
    # Invalidate any previous unused connection codes for this patient
    db.query(ConnectionCode).filter(
        ConnectionCode.patient_id == current_user.id,
        ConnectionCode.is_used == False
    ).update({"is_used": True})
    db.commit()
        
    # Generate new code
    code_str = generate_eight_digit_code()
    
    # Make sure code is unique in database
    while db.query(ConnectionCode).filter(ConnectionCode.code == code_str).first() is not None:
        code_str = generate_eight_digit_code()
        
    expires_at = datetime.utcnow() + timedelta(minutes=10) # 10 minutes validity
    
    connection_code = ConnectionCode(
        code=code_str,
        patient_id=current_user.id,
        expires_at=expires_at
    )
    
    db.add(connection_code)
    db.commit()
    db.refresh(connection_code)
    return {
        "code": connection_code.code,
        "expires_at": connection_code.expires_at
    }

@router.post("/join")
def join_with_code(
    request: JoinCodeRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "CAREGIVER":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Caregivers can claim connection codes."
        )
        
    import re
    code_normalized = request.code.upper().strip()
    if not re.match(r"^[A-Z0-9]{4}-[A-Z0-9]{4}$", code_normalized):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid connection code format. Must be XXXX-XXXX."
        )

    # Lock the connection code row to prevent race conditions during concurrent pairing
    connection_code = db.query(ConnectionCode).filter(
        ConnectionCode.code == code_normalized
    ).with_for_update().first()
    
    if not connection_code:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invalid connection code."
        )
        
    if connection_code.is_used:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This connection code has already been used."
        )
        
    if connection_code.expires_at < datetime.utcnow():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This connection code has expired."
        )
        
    # Check if relationship already exists
    existing = db.query(CaregiverPatientRelationship).filter(
        CaregiverPatientRelationship.caregiver_id == current_user.id,
        CaregiverPatientRelationship.patient_id == connection_code.patient_id,
        CaregiverPatientRelationship.status == "ACTIVE"
    ).first()
    
    if existing:
        connection_code.is_used = True
        db.commit()
        return {"message": "Successfully connected with patient."}
        
    # Create relationship
    relationship = CaregiverPatientRelationship(
        caregiver_id=current_user.id,
        patient_id=connection_code.patient_id,
        status="ACTIVE"
    )
    
    connection_code.is_used = True
    db.add(relationship)
    db.commit()
    
    return {"message": "Successfully connected with patient."}

@router.get("/inspect")
def inspect_code(
    code: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "CAREGIVER":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Caregivers can inspect connection codes."
        )
        
    import re
    code_normalized = code.upper().strip()
    if not re.match(r"^[A-Z0-9]{4}-[A-Z0-9]{4}$", code_normalized):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid connection code format."
        )
        
    connection_code = db.query(ConnectionCode).filter(
        ConnectionCode.code == code_normalized
    ).first()
    
    if not connection_code:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invalid connection code."
        )
        
    if connection_code.is_used:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This connection code has already been used."
        )
        
    if connection_code.expires_at < datetime.utcnow():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This connection code has expired."
        )
        
    patient = db.query(User).filter(User.id == connection_code.patient_id).first()
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Patient not found."
        )
        
    return {
        "patient_id": patient.id,
        "patient_name": patient.name,
        "code": connection_code.code
    }

@router.get("")
def get_connections(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role == "CAREGIVER":
        relations = db.query(CaregiverPatientRelationship).filter(
            CaregiverPatientRelationship.caregiver_id == current_user.id,
            CaregiverPatientRelationship.status == "ACTIVE"
        ).all()
        
        patient_ids = [r.patient_id for r in relations]
        patients = db.query(User).filter(User.id.in_(patient_ids)).all()
        
        # Include profiles
        result = []
        for p in patients:
            profile = db.query(PatientProfile).filter(PatientProfile.id == p.id).first()
            result.append({
                "id": p.id,
                "name": p.name,
                "email": p.email,
                "phone": p.phone,
                "preferred_language": p.preferred_language,
                "patient_profile": {
                    "age": profile.age if profile else None,
                    "emergency_contact_name": profile.emergency_contact_name if profile else None,
                    "emergency_contact_phone": profile.emergency_contact_phone if profile else None,
                    "profile_photo_url": profile.profile_photo_url if profile else None
                } if profile else None
            })
        return result
        
    elif current_user.role == "PATIENT":
        relations = db.query(CaregiverPatientRelationship).filter(
            CaregiverPatientRelationship.patient_id == current_user.id,
            CaregiverPatientRelationship.status == "ACTIVE"
        ).all()
        
        caregiver_ids = [r.caregiver_id for r in relations]
        caregivers = db.query(User).filter(User.id.in_(caregiver_ids)).all()
        return caregivers
        
    else:
        return []
