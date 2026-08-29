from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api import auth, connections, users, activities, my_day, reminders, caregiver

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.PROJECT_VERSION,
    openapi_url="/openapi.json"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Startup Seeding
@app.on_event("startup")
def on_startup():
    from app.core.database import SessionLocal
    from app.core.seeding import seed_database
    db = SessionLocal()
    try:
        seed_database(db)
    finally:
        db.close()

# Include routers
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(connections.router, prefix="/connections", tags=["Connections"])
app.include_router(users.router, tags=["Profiles"])

# Patient Feature routers
app.include_router(activities.router, prefix="/patient", tags=["Patient Activities"])
app.include_router(my_day.router, prefix="/patient", tags=["Patient Schedule"])
app.include_router(reminders.router, prefix="/patient", tags=["Patient Reminders"])

# Caregiver routers
app.include_router(caregiver.router, prefix="/caregiver", tags=["Caregiver Dashboard"])

@app.get("/")
def read_root():
    return {
        "status": "online",
        "message": "Welcome to the MitraCare MVP API foundation.",
        "tagline": "Together in Every Memory, Every Day."
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
