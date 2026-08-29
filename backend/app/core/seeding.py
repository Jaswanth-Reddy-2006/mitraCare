from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from app.models.patient_features import ActivityCategory, Activity, DailyTask, Reminder
from app.models.user import User

def seed_patient_defaults(db: Session, patient_id: str):
    today_str = datetime.utcnow().strftime("%Y-%m-%d")
    
    # Check if they have tasks for today
    task_count = db.query(DailyTask).filter(
        DailyTask.patient_id == patient_id,
        DailyTask.date == today_str
    ).count()

    if task_count == 0:
        # Seed standard tasks
        default_tasks = [
            {
                "title": "Take Morning Medicine",
                "description": "It's time for your morning medicine.",
                "task_type": "MEDICATION",
                "scheduled_time": "09:00"
            },
            {
                "title": "Drink Water",
                "description": "Drink a glass of water to stay hydrated.",
                "task_type": "HYDRATION",
                "scheduled_time": "10:30"
            },
            {
                "title": "Memory Game",
                "description": "Play a cognitive exercise to keep your brain active.",
                "task_type": "ACTIVITY",
                "scheduled_time": "11:00"
            },
            {
                "title": "Lunch Time",
                "description": "Enjoy a balanced healthy lunch.",
                "task_type": "DAILY_ROUTINE",
                "scheduled_time": "13:00"
            },
            {
                "title": "Doctor Appointment",
                "description": "Standard checkup at health center.",
                "task_type": "APPOINTMENT",
                "scheduled_time": "16:00"
            }
        ]

        for t in default_tasks:
            db.add(DailyTask(
                patient_id=patient_id,
                title=t["title"],
                description=t["description"],
                task_type=t["task_type"],
                scheduled_time=t["scheduled_time"],
                date=today_str,
                status="PENDING"
            ))

    # Check if they have reminders
    reminder_count = db.query(Reminder).filter(
        Reminder.patient_id == patient_id
    ).count()

    if reminder_count == 0:
        base_date = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        default_reminders = [
            {
                "title": "Morning Medicine",
                "description": "It's time for your morning medicine.",
                "type": "MEDICINE",
                "offset": timedelta(hours=9)
            },
            {
                "title": "Drink Water",
                "description": "Drink a glass of water.",
                "type": "WATER",
                "offset": timedelta(hours=10, minutes=30)
            },
            {
                "title": "Memory Game",
                "description": "Play memory game.",
                "type": "ACTIVITY",
                "offset": timedelta(hours=11)
            },
            {
                "title": "Drink Water",
                "description": "Drink water.",
                "type": "WATER",
                "offset": timedelta(hours=15)
            },
            {
                "title": "Evening Medicine",
                "description": "Take your medicine.",
                "type": "MEDICINE",
                "offset": timedelta(hours=20)
            }
        ]

        for r in default_reminders:
            db.add(Reminder(
                patient_id=patient_id,
                title=r["title"],
                description=r["description"],
                type=r["type"],
                scheduled_at=base_date + r["offset"],
                status="PENDING"
            ))
    db.commit()

def seed_database(db: Session):
    # 1. Seed Categories & Activities
    categories_data = [
        {
            "name": "Memory",
            "description": "Remember objects and pictures",
            "activities": [
                {
                    "title": "Find the Pair",
                    "description": "Match two same cards",
                    "icon": "style",
                    "difficulty": "EASY",
                    "estimated_duration": 180
                },
                {
                    "title": "Find the Triplet",
                    "description": "Match three same cards",
                    "icon": "grid_on",
                    "difficulty": "MEDIUM",
                    "estimated_duration": 300
                },
                {
                    "title": "Find the Match",
                    "description": "Match similar pictures",
                    "icon": "grid_view",
                    "difficulty": "EASY",
                    "estimated_duration": 180
                },
                {
                    "title": "Remember Pictures",
                    "description": "Look, remember and recall",
                    "icon": "image",
                    "difficulty": "MEDIUM",
                    "estimated_duration": 300
                },
                {
                    "title": "Bihu Drum Rhythm",
                    "description": "Match the Bihu rhythm sequence",
                    "icon": "music_note",
                    "difficulty": "MEDIUM",
                    "estimated_duration": 180
                }
            ]
        },
        {
            "name": "Attention",
            "description": "Focus and find",
            "activities": [
                {
                    "title": "Spot the Difference",
                    "description": "Find what's different",
                    "icon": "search",
                    "difficulty": "HARD",
                    "estimated_duration": 240
                },
                {
                    "title": "Sort and Arrange",
                    "description": "Arrange items in the right order",
                    "icon": "sort",
                    "difficulty": "EASY",
                    "estimated_duration": 120
                },
                {
                    "title": "Sort the Harvest",
                    "description": "Sort Assam tea and chillies",
                    "icon": "filter_list",
                    "difficulty": "EASY",
                    "estimated_duration": 120
                }
            ]
        },
        {
            "name": "Patterns",
            "description": "Complete the pattern",
            "activities": []
        },
        {
            "name": "Objects",
            "description": "Recognize familiar things",
            "activities": [
                {
                    "title": "Name That Object",
                    "description": "Recall names of common objects",
                    "icon": "category",
                    "difficulty": "EASY",
                    "estimated_duration": 150
                },
                {
                    "title": "Northeast Word Search",
                    "description": "Unscramble Northeast heritage words",
                    "icon": "spellcheck",
                    "difficulty": "MEDIUM",
                    "estimated_duration": 200
                }
            ]
        },
        {
            "name": "Daily Recall",
            "description": "Remember your day",
            "activities": [
                {
                    "title": "Recall Daily Events",
                    "description": "Remember what happened today",
                    "icon": "today",
                    "difficulty": "EASY",
                    "estimated_duration": 180
                }
            ]
        }
    ]

    for cat_data in categories_data:
        category = db.query(ActivityCategory).filter(ActivityCategory.name == cat_data["name"]).first()
        if not category:
            category = ActivityCategory(
                name=cat_data["name"],
                description=cat_data["description"]
            )
            db.add(category)
            db.flush()
        
        for act_data in cat_data["activities"]:
            activity = db.query(Activity).filter(Activity.title == act_data["title"]).first()
            if not activity:
                activity = Activity(
                    category_id=category.id,
                    title=act_data["title"],
                    description=act_data["description"],
                    icon=act_data["icon"],
                    difficulty=act_data["difficulty"],
                    estimated_duration=act_data["estimated_duration"]
                )
                db.add(activity)
    db.commit()

    # 2. Seed for existing patients
    patients = db.query(User).filter(User.role == "PATIENT").all()
    for patient in patients:
        seed_patient_defaults(db, patient.id)
