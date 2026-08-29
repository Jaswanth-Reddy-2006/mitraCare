from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta
from app.core.database import get_db
from app.core.security import get_password_hash, verify_password, create_access_token
from app.api.deps import get_current_user
from app.models.user import User, PatientProfile, CaregiverProfile
from app.schemas.user import UserRegister, UserLogin, Token, UserResponse

router = APIRouter()

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_in: UserRegister, db: Session = Depends(get_db)):
    # Validate uniqueness of email/phone
    if user_in.email:
        existing_email = db.query(User).filter(User.email == user_in.email).first()
        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered."
            )
            
    if user_in.phone:
        existing_phone = db.query(User).filter(User.phone == user_in.phone).first()
        if existing_phone:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Phone number already registered."
            )
            
    if not user_in.email and not user_in.phone:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Either email or phone number must be provided."
        )

    # Hash the password
    password_hash = get_password_hash(user_in.password)
    
    # Create the user
    user = User(
        name=user_in.name,
        email=user_in.email,
        phone=user_in.phone,
        password_hash=password_hash,
        role=user_in.role.upper(),
        preferred_language=user_in.preferred_language
    )
    
    db.add(user)
    db.flush() # Get user.id
    
    # Create corresponding profile
    role_upper = user_in.role.upper()
    if role_upper == "PATIENT":
        patient_profile = PatientProfile(
            id=user.id,
            age=user_in.age,
            emergency_contact_name=user_in.emergency_contact_name,
            emergency_contact_phone=user_in.emergency_contact_phone
        )
        db.add(patient_profile)
    elif role_upper == "CAREGIVER":
        caregiver_profile = CaregiverProfile(
            id=user.id,
            organization=user_in.organization
        )
        db.add(caregiver_profile)
    
    db.commit()
    db.refresh(user)
    
    if role_upper == "PATIENT":
        from app.core.seeding import seed_patient_defaults
        seed_patient_defaults(db, user.id)
        
    return user

@router.post("/login", response_model=Token)
def login(login_in: UserLogin, db: Session = Depends(get_db)):
    # Query user by email or phone
    user = db.query(User).filter(
        (User.email == login_in.username) | (User.phone == login_in.username)
    ).first()
    
    if not user or not verify_password(login_in.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect username or password."
        )
        
    access_token = create_access_token(subject=user.id)
    return Token(
        access_token=access_token,
        role=user.role,
        name=user.name,
        user_id=user.id
    )

@router.post("/login-oauth", response_model=Token)
def login_oauth(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    # Standard OAuth2 form login for Swagger Docs UI
    user = db.query(User).filter(
        (User.email == form_data.username) | (User.phone == form_data.username)
    ).first()
    
    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect username or password."
        )
        
    access_token = create_access_token(subject=user.id)
    return Token(
        access_token=access_token,
        role=user.role,
        name=user.name,
        user_id=user.id
    )

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user
