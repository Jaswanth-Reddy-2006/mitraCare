import uuid
from fastapi.testclient import TestClient
from app.main import app

def test_caregiver_full_flow():
    with TestClient(app) as client:
        suffix_p = uuid.uuid4().hex[:8]
        suffix_c1 = uuid.uuid4().hex[:8]
        suffix_c2 = uuid.uuid4().hex[:8]

        email_p = f"pat_{suffix_p}@example.com"
        email_c1 = f"cg1_{suffix_c1}@example.com"
        email_c2 = f"cg2_{suffix_c2}@example.com"
        password = "securepassword123"

        # 1. Register Patient & Caregivers
        client.post("/auth/register", json={
            "name": "Patient", "email": email_p, "password": password, "role": "PATIENT",
            "age": 70, "emergency_contact_name": "Contact A", "emergency_contact_phone": "+919000000001"
        })
        client.post("/auth/register", json={
            "name": "Caregiver 1", "email": email_c1, "password": password, "role": "CAREGIVER"
        })
        client.post("/auth/register", json={
            "name": "Caregiver 2", "email": email_c2, "password": password, "role": "CAREGIVER"
        })

        # Login
        login_p = client.post("/auth/login", json={"username": email_p, "password": password}).json()
        login_c1 = client.post("/auth/login", json={"username": email_c1, "password": password}).json()
        login_c2 = client.post("/auth/login", json={"username": email_c2, "password": password}).json()

        token_p = login_p["access_token"]
        token_c1 = login_c1["access_token"]
        token_c2 = login_c2["access_token"]

        headers_p = {"Authorization": f"Bearer {token_p}"}
        headers_c1 = {"Authorization": f"Bearer {token_c1}"}
        headers_c2 = {"Authorization": f"Bearer {token_c2}"}

        # 2. Patient generates connection code
        gen_res = client.post("/connections/generate-code", headers=headers_p)
        assert gen_res.status_code == 200
        code_data = gen_res.json()
        code = code_data["code"]
        assert len(code) == 9 # e.g. XXXX-XXXX (8 alphanumeric + 1 hyphen)

        # 3. Caregiver 1 joins using the code
        join_res = client.post("/connections/join", json={"code": code}, headers=headers_c1)
        assert join_res.status_code == 200
        assert "Successfully connected" in join_res.json()["message"]

        # 4. Caregiver 2 attempts to join with the same code (should fail because one-time use)
        join_fail = client.post("/connections/join", json={"code": code}, headers=headers_c2)
        assert join_fail.status_code == 400
        assert "already been used" in join_fail.json()["detail"]

        # 5. Fetch patient profile to extract patient ID
        patient_info = client.get("/auth/me", headers=headers_p).json()
        patient_id = patient_info["id"]

        # 6. Caregiver 1 fetches patient dashboard summary
        dash_res = client.get(f"/caregiver/dashboard-summary?patient_id={patient_id}", headers=headers_c1)
        assert dash_res.status_code == 200
        dash_data = dash_res.json()
        assert dash_data["patient_name"] == "Patient"
        assert "completed_tasks_count" in dash_data

        # 7. Caregiver 1 fetches patient cognitive reports
        report_res = client.get(f"/caregiver/reports?patient_id={patient_id}&range_days=30", headers=headers_c1)
        assert report_res.status_code == 200
        report_data = report_res.json()
        assert "score_trends" in report_data
        assert "domain_performance" in report_data

        # 8. Caregiver 1 adds a daily task for patient
        task_res = client.post(
            f"/caregiver/patients/{patient_id}/tasks",
            json={
                "title": "Drink Morning Tea",
                "description": "Herbal tea with lemon",
                "task_type": "DAILY_ROUTINE",
                "scheduled_time": "08:30",
                "date": "2026-08-30"
            },
            headers=headers_c1
        )
        assert task_res.status_code == 200
        task_id = task_res.json()["id"]

        # 9. Caregiver 1 updates patient profile
        profile_res = client.post(
            f"/caregiver/patients/{patient_id}/profile",
            json={
                "age": 73,
                "emergency_contact_name": "New Contact Name"
            },
            headers=headers_c1
        )
        assert profile_res.status_code == 200

        # Verify profile updated
        me_check = client.get("/auth/me", headers=headers_p).json()
        assert me_check["patient_profile"]["age"] == 73
        assert me_check["patient_profile"]["emergency_contact_name"] == "New Contact Name"

        # 10. Caregiver 1 deletes the task
        del_res = client.delete(f"/caregiver/patients/{patient_id}/tasks/{task_id}", headers=headers_c1)
        assert del_res.status_code == 200

        # SECURITY GUARD: Caregiver 2 attempts to fetch Dashboard details for Patient (Forbidden)
        sec_fail = client.get(f"/caregiver/dashboard-summary?patient_id={patient_id}", headers=headers_c2)
        assert sec_fail.status_code == 403
