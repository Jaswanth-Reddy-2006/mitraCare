import uuid
from fastapi.testclient import TestClient
from app.main import app

def test_patient_features_full_flow():
    # Use context manager so startup event (seeding) runs
    with TestClient(app) as client:
        # 1. Create two test patients (Patient A and Patient B)
        suffix_a = uuid.uuid4().hex[:8]
        suffix_b = uuid.uuid4().hex[:8]
        
        email_a = f"pat_a_{suffix_a}@example.com"
        email_b = f"pat_b_{suffix_b}@example.com"
        password = "securepassword123"

        # Register A
        reg_a = client.post("/auth/register", json={
            "name": "Patient A",
            "email": email_a,
            "password": password,
            "role": "PATIENT",
            "age": 70,
            "emergency_contact_name": "Contact A",
            "emergency_contact_phone": "+919000000001"
        })
        assert reg_a.status_code == 201
        
        # Register B
        reg_b = client.post("/auth/register", json={
            "name": "Patient B",
            "email": email_b,
            "password": password,
            "role": "PATIENT",
            "age": 72,
            "emergency_contact_name": "Contact B",
            "emergency_contact_phone": "+919000000002"
        })
        assert reg_b.status_code == 201

        # Login both
        login_a = client.post("/auth/login", json={"username": email_a, "password": password}).json()
        login_b = client.post("/auth/login", json={"username": email_b, "password": password}).json()

        token_a = login_a["access_token"]
        token_b = login_b["access_token"]
        headers_a = {"Authorization": f"Bearer {token_a}"}
        headers_b = {"Authorization": f"Bearer {token_b}"}

        # 2. Get activities catalog
        act_res = client.get("/patient/activities", headers=headers_a)
        assert act_res.status_code == 200
        activities = act_res.json()
        assert len(activities) > 0
        activity_id = activities[0]["id"]

        # 3. Start activity session
        session_res = client.post(
            "/patient/activity-sessions",
            json={"activity_id": activity_id, "difficulty_level": "EASY"},
            headers=headers_a
        )
        assert session_res.status_code == 200
        session = session_res.json()
        session_id = session["id"]

        # SECURITY CHECK: Patient B attempts to submit result for Patient A's session
        sec_submit = client.post(
            f"/patient/activity-sessions/{session_id}/result",
            json={"score": 85, "accuracy": 0.9, "response_time": 45000},
            headers=headers_b
        )
        assert sec_submit.status_code == 403 # Forbidden

        # Patient A submits result for A's session (Success)
        submit_res = client.post(
            f"/patient/activity-sessions/{session_id}/result",
            json={"score": 90, "accuracy": 0.95, "response_time": 40000},
            headers=headers_a
        )
        assert submit_res.status_code == 200
        assert submit_res.json()["score"] == 90

        # 4. Daily tasks checklist
        tasks_res = client.get("/patient/my-day", headers=headers_a)
        assert tasks_res.status_code == 200
        tasks = tasks_res.json()
        assert len(tasks) > 0
        task_id = tasks[0]["id"]

        # SECURITY CHECK: Patient B attempts to complete Patient A's task
        sec_task = client.post(f"/patient/my-day/tasks/{task_id}/complete", headers=headers_b)
        assert sec_task.status_code == 403

        # Patient A completes A's task
        task_comp = client.post(f"/patient/my-day/tasks/{task_id}/complete", headers=headers_a)
        assert task_comp.status_code == 200
        assert task_comp.json()["status"] == "COMPLETED"

        # Patient A skips task
        task_skip = client.post(f"/patient/my-day/tasks/{task_id}/skip", headers=headers_a)
        assert task_skip.status_code == 200
        assert task_skip.json()["status"] == "SKIPPED"

        # 5. Reminders checklist
        reminders_res = client.get("/patient/reminders/today", headers=headers_a)
        assert reminders_res.status_code == 200
        reminders = reminders_res.json()
        assert len(reminders) > 0
        reminder_id = reminders[0]["id"]

        # SECURITY CHECK: Patient B attempts to complete Patient A's reminder
        sec_rem = client.post(f"/patient/reminders/{reminder_id}/complete", headers=headers_b)
        assert sec_rem.status_code == 403

        # Patient A completes A's reminder
        rem_comp = client.post(f"/patient/reminders/{reminder_id}/complete", headers=headers_a)
        assert rem_comp.status_code == 200
        assert rem_comp.json()["status"] == "COMPLETED"
