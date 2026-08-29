import uuid
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["status"] == "online"
    assert "MitraCare" in response.json()["message"]

def test_auth_flow():
    # Use random email and phone to prevent conflicts in DB
    unique_suffix = uuid.uuid4().hex[:8]
    email = f"test_{unique_suffix}@example.com"
    phone = f"+9198765{unique_suffix[:5]}"
    password = "testpassword123"

    # 1. Register Patient
    reg_response = client.post(
        "/auth/register",
        json={
            "name": "Test Patient",
            "email": email,
            "phone": phone,
            "password": password,
            "role": "PATIENT",
            "age": 75,
            "emergency_contact_name": "Emergency Person",
            "emergency_contact_phone": "+919999999999"
        }
    )
    assert reg_response.status_code == 201
    data = reg_response.json()
    assert data["name"] == "Test Patient"
    assert data["role"] == "PATIENT"
    assert data["patient_profile"]["age"] == 75

    # 2. Login
    login_response = client.post(
        "/auth/login",
        json={
            "username": email,
            "password": password
        }
    )
    assert login_response.status_code == 200
    token_data = login_response.json()
    assert "access_token" in token_data
    assert token_data["role"] == "PATIENT"

    # 3. Get Current User Info
    token = token_data["access_token"]
    me_response = client.get(
        "/auth/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert me_response.status_code == 200
    me_data = me_response.json()
    assert me_data["email"] == email
    assert me_data["patient_profile"]["emergency_contact_name"] == "Emergency Person"
