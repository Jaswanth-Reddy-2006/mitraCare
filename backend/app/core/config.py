import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    PROJECT_NAME: str = "MitraCare API"
    PROJECT_VERSION: str = "1.0.0"
    
    # Database
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", 
        "postgresql://mitracare_admin:mitracare_secure_pass@localhost:5432/mitracare_db"
    )
    
    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "super_secret_mitracare_key_for_development_jwt_signing_1234567890")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "43200")) # 30 days
    
    # CORS
    BACKEND_CORS_ORIGINS: list = ["*"]

settings = Settings()
